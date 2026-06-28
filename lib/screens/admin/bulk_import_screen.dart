import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/excel_template_service.dart';
import '../../utils/app_colors.dart';
import 'import_confirmation_screen.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _downloadTemplate() async {
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final categories = provider.categories;
      final bytes = ExcelTemplateService.generateTemplateBytes(categories);

      final directory =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/template_produk_lelang.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template disimpan di $filePath'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickExcelFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.parseImportFile(result.files.single.bytes!);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ImportConfirmationScreen()),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Import Massal Produk',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unduh template, isi data produk, lalu unggah file Excel untuk diimport ke database.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildCard(
            icon: Icons.download_outlined,
            title: '1. Unduh Template Excel',
            description:
                'Template sudah berisi daftar kategori yang tersedia di database.',
            buttonLabel: 'Unduh Template',
            onPressed: _downloadTemplate,
          ),
          const SizedBox(height: 20),
          _buildCard(
            icon: Icons.upload_file_outlined,
            title: '2. Unggah File Excel',
            description:
                'Pilih file .xlsx yang sudah diisi sesuai format template.',
            buttonLabel: 'Pilih File Excel',
            onPressed: _pickExcelFile,
            isLoading: _isLoading,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          // Instructions card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Petunjuk Pengisian',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _instructionRow('Kolom Nama Produk, Kategori, Berat, Kondisi, dan Harga Dasar wajib diisi.'),
                _instructionRow('Kategori harus sesuai dengan daftar di sheet "Daftar Kategori".'),
                _instructionRow('Kondisi hanya boleh: Baik, Cukup Baik, atau Perlu Perbaikan.'),
                _instructionRow('Baris yang kosong sepenuhnya akan diabaikan otomatis.'),
                _instructionRow('Setelah konfirmasi data, Anda akan diminta menginput foto per produk.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward, size: 18),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
