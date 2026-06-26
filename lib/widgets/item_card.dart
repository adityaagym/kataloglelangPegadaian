import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/auction_item.dart';
import '../providers/app_provider.dart';
import '../screens/item_detail_screen.dart';
import '../utils/app_colors.dart';

class ItemCard extends StatelessWidget {
  final AuctionItem item;

  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final category = item.categoryName ?? 'Lainnya';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ItemDetailScreen(item: item)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFD2D2D2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark.withValues(alpha: 0.055),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: FutureBuilder(
                    future: Provider.of<AppProvider>(
                      context,
                      listen: false,
                    ).getItemPhotos(item.id!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final photos = snapshot.data!;
                        final primaryPhoto = photos.firstWhere(
                          (p) => p.isPrimary,
                          orElse: () => photos.first,
                        );
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.file(
                                  File(primaryPhoto.localPath),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 54,
                                        color: AppColors.textMuted,
                                      ),
                                ),
                              ),
                            ),
                            if (item.karat != null && item.karat!.isNotEmpty)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    item.karat!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }
                      return const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 54,
                          color: AppColors.textMuted,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.categoryBadgeBg(category),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.categoryBadgeText(category),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HARGA AWAL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              currencyFormatter.format(item.basePrice),
                              style: const TextStyle(
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                height: 1.05,
                              ),
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
        ),
      ),
    );
  }
}
