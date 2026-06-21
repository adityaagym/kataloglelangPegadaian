import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/auction_item.dart';
import '../../models/item_photo.dart';
import '../../models/category.dart';
import '../../database/database_helper.dart';
import '../../utils/file_helper.dart';

class ItemFormScreen extends StatefulWidget {
  final AuctionItem? itemToEdit;

  const ItemFormScreen({super.key, this.itemToEdit});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  int? _categoryId;
  double _weightGram = 0;
  String? _karat;
  String _condition = 'Sangat Baik';
  double _basePrice = 0;
  String? _description;
  bool _isActive = true;

  List<File> _newPhotos = [];
  List<ItemPhoto> _existingPhotos = [];

  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
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
  }

  Future<void> _loadExistingPhotos() async {
    final photos = await Provider.of<AppProvider>(context, listen: false).getItemPhotos(widget.itemToEdit!.id!);
    setState(() {
      _existingPhotos = photos;
    });
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      if (_existingPhotos.length + _newPhotos.length + images.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maksimal 10 foto diperbolehkan.')));
        return;
      }
      setState(() {
        _newPhotos.addAll(images.map((xfile) => File(xfile.path)));
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu.')));
      return;
    }
    if (_existingPhotos.isEmpty && _newPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimal 1 foto wajib diunggah.')));
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    try {
      final dbHelper = DatabaseHelper.instance;
      int itemId;

      final item = AuctionItem(
        id: widget.itemToEdit?.id,
        name: _name,
        categoryId: _categoryId!,
        weightGram: _weightGram,
        karat: _karat,
        condition: _condition,
        basePrice: _basePrice,
        description: _description,
        isActive: _isActive,
        createdAt: widget.itemToEdit?.createdAt ?? DateTime.now().toIso8601String(),
      );

      if (widget.itemToEdit == null) {
        // Create
        itemId = await dbHelper.createAuctionItem(item);
      } else {
        // Update
        itemId = widget.itemToEdit!.id!;
        await dbHelper.updateAuctionItem(item);
      }

      // Save new photos to local directory and database
      for (int i = 0; i < _newPhotos.length; i++) {
        final localPath = await FileHelper.saveImageToLocalDirectory(_newPhotos[i]);
        final photo = ItemPhoto(
          itemId: itemId,
          localPath: localPath,
          isPrimary: widget.itemToEdit == null && i == 0 ? true : false, // first new photo is primary if new item
          sortOrder: _existingPhotos.length + i,
        );
        await dbHelper.createItemPhoto(photo);
      }

      await Provider.of<AppProvider>(context, listen: false).refreshAdminData();
      
      if (mounted) {
        Navigator.pop(context); // Go back to list or dashboard
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil disimpan!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.itemToEdit != null ? AppBar(title: const Text('Edit Barang')) : null,
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Panel - Form
                  Expanded(
                    flex: 1,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          if (widget.itemToEdit == null)
                            const Text('Tambah Barang Baru', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          
                          TextFormField(
                            initialValue: _name,
                            decoration: const InputDecoration(labelText: 'Nama Barang *', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                            onSaved: (val) => _name = val!,
                          ),
                          const SizedBox(height: 16),
                          
                          Consumer<AppProvider>(
                            builder: (context, provider, child) {
                              return DropdownButtonFormField<int>(
                                value: _categoryId,
                                decoration: const InputDecoration(labelText: 'Kategori *', border: OutlineInputBorder()),
                                items: provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                onChanged: (val) => setState(() => _categoryId = val),
                                validator: (val) => val == null ? 'Pilih kategori' : null,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: widget.itemToEdit != null ? _weightGram.toString() : '',
                                  decoration: const InputDecoration(labelText: 'Berat (gram) *', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                                  onSaved: (val) => _weightGram = double.parse(val!),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  initialValue: _karat,
                                  decoration: const InputDecoration(labelText: 'Karat (Opsional)', border: OutlineInputBorder()),
                                  onSaved: (val) => _karat = val,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          DropdownButtonFormField<String>(
                            value: _condition,
                            decoration: const InputDecoration(labelText: 'Kondisi *', border: OutlineInputBorder()),
                            items: ['Sangat Baik', 'Baik', 'Cukup', 'Perlu Perbaikan']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => setState(() => _condition = val!),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            initialValue: widget.itemToEdit != null ? _basePrice.toString() : '',
                            decoration: const InputDecoration(labelText: 'Harga Dasar Lelang (Rp) *', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                            onSaved: (val) => _basePrice = double.parse(val!),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            initialValue: _description,
                            decoration: const InputDecoration(labelText: 'Deskripsi Tambahan', border: OutlineInputBorder()),
                            maxLines: 3,
                            onSaved: (val) => _description = val,
                          ),
                          const SizedBox(height: 16),
                          
                          SwitchListTile(
                            title: const Text('Status Aktif'),
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 48),
                  
                  // Right Panel - Photos
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Upload Foto Barang (Min 1, Maks 10)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Klik untuk memilih foto', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _existingPhotos.length + _newPhotos.length,
                            itemBuilder: (context, index) {
                              if (index < _existingPhotos.length) {
                                // Existing photo
                                final photo = _existingPhotos[index];
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(File(photo.localPath), fit: BoxFit.cover),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4, right: 4,
                                      child: GestureDetector(
                                        onTap: () async {
                                          await DatabaseHelper.instance.deleteItemPhoto(photo.id!);
                                          _loadExistingPhotos();
                                        },
                                        child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                                      ),
                                    )
                                  ],
                                );
                              } else {
                                // New photo
                                final newIndex = index - _existingPhotos.length;
                                final file = _newPhotos[newIndex];
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(file, fit: BoxFit.cover),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4, right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _newPhotos.removeAt(newIndex);
                                          });
                                        },
                                        child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                                      ),
                                    )
                                  ],
                                );
                              }
                            },
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Padding(padding: EdgeInsets.all(16.0), child: Text('Batal')),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                                onPressed: _saveItem,
                                child: const Padding(padding: EdgeInsets.all(16.0), child: Text('Simpan Barang')),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
