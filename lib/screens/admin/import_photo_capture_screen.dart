import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../database/database_helper.dart';
import '../../models/auction_item.dart';
import '../../utils/file_helper.dart';

class ImportPhotoCaptureScreen extends StatefulWidget {
  final List<int> itemIds;

  const ImportPhotoCaptureScreen({super.key, required this.itemIds});

  @override
  State<ImportPhotoCaptureScreen> createState() =>
      _ImportPhotoCaptureScreenState();
}

class _ImportPhotoCaptureScreenState extends State<ImportPhotoCaptureScreen> {
  int _currentIndex = 0;
  final Map<int, List<File>> _itemPhotos = {};
  List<AuctionItem> _items = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final db = DatabaseHelper.instance;
    final items = <AuctionItem>[];
    for (final id in widget.itemIds) {
      try {
        items.add(await db.readAuctionItem(id));
      } catch (_) {
        // Skip missing items
      }
    }
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    setState(() {
      _itemPhotos.putIfAbsent(_currentIndex, () => []).add(File(pickedFile.path));
    });
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    setState(() {
      _itemPhotos.putIfAbsent(_currentIndex, () => []).add(File(pickedFile.path));
    });
  }

  void _showPhotoSourceSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'PILIH SUMBER FOTO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF111827),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF111827)),
                title: const Text('Kamera', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF111827)),
                title: const Text('Galeri Foto', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removePhoto(int photoIndex) async {
    setState(() {
      _itemPhotos[_currentIndex]?.removeAt(photoIndex);
    });
  }

  Future<void> _saveCurrentItemPhotos() async {
    final photos = _itemPhotos[_currentIndex] ?? [];
    if (photos.isEmpty || _currentIndex >= _items.length) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final itemId = _items[_currentIndex].id!;

    for (var i = 0; i < photos.length; i++) {
      final savedPath = await FileHelper.saveImageToLocalDirectory(photos[i]);
      await provider.attachPhotoToItem(itemId, savedPath, isPrimary: i == 0);
    }
  }

  Future<void> _next() async {
    final photos = _itemPhotos[_currentIndex] ?? [];
    if (photos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Foto produk belum terupload! Harap unggah minimal 1 foto.',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            backgroundColor: Color(0xFFDC2626), // Corporate Red
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    await _saveCurrentItemPhotos();

    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex++;
        _isSaving = false;
      });
    } else {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Must click the button to close
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF16A34A),
                  size: 64,
                ),
                const SizedBox(height: 18),
                const Text(
                  'IMPOR SELESAI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Semua produk dan foto pendukung telah berhasil diunggah dan disimpan ke dalam katalog.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      final provider = Provider.of<AppProvider>(context, listen: false);
                      provider.finishPhotoImport();
                    },
                    child: const Text(
                      'SELESAI & KEMBALI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _skip() {
    if (_currentIndex < _items.length - 1) {
      setState(() => _currentIndex++);
    } else {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.finishPhotoImport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF16A34A)),
        ),
      );
    }

    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              await provider.cancelPhotoImport();
            },
          ),
          title: const Text(
            'Foto Produk',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF111827)),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Tidak ada item untuk difoto',
            style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
      );
    }

    final item = _items[_currentIndex];
    final photos = _itemPhotos[_currentIndex] ?? [];
    final progress = '${_currentIndex + 1}/${_items.length}';
    final isLast = _currentIndex >= _items.length - 1;
    final categoryName = item.categoryName ?? 'Lainnya';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () async {
            final provider = Provider.of<AppProvider>(context, listen: false);
            await provider.cancelPhotoImport();
          },
        ),
        title: Text(
          'Foto Produk $progress',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _items.length,
                backgroundColor: const Color(0xFFE5E7EB),
                color: const Color(0xFF16A34A),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),

            // 2. Item Info Card (Identical layout to the confirmation page card)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6), // Sharp corporate corners
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFlatCategoryBadge(categoryName),
                        const SizedBox(height: 6),
                        Text(
                          item.name.isEmpty ? '(Nama Kosong)' : item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (item.creditNumber?.isNotEmpty == true)
                              _buildBlueCreditNumberBadge(item.creditNumber!),
                            if (item.weightGram > 0)
                              _buildWeightBadge(item.weightGram),
                            if (item.karat != null && item.karat!.isNotEmpty)
                              _buildKaratBadge(item.karat!),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.payments_outlined, size: 18, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            currencyFormatter.format(item.basePrice),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF16A34A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Photo area
            if (photos.isEmpty)
              GestureDetector(
                onTap: () => _showPhotoSourceSelector(context),
                child: Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6), // Sharp corners
                    border: Border.all(
                      color: const Color(0xFFD1D5DB),
                      width: 1.5,
                      style: BorderStyle.solid, // Flat solid clean borders
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 44,
                        color: Color(0xFF6B7280),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Ambil Foto Produk',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ketuk untuk menggunakan Kamera atau Galeri',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == photos.length) {
                      // Add Photo Card
                      return GestureDetector(
                        onTap: () => _showPhotoSourceSelector(context),
                        child: Container(
                          height: 198,
                          width: 130,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFD1D5DB),
                              width: 1.5,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 28, color: Color(0xFF6B7280)),
                              SizedBox(height: 8),
                              Text(
                                'Tambah Foto',
                                style: TextStyle(
                                  color: Color(0xFF374151),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              photos[index],
                              height: 198,
                              width: 198,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removePhoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626), // Sharp corporate red
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                        if (index == 0)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'UTAMA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 32),
            Container(color: const Color(0xFFE5E7EB), height: 1),
            const SizedBox(height: 24),

            // 5. Navigation buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _isSaving ? null : _skip,
                    child: const Text(
                      'Lewati',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A), // Corporate Green
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _isSaving ? null : _next,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_alt, size: 18),
                    label: Text(
                      isLast ? 'Simpan & Selesai' : 'Simpan & Lanjut',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
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

  Widget _buildFlatCategoryBadge(String categoryName) {
    final isGold = categoryName.toLowerCase().contains('emas') ||
        categoryName.toLowerCase().contains('logam mulia');

    final bgColor = isGold ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6);
    final textColor = isGold ? const Color(0xFF92400E) : const Color(0xFF374151);
    final borderColor = isGold ? const Color(0xFFFDE68A) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        categoryName.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBlueCreditNumberBadge(String creditNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Light blue background
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFBFDBFE)), // Light blue border
      ),
      child: Text(
        creditNumber,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1E40AF), // Dark blue text
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }

  Widget _buildWeightBadge(double weight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Light green background
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.scale_outlined, size: 16, color: Color(0xFF166534)),
          const SizedBox(width: 4),
          Text(
            'Berat: ${weight}g',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKaratBadge(String karat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Light orange background
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_outlined, size: 16, color: Color(0xFFC2410C)),
          const SizedBox(width: 4),
          Text(
            'Karat: $karat',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFFC2410C),
            ),
          ),
        ],
      ),
    );
  }
}
