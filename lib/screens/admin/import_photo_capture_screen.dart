import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../database/database_helper.dart';
import '../../models/auction_item.dart';
import '../../utils/file_helper.dart';
import '../../utils/app_colors.dart';

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
    setState(() => _isSaving = true);
    await _saveCurrentItemPhotos();

    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex++;
        _isSaving = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua foto berhasil disimpan ✓'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  void _skip() {
    if (_currentIndex < _items.length - 1) {
      setState(() => _currentIndex++);
    } else {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Foto Produk')),
        body: const Center(child: Text('Tidak ada item untuk difoto')),
      );
    }

    final item = _items[_currentIndex];
    final photos = _itemPhotos[_currentIndex] ?? [];
    final progress = '${_currentIndex + 1}/${_items.length}';
    final isLast = _currentIndex >= _items.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Foto Produk $progress',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _items.length,
                backgroundColor: AppColors.muted,
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 20),
            // Item info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    children: [
                      Text(
                        'Berat: ${item.weightGram}g',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Harga: Rp ${item.basePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Photo area
            if (photos.isEmpty)
              GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Ketuk untuk ambil foto',
                        style: TextStyle(color: AppColors.textMuted),
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
                  itemCount: photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            photos[index],
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => _removePhoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
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
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Utama',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            // Photo action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Galeri'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Kamera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _skip,
                    child: const Text('Lewati'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
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
}
