import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/auction_item.dart';
import '../providers/app_provider.dart';
import '../models/item_photo.dart';

class ItemDetailScreen extends StatefulWidget {
  final AuctionItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 200,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
          label: const Text('Kembali ke Katalog', style: TextStyle(color: Color(0xFF1B5E20), fontSize: 16)),
        ),
      ),
      body: Row(
        children: [
          // Left Column (Carousel)
          Expanded(
            flex: 55,
            child: FutureBuilder<List<ItemPhoto>>(
              future: Provider.of<AppProvider>(context, listen: false).getItemPhotos(widget.item.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final photos = snapshot.data ?? [];
                
                if (photos.isEmpty) {
                  return const Center(child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey));
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 500,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: photos.length > 1,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                      ),
                      items: photos.map((photo) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.symmetric(horizontal: 5.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(photo.localPath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.error),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: photos.asMap().entries.map((entry) {
                        return Container(
                          width: 12.0,
                          height: 12.0,
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF1B5E20))
                                .withOpacity(_currentImageIndex == entry.key ? 0.9 : 0.4),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Right Column (Details)
          Expanded(
            flex: 45,
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF424242)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9A825).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.item.categoryName ?? 'Unknown',
                      style: const TextStyle(color: Color(0xFFF9A825), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildSpecRow('Berat', '${widget.item.weightGram} gram'),
                  if (widget.item.karat != null && widget.item.karat!.isNotEmpty) 
                    _buildSpecRow('Karat', widget.item.karat!),
                  _buildSpecRow('Kondisi', widget.item.condition),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 32),
                  const Text('Harga Dasar Lelang:', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(widget.item.basePrice),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFF9A825)),
                  ),
                  const SizedBox(height: 32),
                  if (widget.item.description != null && widget.item.description!.isNotEmpty) ...[
                    const Text('Deskripsi:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(widget.item.description!, style: const TextStyle(fontSize: 16, height: 1.5)),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 18, color: Colors.grey))),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
