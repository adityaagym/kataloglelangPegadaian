import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/auction_item.dart';
import 'item_form_screen.dart';
import 'dart:io';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).refreshAdminData();
    });
  }

  void _confirmDelete(BuildContext context, AuctionItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang Lelang?'),
        content: Text("Apakah Anda yakin ingin menghapus '${item.name}'? Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).deleteItem(item.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Ya, Hapus Permanen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kelola Barang Lelang', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Tambah Barang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onPressed: () {
                  // Usually we would navigate to the form here, but since we are using a side nav,
                  // we might need to use a callback to change the selected index in AdminDashboard.
                  // For simplicity, we can push it as a modal page route.
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const Scaffold(body: ItemFormScreen())));
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final items = provider.items; // When in admin, items holds all data (active & inactive)
                  if (items.isEmpty) {
                    return const Center(child: Text('Belum ada data barang lelang.'));
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: FutureBuilder(
                          future: provider.getItemPhotos(item.id!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(snapshot.data!.first.localPath),
                                  width: 50, height: 50, fit: BoxFit.cover,
                                  errorBuilder: (_,__,___) => const Icon(Icons.image),
                                ),
                              );
                            }
                            return const Icon(Icons.image, size: 50);
                          },
                        ),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.categoryName} • ${currencyFormatter.format(item.basePrice)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.isActive ? Colors.green.shade100 : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.isActive ? 'Aktif' : 'Non-aktif',
                                style: TextStyle(color: item.isActive ? Colors.green.shade800 : Colors.grey.shade700, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(body: ItemFormScreen(itemToEdit: item))));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, item),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
