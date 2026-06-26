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
  String _condition = 'Baik';
  double _basePrice = 0;
  String? _description;
  bool _isActive = true;

  final List<File> _newPhotos = [];
  List<ItemPhoto> _existingPhotos = [];

  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  int _primaryPhotoIndex = 0; // index in the combined list

  final List<String> _conditionOptions = [
    'Baik',
    'Cukup Baik',
    'Perlu Perbaikan',
  ];

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
      _condition = widget.itemToEdit!.condition;
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
    double karatVal = 24.0;
    if (_karat != null && _karat!.isNotEmpty) {
      final regExp = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
      final match = regExp.firstMatch(_karat!);
      if (match != null) {
        final parsed = double.tryParse(match.group(1)!) ?? 24.0;
        karatVal = parsed > 24.0 ? 24.0 : (parsed < 0 ? 0 : parsed);
      }
    }

    _basePrice = provider.goldPricePerGram * (karatVal / 24.0) * _weightGram;
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
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (_existingPhotos.isEmpty && _newPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Minimal 1 foto wajib diunggah.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
        condition: _condition,
        basePrice: _basePrice,
        description: _description,
        isActive: _isActive,
        createdAt:
            widget.itemToEdit?.createdAt ?? DateTime.now().toIso8601String(),
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
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.itemToEdit != null
          ? AppBar(
              title: const Text(
                'Edit Barang',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
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
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.itemToEdit == null) ...[
                    const Text(
                      'Tambah Barang Lelang',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Input data barang baru ke database offline cabang.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Panel - Form
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nomor Akad / Kredit
                                _buildLabel('Nomor Akad / Kredit'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: _creditNumber,
                                  decoration: _inputDecoration(
                                    'Contoh: BK 1234',
                                    helperText:
                                        'Boleh sama untuk beberapa barang dalam satu akad.',
                                  ),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  onSaved: (val) => _creditNumber = val,
                                ),
                                const SizedBox(height: 20),

                                // Nama Barang
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
                                  onSaved: (val) => _name = val!,
                                ),
                                const SizedBox(height: 20),

                                // Kategori
                                _buildLabel('Kategori', required: true),
                                const SizedBox(height: 8),
                                Consumer<AppProvider>(
                                  builder: (context, provider, child) {
                                    final isGold = _isGoldCategory(provider);
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        DropdownButtonFormField<int>(
                                          initialValue: _categoryId,
                                          decoration: _inputDecoration(
                                            'Pilih kategori',
                                          ),
                                          items: provider.categories
                                              .map(
                                                (c) => DropdownMenuItem(
                                                  value: c.id,
                                                  child: Text(c.name),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _categoryId = val;
                                              final nextIsGold =
                                                  _isGoldCategory(provider);
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
                                        const SizedBox(height: 20),

                                        // Berat + Karat (Only visible for Gold categories)
                                        if (isGold) ...[
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _buildLabel(
                                                      'Berat (gram)',
                                                      required: true,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    TextFormField(
                                                      initialValue:
                                                          widget.itemToEdit !=
                                                                  null &&
                                                              widget
                                                                      .itemToEdit!
                                                                      .categoryId ==
                                                                  _categoryId
                                                          ? _weightGram
                                                                .toString()
                                                          : '',
                                                      decoration:
                                                          _inputDecoration(
                                                            '0.00',
                                                          ),
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                      validator: (val) {
                                                        if (!_isGoldCategory(
                                                          provider,
                                                        )) {
                                                          return null;
                                                        }
                                                        if (val == null ||
                                                            val.isEmpty) {
                                                          return 'Wajib diisi';
                                                        }
                                                        if (double.tryParse(
                                                              val,
                                                            ) ==
                                                            null) {
                                                          return 'Harus angka';
                                                        }
                                                        return null;
                                                      },
                                                      onChanged: (val) {
                                                        setState(() {
                                                          _weightGram =
                                                              double.tryParse(
                                                                val,
                                                              ) ??
                                                              0.0;
                                                          _recalculateBasePrice(
                                                            provider,
                                                          );
                                                        });
                                                      },
                                                      onSaved: (val) {
                                                        _weightGram =
                                                            _isGoldCategory(
                                                              provider,
                                                            )
                                                            ? (double.tryParse(
                                                                    val ?? '',
                                                                  ) ??
                                                                  0.0)
                                                            : 0.0;
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
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
                                                        if (!_isGoldCategory(
                                                          provider,
                                                        )) {
                                                          return null;
                                                        }
                                                        if (val == null ||
                                                            val.isEmpty) {
                                                          return 'Wajib diisi';
                                                        }
                                                        final regExp = RegExp(
                                                          r'([0-9]+(?:\.[0-9]+)?)',
                                                        );
                                                        final match = regExp
                                                            .firstMatch(val);
                                                        if (match == null) {
                                                          return 'Harus berupa angka karat';
                                                        }
                                                        final parsed =
                                                            double.tryParse(
                                                              match.group(1)!,
                                                            );
                                                        if (parsed == null ||
                                                            parsed <= 0 ||
                                                            parsed > 24) {
                                                          return 'Karat harus antara 1 - 24';
                                                        }
                                                        return null;
                                                      },
                                                      onChanged: (val) {
                                                        setState(() {
                                                          _karat = val;
                                                          _recalculateBasePrice(
                                                            provider,
                                                          );
                                                        });
                                                      },
                                                      onSaved: (val) {
                                                        _karat =
                                                            _isGoldCategory(
                                                              provider,
                                                            )
                                                            ? val
                                                            : null;
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                        ],

                                        // Kondisi Barang - Chip selector
                                        _buildLabel(
                                          'Kondisi Barang',
                                          required: true,
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.muted,
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: AppColors.border,
                                            ),
                                          ),
                                          child: Row(
                                            children: _conditionOptions.map((
                                              option,
                                            ) {
                                              final isSelected =
                                                  _condition == option;
                                              return Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  child: ChoiceChip(
                                                    label: Center(
                                                      child: Text(
                                                        option,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    selected: isSelected,
                                                    selectedColor:
                                                        AppColors.primary,
                                                    labelStyle: TextStyle(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : AppColors
                                                                .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                    backgroundColor:
                                                        Colors.white,
                                                    side: BorderSide(
                                                      color: isSelected
                                                          ? AppColors.primary
                                                          : AppColors.border,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    showCheckmark: false,
                                                    onSelected: (selected) {
                                                      if (selected) {
                                                        setState(
                                                          () => _condition =
                                                              option,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // Harga Lelang
                                        _buildLabel(
                                          'Harga Lelang',
                                          required: true,
                                        ),
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
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            _ThousandsSeparatorFormatter(),
                                          ],
                                          onChanged: (val) {
                                            setState(() {
                                              final rawValue = val.replaceAll(
                                                '.',
                                                '',
                                              );
                                              _basePrice =
                                                  double.tryParse(rawValue) ??
                                                  0.0;
                                            });
                                          },
                                          validator: (val) {
                                            if (val == null ||
                                                val.isEmpty ||
                                                val.replaceAll('.', '') ==
                                                    '0') {
                                              return 'Wajib diisi';
                                            }
                                            return null;
                                          },
                                          onSaved: (val) {
                                            if (val != null) {
                                              final rawValue = val.replaceAll(
                                                '.',
                                                '',
                                              );
                                              _basePrice =
                                                  double.tryParse(rawValue) ??
                                                  0.0;
                                            } else {
                                              _basePrice = 0.0;
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Deskripsi
                                _buildLabel(
                                  'Deskripsi Barang',
                                  required: false,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: _description,
                                  decoration: _inputDecoration(
                                    'Deskripsi tambahan...',
                                  ),
                                  maxLines: 4,
                                  onSaved: (val) => _description = val,
                                ),
                                const SizedBox(height: 20),

                                // Status switch
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SwitchListTile(
                                    title: const Text(
                                      'Status Aktif',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _isActive
                                          ? 'Barang tampil di katalog'
                                          : 'Barang disembunyikan',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    value: _isActive,
                                    activeThumbColor: AppColors.primary,
                                    onChanged: (val) =>
                                        setState(() => _isActive = val),
                                  ),
                                ),
                                _buildSimulationPreview(),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 40),

                      // Right Panel - Photos
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Unggah Foto Barang',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(Maks 10)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textMuted.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Upload area
                              GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  height: 160,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.muted,
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.30,
                                      ),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 44,
                                        color: AppColors.primary.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Ambil Foto dari Kamera\n/ Pilih dari Galeri Tablet',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Format JPG atau PNG',
                                        style: TextStyle(
                                          color: AppColors.textMuted.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
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
                                    size: 20,
                                  ),
                                  label: const Text('Ambil dari Kamera'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                    ),
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Photo thumbnails
                              if (_existingPhotos.isNotEmpty ||
                                  _newPhotos.isNotEmpty)
                                SizedBox(
                                  height: 90,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        _existingPhotos.length +
                                        _newPhotos.length,
                                    itemBuilder: (context, index) {
                                      final isPrimary =
                                          index == _primaryPhotoIndex;
                                      Widget imageWidget;
                                      VoidCallback onDelete;

                                      if (index < _existingPhotos.length) {
                                        final photo = _existingPhotos[index];
                                        imageWidget = Image.file(
                                          File(photo.localPath),
                                          fit: BoxFit.cover,
                                        );
                                        onDelete = () async {
                                          await DatabaseHelper.instance
                                              .deleteItemPhoto(photo.id!);
                                          _loadExistingPhotos();
                                        };
                                      } else {
                                        final newIdx =
                                            index - _existingPhotos.length;
                                        imageWidget = Image.file(
                                          _newPhotos[newIdx],
                                          fit: BoxFit.cover,
                                        );
                                        onDelete = () => setState(
                                          () => _newPhotos.removeAt(newIdx),
                                        );
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 10,
                                        ),
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
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  border: isPrimary
                                                      ? Border.all(
                                                          color:
                                                              AppColors.primary,
                                                          width: 3,
                                                        )
                                                      : Border.all(
                                                          color:
                                                              AppColors.border,
                                                        ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  child: imageWidget,
                                                ),
                                              ),
                                              if (isPrimary)
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 3,
                                                        ),
                                                    decoration: const BoxDecoration(
                                                      color: AppColors.primary,
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                            bottom:
                                                                Radius.circular(
                                                                  15,
                                                                ),
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Foto Utama',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w700,
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
                                                    padding:
                                                        const EdgeInsets.all(2),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color:
                                                              AppColors.error,
                                                          shape:
                                                              BoxShape.circle,
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

                              const SizedBox(height: 32),

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            AppColors.textSecondary,
                                        side: const BorderSide(
                                          color: AppColors.cardBorder,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('Batal'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: _saveItem,
                                      child: const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text(
                                          'Simpan Barang',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text, {bool required = false, String? suffix}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            fontSize: 14,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (suffix != null) ...[
          const SizedBox(width: 6),
          Text(
            suffix,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {String? helperText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      helperText: helperText,
      helperMaxLines: 2,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
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

    final hargaInt = _basePrice.round();

    // 1. Tunai
    final tunaiRes = FinancingCalculator.simulasiTunai(hargaLelang: hargaInt);

    // 2. KCA
    final kcaRes = FinancingCalculator.simulasiKca(
      hargaLelang: hargaInt,
      config: _financingConfig!,
    );

    // 3. KRASIDA
    final defaultTenor = _financingTenors.isNotEmpty
        ? _financingTenors.first['months'] as int
        : 12;
    final krasidaRes = FinancingCalculator.simulasiKrasida(
      hargaLelang: hargaInt,
      config: _financingConfig!,
      tenors: _financingTenors,
      tenorMonths: defaultTenor,
    );

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'PREVIEW SIMULASI PEMBIAYAAN — ${currencyFormatter.format(hargaInt)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // TUNAI
          _buildPreviewRow(
            icon: Icons.money_outlined,
            iconColor: AppColors.successGreen,
            title: '💵 TUNAI',
            details: [
              'Total Bayar: ${currencyFormatter.format(tunaiRes.hargaLelang)}',
              '(Bayar penuh saat transaksi, tanpa bunga/cicilan)',
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // KCA
          if (kcaRes.eligible)
            _buildPreviewRow(
              icon: Icons.credit_card_outlined,
              iconColor: AppColors.info,
              title: '💳 KCA (Kredit Cicilan Angsuran) — Tempo ${kcaRes.tempoKca} Bulan',
              details: [
                'Uang Muka: ${currencyFormatter.format(kcaRes.uangMuka)}',
                'Uang Pinjaman: ${currencyFormatter.format(kcaRes.uangPinjaman)}',
                'Bunga Total: ${currencyFormatter.format(kcaRes.bungaTotalKca!)}',
                'Admin Fee: ${currencyFormatter.format(kcaRes.adminFee!)}',
                'Total Pelunasan: ${currencyFormatter.format(kcaRes.totalPelunasanKca!)}',
                '(Bayar bebas selama 4 bulan, tanpa angsuran rutin)',
              ],
            )
          else
            _buildIneligiblePreviewRow(
              title: '💳 KCA (Tidak Eligible)',
              message: kcaRes.message ?? '',
            ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // KRASIDA
          if (krasidaRes.eligible)
            _buildPreviewRow(
              icon: Icons.bar_chart_outlined,
              iconColor: AppColors.accent,
              title: '📊 KRASIDA (Kredit Gadai Sistem Angsuran)',
              details: [
                'Uang Muka: ${currencyFormatter.format(krasidaRes.uangMuka)}',
                'Uang Pinjaman: ${currencyFormatter.format(krasidaRes.uangPinjaman)}',
                'Angsuran per Bulan:',
                ...?krasidaRes.perbandinganTenor?.map((t) =>
                    '• ${t.tenor} bln : ${currencyFormatter.format(t.angsuranPerBulan)} / bln (total ${currencyFormatter.format(t.totalBayar)})'),
              ],
            )
          else
            _buildIneligiblePreviewRow(
              title: '📊 KRASIDA (Tidak Eligible)',
              message: krasidaRes.message ?? '',
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> details,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...details.map((d) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Text(
                d,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: d.startsWith('•') || d.contains('Total') ? FontWeight.w700 : FontWeight.w600,
                  color: d.startsWith('(') ? AppColors.textSecondary : AppColors.textDark,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildIneligiblePreviewRow({
    required String title,
    required String message,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
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
