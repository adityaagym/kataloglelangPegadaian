import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/imported_auction_item.dart';
import '../../utils/app_colors.dart';
import 'import_photo_capture_screen.dart';

class ImportConfirmationScreen extends StatelessWidget {
  const ImportConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Data Import',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final items = provider.importDraftItems;
          final validSelectedCount = provider.selectedImportCount;

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada data untuk dikonfirmasi',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return Column(
            children: [
              // Summary bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${items.length} baris ditemukan',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '$validSelectedCount item valid terpilih',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _toggleAll(provider),
                      icon: const Icon(Icons.checklist, size: 18),
                      label: const Text('Pilih Semua'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Item list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final imported = items[index];
                    return _buildItemCard(context, provider, imported);
                  },
                ),
              ),
              // Bottom action bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.clearImportDraft();
                            Navigator.pop(context);
                          },
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: validSelectedCount > 0
                              ? () => _proceedToPhotos(context, provider)
                              : null,
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: Text(
                            'Lanjut Input Foto ($validSelectedCount)',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    AppProvider provider,
    ImportedAuctionItem imported,
  ) {
    final item = imported.item;
    final hasErrors = !imported.isValid;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasErrors ? Colors.red.shade200 : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: imported.isSelected && imported.isValid,
                  onChanged: imported.isValid
                      ? (_) =>
                          provider.toggleItemSelection(imported.rowIndex)
                      : null,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name.isEmpty ? '(Nama kosong)' : item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Baris ${imported.rowIndex}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasErrors)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Error',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Valid',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    children: [
                      _infoChip(
                        Icons.category_outlined,
                        'Kategori ID: ${item.categoryId}',
                      ),
                      _infoChip(Icons.scale_outlined, '${item.weightGram}g'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Harga: Rp ${item.basePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                  if (hasErrors) ...[
                    const SizedBox(height: 8),
                    ...imported.validationErrors.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $e',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _toggleAll(AppProvider provider) {
    final allValidSelected = provider.importDraftItems
        .where((i) => i.isValid)
        .every((i) => i.isSelected);

    final newItems = provider.importDraftItems.map((imported) {
      if (!imported.isValid) return imported;
      return imported.copyWith(isSelected: !allValidSelected);
    }).toList();

    provider.setImportDraft(newItems);
  }

  Future<void> _proceedToPhotos(
    BuildContext context,
    AppProvider provider,
  ) async {
    final savedIds = await provider.saveImportedItems();
    if (savedIds.isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada item yang tersimpan')),
      );
      return;
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ImportPhotoCaptureScreen(itemIds: savedIds),
        ),
      );
    }
  }
}
