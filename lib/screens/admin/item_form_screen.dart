import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/auction_item.dart';
import '../../models/item_photo.dart';
import '../../database/database_helper.dart';
import '../../utils/file_helper.dart';
import '../../utils/app_colors.dart';
import '../../services/financing_calculator.dart';
import '../../widgets/responsive_row_column.dart';

class ItemFormScreen extends StatefulWidget {
  final AuctionItem? itemToEdit;

  const ItemFormScreen({super.key, this.itemToEdit});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _creditNumber;
  String _name = '';
  int? _categoryId;
  double _weightGram = 0;
  String? _karat;
  double _basePrice = 0;
  String? _description;
  bool _isActive = true;

  // Track original values to show floating save button when modified
  int _originalPhotosLength = 0;
  int _originalPrimaryPhotoIndex = 0;

  bool get _hasChanges {
    final currentBasePriceText = _basePriceController.text.replaceAll('.', '');
    final currentBasePrice = double.tryParse(currentBasePriceText) ?? 0.0;

    if (widget.itemToEdit == null) {
      // For adding a new item, check if anything is modified from blank defaults
      return (_creditNumber != null && _creditNumber!.trim().isNotEmpty) ||
          _name.isNotEmpty ||
          _categoryId != null ||
          _weightGram != 0.0 ||
          _karat != null ||
          currentBasePrice != 0.0 ||
          (_description != null && _description!.trim().isNotEmpty) ||
          !_isActive ||
          _newPhotos.isNotEmpty;
    }
    
    // For editing an existing item
    final orig = widget.itemToEdit!;
    if ((_creditNumber ?? '') != (orig.creditNumber ?? '')) return true;
    if (_name != orig.name) return true;
    if (_categoryId != orig.categoryId) return true;
    if (_weightGram != orig.weightGram) return true;
    if ((_karat ?? '') != (orig.karat ?? '')) return true;
    if (currentBasePrice != orig.basePrice) return true;
    if ((_description ?? '') != (orig.description ?? '')) return true;
    if (_isActive != orig.isActive) return true;
    if (_newPhotos.isNotEmpty) return true;
    if (_existingPhotos.length != _originalPhotosLength) return true;
    if (_primaryPhotoIndex != _originalPrimaryPhotoIndex) return true;
    
    return false;
  }

  final List<File> _newPhotos = [];
  List<ItemPhoto> _existingPhotos = [];

  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  int _primaryPhotoIndex = 0; // index in the combined list

  late TextEditingController _basePriceController;

  Map<String, dynamic>? _financingConfig;
  List<Map<String, dynamic>> _financingTenors = [];
  bool _isFinancingLoading = true;

  @override
  void initState() {
    super.initState();
    _basePriceController = TextEditingController(
      text: widget.itemToEdit != null
          ? NumberFormat.decimalPattern(
              'id',
            ).format(widget.itemToEdit!.basePrice.round())
          : '',
    );
    if (widget.itemToEdit != null) {
      _creditNumber = widget.itemToEdit!.creditNumber;
      _name = widget.itemToEdit!.name;
      _categoryId = widget.itemToEdit!.categoryId;
      _weightGram = widget.itemToEdit!.weightGram;
      _karat = widget.itemToEdit!.karat;
      _basePrice = widget.itemToEdit!.basePrice;
      _description = widget.itemToEdit!.description;
      _isActive = widget.itemToEdit!.isActive;

      _loadExistingPhotos();
    }
    _loadFinancingData();
  }

  Future<void> _loadFinancingData() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final config = await provider.getActiveFinancingConfig();
    if (config != null && config['is_active'] == 1) {
      final tenors = await provider.getFinancingTenors(config['id'] as int);
      final activeTenors = tenors.where((t) => t['is_active'] == 1).toList();
      if (mounted) {
        setState(() {
          _financingConfig = config;
          _financingTenors = activeTenors;
          _isFinancingLoading = false;
        });
      }
    } else if (mounted) {
      setState(() => _isFinancingLoading = false);
    }
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    super.dispose();
  }

  bool _isGoldCategory(AppProvider provider) {
    if (_categoryId == null) return false;
    try {
      final category = provider.categories.firstWhere(
        (c) => c.id == _categoryId,
      );
      final name = category.name.toLowerCase();
      return name.contains('emas') || name.contains('logam mulia');
    } catch (_) {
      return false;
    }
  }

  void _recalculateBasePrice(AppProvider provider) {
    final karatVal = FinancingCalculator.parseKarat(_karat);
    final effectiveKarat = karatVal > 0 ? karatVal : 24.0;

    _basePrice = FinancingCalculator.hitungHargaEmas(
      hdlePrice: provider.goldPricePerGram,
      weightGram: _weightGram,
      karatVal: effectiveKarat,
    ).toDouble();

    if (_basePrice > 0) {
      _basePriceController.text = NumberFormat.decimalPattern(
        'id',
      ).format(_basePrice.round());
    } else {
      _basePriceController.text = '';
    }
  }

  Future<void> _loadExistingPhotos() async {
    final photos = await Provider.of<AppProvider>(
      context,
      listen: false,
    ).getItemPhotos(widget.itemToEdit!.id!);
    setState(() {
      _existingPhotos = photos;
      final primaryIdx = photos.indexWhere((p) => p.isPrimary);
      if (primaryIdx >= 0) _primaryPhotoIndex = primaryIdx;
      
      _originalPhotosLength = photos.length;
      _originalPrimaryPhotoIndex = _primaryPhotoIndex;
    });
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      if (_existingPhotos.length + _newPhotos.length + images.length > 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Maksimal 10 foto diperbolehkan.'),
              backgroundColor: const Color(0xFFD97706),
            ),
          );
        }
        return;
      }
      setState(() {
        _newPhotos.addAll(images.map((xfile) => File(xfile.path)));
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      if (_existingPhotos.length + _newPhotos.length + 1 > 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Maksimal 10 foto diperbolehkan.'),
              backgroundColor: const Color(0xFFD97706),
            ),
          );
        }
        return;
      }
      setState(() {
        _newPhotos.add(File(image.path));
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih kategori terlebih dahulu.'),
          backgroundColor: const Color(0xFFD97706),
        ),
      );
      return;
    }
    if (_existingPhotos.isEmpty && _newPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Minimal 1 foto wajib diunggah.'),
          backgroundColor: const Color(0xFFD97706),
        ),
      );
      return;
    }

    _formKey.currentState!.save();

    final provider = Provider.of<AppProvider>(context, listen: false);
    final isGold = _isGoldCategory(provider);
    if (!isGold) {
      _weightGram = 0.0;
      _karat = null;
    }

    setState(() => _isSaving = true);

    try {
      final dbHelper = DatabaseHelper.instance;
      int itemId;

      final item = AuctionItem(
        id: widget.itemToEdit?.id,
        creditNumber: _creditNumber?.trim().isEmpty == true
            ? null
            : _creditNumber?.trim(),
        name: _name,
        categoryId: _categoryId!,
        weightGram: _weightGram,
        karat: _karat,
        basePrice: _basePrice,
        description: _description,
        isActive: _isActive,
        createdAt: DateTime.now().toIso8601String(),
      );

      if (widget.itemToEdit == null) {
        itemId = await dbHelper.createAuctionItem(item);
      } else {
        itemId = widget.itemToEdit!.id!;
        await dbHelper.updateAuctionItem(item);
      }

      for (int i = 0; i < _newPhotos.length; i++) {
        final localPath = await FileHelper.saveImageToLocalDirectory(
          _newPhotos[i],
        );
        final combinedIndex = _existingPhotos.length + i;
        final photo = ItemPhoto(
          itemId: itemId,
          localPath: localPath,
          isPrimary: combinedIndex == _primaryPhotoIndex,
          sortOrder: combinedIndex,
        );
        await dbHelper.createItemPhoto(photo);
      }

      if (!mounted) return;
      await Provider.of<AppProvider>(context, listen: false).refreshAdminData();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data berhasil disimpan!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isGold = _isGoldCategory(provider);
    final isPortrait = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: widget.itemToEdit != null
          ? AppBar(
              title: const Text(
                'Edit Barang',
                style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827)),
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: const Color(0xFFE5E7EB),
                  height: 1,
                ),
              ),
            )
          : null,
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Menyimpan data...',
                    style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.itemToEdit == null) ...[
                        const SizedBox(height: 20), // Lower the header
                        const Text(
                          'Tambah Barang Lelang',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Input data barang baru ke database offline cabang.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      ResponsiveRowColumn(
                        isPortrait: isPortrait,
                        spacing: 40,
                        left: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card 1: Informasi Dasar
                              _buildFormCard(
                                title: 'Informasi Dasar',
                                icon: Icons.assignment_outlined,
                                children: [
                                  _buildLabel('Nomor Akad / Kredit'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: _creditNumber,
                                    decoration: _inputDecoration(
                                      'Contoh: BK 1234',
                                      helperText: 'Boleh sama untuk beberapa barang dalam satu akad.',
                                    ),
                                    textCapitalization: TextCapitalization.characters,
                                    onChanged: (val) => setState(() => _creditNumber = val),
                                    onSaved: (val) => _creditNumber = val,
                                  ),
                                  const SizedBox(height: 20),

                                  _buildLabel('Nama Barang', required: true),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: _name,
                                    decoration: _inputDecoration(
                                      'Contoh: Cincin Emas Berlian',
                                    ),
                                    validator: (val) => val == null || val.isEmpty
                                        ? 'Wajib diisi'
                                        : null,
                                    onChanged: (val) => setState(() => _name = val),
                                    onSaved: (val) => _name = val!,
                                  ),
                                  const SizedBox(height: 20),

                                  _buildLabel('Kategori', required: true),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    initialValue: _categoryId,
                                    decoration: _inputDecoration(
                                      'Pilih kategori',
                                    ),
                                    items: provider.categories
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c.id,
                                            child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _categoryId = val;
                                        final nextIsGold = _isGoldCategory(provider);
                                        if (nextIsGold) {
                                          _recalculateBasePrice(provider);
                                        } else {
                                          _weightGram = 0.0;
                                          _karat = null;
                                          if (widget.itemToEdit == null) {
                                            _basePrice = 0.0;
                                            _basePriceController.clear();
                                          }
                                        }
                                      });
                                    },
                                    validator: (val) => val == null
                                        ? 'Pilih kategori'
                                        : null,
                                  ),
                                ],
                              ),

                              // Card 2: Spesifikasi
                              _buildFormCard(
                                title: 'Spesifikasi',
                                icon: Icons.tune_outlined,
                                children: [
                                  if (isGold) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildLabel(
                                                'Berat (gram)',
                                                required: true,
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                initialValue: widget.itemToEdit != null &&
                                                        widget.itemToEdit!.categoryId == _categoryId
                                                    ? _weightGram.toString()
                                                    : '',
                                                decoration: _inputDecoration(
                                                  '0.00',
                                                ),
                                                keyboardType: const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                                validator: (val) {
                                                  if (!_isGoldCategory(provider)) {
                                                    return null;
                                                  }
                                                  if (val == null || val.isEmpty) {
                                                    return 'Wajib diisi';
                                                  }
                                                  if (double.tryParse(val) == null) {
                                                    return 'Harus angka';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (val) {
                                                  setState(() {
                                                    _weightGram = double.tryParse(val) ?? 0.0;
                                                    _recalculateBasePrice(provider);
                                                  });
                                                },
                                                onSaved: (val) {
                                                  _weightGram = _isGoldCategory(provider)
                                                      ? (double.tryParse(val ?? '') ?? 0.0)
                                                      : 0.0;
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildLabel(
                                                'Kadar / Karat',
                                                required: true,
                                                suffix: '(maks 24)',
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                initialValue: _karat,
                                                decoration: _inputDecoration(
                                                  'Contoh: 18 atau 18 Karat',
                                                ),
                                                validator: (val) {
                                                  if (!_isGoldCategory(provider)) {
                                                    return null;
                                                  }
                                                  if (val == null || val.isEmpty) {
                                                    return 'Wajib diisi';
                                                  }
                                                  final regExp = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
                                                  final match = regExp.firstMatch(val);
                                                  if (match == null) {
                                                    return 'Harus berupa angka karat';
                                                  }
                                                  final parsed = double.tryParse(match.group(1)!);
                                                  if (parsed == null || parsed <= 0 || parsed > 24) {
                                                    return 'Karat harus antara 1 - 24';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (val) {
                                                  setState(() {
                                                    _karat = val;
                                                    _recalculateBasePrice(provider);
                                                  });
                                                },
                                                onSaved: (val) {
                                                  _karat = _isGoldCategory(provider) ? val : null;
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        'Spesifikasi khusus tersedia setelah Anda memilih kategori emas.',
                                        style: TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ]),

                              // Card 3: Penetapan Harga & Deskripsi
                              _buildFormCard(
                                title: 'Penetapan Harga & Deskripsi',
                                icon: Icons.payments_outlined,
                                children: [
                                  _buildGoldPriceBanner(provider),
                                  _buildLabel('Harga Lelang', required: true),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _basePriceController,
                                    readOnly: false,
                                    decoration: _inputDecoration(
                                      'Rp 0',
                                      helperText: isGold
                                          ? 'Dihitung otomatis: Harga Emas x (Karat/24) x Berat (Dapat diubah manual)'
                                          : 'Masukkan harga lelang secara manual',
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      _ThousandsSeparatorFormatter(),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        final rawValue = val.replaceAll('.', '');
                                        _basePrice = double.tryParse(rawValue) ?? 0.0;
                                      });
                                    },
                                    validator: (val) {
                                      if (val == null || val.isEmpty || val.replaceAll('.', '') == '0') {
                                        return 'Wajib diisi';
                                      }
                                      return null;
                                    },
                                    onSaved: (val) {
                                      if (val != null) {
                                        final rawValue = val.replaceAll('.', '');
                                        _basePrice = double.tryParse(rawValue) ?? 0.0;
                                      } else {
                                        _basePrice = 0.0;
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  _buildLabel('Deskripsi Barang', required: false),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: _description,
                                    decoration: _inputDecoration(
                                      'Deskripsi tambahan...',
                                    ),
                                    maxLines: 4,
                                    onChanged: (val) => setState(() => _description = val),
                                    onSaved: (val) => _description = val,
                                  ),
                                  const SizedBox(height: 20),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Status Aktif',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _isActive
                                                    ? 'Barang tampil di katalog'
                                                    : 'Barang disembunyikan',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6B7280),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: _isActive,
                                          activeTrackColor: AppColors.primary.withValues(alpha: 0.2),
                                          activeThumbColor: AppColors.primary,
                                          onChanged: (val) => setState(() => _isActive = val),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        right: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Photos Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Unggah Foto Barang',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(Maks 10)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: const Color(0xFF9CA3AF),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Upload area with dashed border CustomPaint
                                  CustomPaint(
                                    painter: DashedBorderPainter(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      strokeWidth: 2,
                                      borderRadius: 6,
                                    ),
                                    child: GestureDetector(
                                      onTap: _pickImages,
                                      child: Container(
                                        height: 160,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.cloud_upload_outlined,
                                              size: 40,
                                              color: AppColors.primary.withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(height: 10),
                                            const Text(
                                              'Ambil Foto dari Kamera\n/ Pilih dari Galeri Tablet',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Color(0xFF4B5563),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'Format JPG atau PNG',
                                              style: TextStyle(
                                                color: Color(0xFF9CA3AF),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Camera button
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _takePhoto,
                                      icon: const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w800)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(
                                          color: AppColors.primary,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Photo thumbnails
                                  if (_existingPhotos.isNotEmpty || _newPhotos.isNotEmpty)
                                    SizedBox(
                                      height: 90,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _existingPhotos.length + _newPhotos.length,
                                        itemBuilder: (context, index) {
                                          final isPrimary = index == _primaryPhotoIndex;
                                          Widget imageWidget;
                                          VoidCallback onDelete;

                                          if (index < _existingPhotos.length) {
                                            final photo = _existingPhotos[index];
                                            imageWidget = Image.file(
                                              File(photo.localPath),
                                              fit: BoxFit.cover,
                                            );
                                            onDelete = () async {
                                              await DatabaseHelper.instance.deleteItemPhoto(photo.id!);
                                              _loadExistingPhotos();
                                            };
                                          } else {
                                            final newIdx = index - _existingPhotos.length;
                                            imageWidget = Image.file(
                                              _newPhotos[newIdx],
                                              fit: BoxFit.cover,
                                            );
                                            onDelete = () => setState(
                                                  () => _newPhotos.removeAt(newIdx),
                                                );
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.only(right: 10),
                                            child: GestureDetector(
                                              onTap: () => setState(
                                                () => _primaryPhotoIndex = index,
                                              ),
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  Container(
                                                    width: 80,
                                                    height: 80,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: isPrimary
                                                          ? Border.all(
                                                              color: AppColors.primary,
                                                              width: 3,
                                                            )
                                                          : Border.all(
                                                              color: const Color(0xFFE5E7EB),
                                                            ),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: imageWidget,
                                                    ),
                                                  ),
                                                  if (isPrimary)
                                                    Positioned(
                                                      bottom: 0,
                                                      left: 0,
                                                      right: 0,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          vertical: 3,
                                                        ),
                                                        decoration: const BoxDecoration(
                                                          color: AppColors.primary,
                                                          borderRadius: BorderRadius.vertical(
                                                            bottom: Radius.circular(4),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'Foto Utama',
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w900,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  Positioned(
                                                    top: -4,
                                                    right: -4,
                                                    child: GestureDetector(
                                                      onTap: onDelete,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(2),
                                                        decoration: const BoxDecoration(
                                                          color: Color(0xFFDC2626),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          size: 14,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Real-time Live Simulation Preview Card
                            _buildSimulationPreview(),

                            const SizedBox(height: 32),

                            // Action buttons
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Batal & Kembali', style: TextStyle(fontWeight: FontWeight.w800)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF4B5563),
                                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasChanges)
                  Positioned(
                    left: 32,
                    right: 32,
                    bottom: 24,
                    child: _buildFloatingSaveButton(),
                  ),
              ],
            ),
    );
  }

  Widget _buildFloatingSaveButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = MediaQuery.of(context).size.width > 650;
        final button = ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveItem,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline_rounded, size: 22),
          label: Text(
            _isSaving ? 'Menyimpan...' : 'Simpan Barang',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 20,
            ),
          ),
        );

        final notificationIcon = Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        );

        final textColumn = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Perubahan Terdeteksi',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              'Ada data barang baru/perubahan yang belum disimpan.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: isWide
              ? Row(
                  children: [
                    notificationIcon,
                    const SizedBox(width: 16),
                    Expanded(child: textColumn),
                    const SizedBox(width: 16),
                    button,
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        notificationIcon,
                        const SizedBox(width: 16),
                        Expanded(child: textColumn),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: button,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }


  Widget _buildGoldPriceBanner(AppProvider provider) {
    final isGold = _isGoldCategory(provider);
    if (!isGold) return const SizedBox.shrink();

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Calculate auto base price estimation
    final karatVal = FinancingCalculator.parseKarat(_karat);
    final effectiveKarat = karatVal > 0 ? karatVal : 24.0;
    final estimatedPrice = FinancingCalculator.hitungHargaEmas(
      hdlePrice: provider.goldPricePerGram,
      weightGram: _weightGram,
      karatVal: effectiveKarat,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber light tint
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.gavel_outlined,
            color: Color(0xFFD97706),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kalkulator Harga Emas Pegadaian',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Harga Emas Saat Ini: ${formatter.format(provider.goldPricePerGram)} / gram',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_weightGram > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      'Estimasi Nilai Taksir: ${formatter.format(estimatedPrice)} (${_weightGram}g @ ${karatVal.toStringAsFixed(0)} Karat)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false, String? suffix}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF374151),
            fontSize: 13,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w800,
            ),
          ),
        if (suffix != null) ...[
          const SizedBox(width: 6),
          Text(
            suffix,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {String? helperText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
      helperText: helperText,
      helperStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
      helperMaxLines: 2,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildSimulationPreview() {
    if (_isFinancingLoading || _financingConfig == null || _basePrice <= 0) {
      return const SizedBox.shrink();
    }

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final provider = Provider.of<AppProvider>(context, listen: false);
    final hargaInt = _basePrice.round();

    double appraisalValue = hargaInt.toDouble();
    if (_isGoldCategory(provider)) {
      final stlPrice = (_financingConfig?['stl_price'] as num?)?.toDouble() ?? 502894;
      final karatVal = FinancingCalculator.parseKarat(_karat);
      appraisalValue = FinancingCalculator.hitungNilaiTaksiran(
        stlPrice: stlPrice,
        weightGram: _weightGram,
        karatVal: karatVal > 0 ? karatVal : 24.0,
      );
    }

    // 1. Tunai
    final tunaiRes = FinancingCalculator.simulasiTunai(hargaLelang: hargaInt);

    // 2. KCA
    final kcaRes = FinancingCalculator.simulasiKca(
      hargaLelang: hargaInt,
      appraisalValue: appraisalValue,
      config: _financingConfig!,
    );

    // 3. KRASIDA
    final defaultTenor = _financingTenors.isNotEmpty
        ? _financingTenors.first['months'] as int
        : 12;
    final krasidaRes = FinancingCalculator.simulasiKrasida(
      hargaLelang: hargaInt,
      appraisalValue: appraisalValue,
      config: _financingConfig!,
      tenors: _financingTenors,
      tenorMonths: defaultTenor,
    );

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PREVIEW SIMULASI PEMBIAYAAN',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    letterSpacing: 0.5,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Berdasarkan harga lelang: ${currencyFormatter.format(hargaInt)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // TUNAI CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9), // Light green tint
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: AppColors.successGreen, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'TUNAI',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Text(
                        currencyFormatter.format(tunaiRes.hargaLelang),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(left: 26),
                  child: Text(
                    'Bayar penuh saat transaksi, tanpa bunga/cicilan.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KCA CARD
          if (kcaRes.eligible)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD), // Light blue tint
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBBDEFB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.credit_card_outlined, color: AppColors.info, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rahn (Kredit Cepat Aman) — Tempo ${kcaRes.tempoKca} Bulan',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.categoryBlueText,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPreviewDetailRow('Uang Muka (DP)', currencyFormatter.format(kcaRes.uangMuka)),
                  _buildPreviewDetailRow('Uang Pinjaman', currencyFormatter.format(kcaRes.uangPinjaman)),
                  _buildPreviewDetailRow('Biaya Admin', currencyFormatter.format(kcaRes.adminFee!)),
                  const Divider(height: 16, color: Color(0xFFBBDEFB)),
                  _buildPreviewDetailRow(
                    'Total Pelunasan',
                    currencyFormatter.format(kcaRes.totalPelunasanKca!),
                    isBold: true,
                    textColor: AppColors.categoryBlueText,
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      '* Bayar bebas kapan saja selama 4 bulan, tanpa angsuran rutin bulanan.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE), // Light red tint
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rahn (Tidak Eligible)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFDC2626),
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kcaRes.message ?? 'Harga di luar limit kelayakan Rahn.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4B5563),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // KRASIDA CARD
          if (krasidaRes.eligible)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1), // Light gold tint
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFECB3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bar_chart_outlined, color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          ' Arrum Emas (Kredit Gadai Angsuran Bulanan)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.categoryAmberText,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPreviewDetailRow('Uang Muka (DP)', currencyFormatter.format(krasidaRes.uangMuka)),
                  _buildPreviewDetailRow('Uang Pinjaman', currencyFormatter.format(krasidaRes.uangPinjaman)),
                  const SizedBox(height: 12),
                  const Text(
                    'Simulasi Angsuran Bulanan:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.categoryAmberText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    children: krasidaRes.perbandinganTenor?.map((t) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFECB3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Tenor ${t.tenor} Bulan',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${currencyFormatter.format(t.angsuranPerBulan)} / bln',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.categoryAmberText,
                                    ),
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Total bayar: ${currencyFormatter.format(t.totalBayar)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList() ?? [],
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE), // Light red tint
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Arrum Emas (Tidak Eligible)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFDC2626),
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          krasidaRes.message ?? 'Harga di luar limit kelayakan Arrum Emas.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4B5563),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF4B5563),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: textColor ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return const TextEditingValue();

    final number = int.parse(cleaned);
    final formatter = NumberFormat.decimalPattern('id');
    final formatted = formatter.format(number);

    int cursorPosition =
        formatted.length -
        (newValue.text.length - newValue.selection.baseOffset);
    if (cursorPosition < 0) cursorPosition = 0;
    if (cursorPosition > formatted.length) cursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.gap = 4,
    this.dashLength = 6,
    this.borderRadius = 24,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
