import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/item_photo.dart';
import '../../utils/app_colors.dart';
import 'item_list_screen.dart';
import 'item_form_screen.dart';
import 'gold_price_screen.dart';
import 'backup_screen.dart';
import 'financing_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = DashboardOverview(
          onNavigateToGoldPrice: () => setState(() => _selectedIndex = 3),
        );
        break;
      case 1:
        content = const ItemListScreen();
        break;
      case 2:
        content = const ItemFormScreen();
        break;
      case 3:
        content = GoldPriceScreen(
          onNavigateToItem: () => setState(() => _selectedIndex = 1),
        );
        break;
      case 4:
        content = const BackupScreen();
        break;
      case 5:
        content = const FinancingScreen();
        break;
      default:
        content = DashboardOverview(
          onNavigateToGoldPrice: () => setState(() => _selectedIndex = 3),
        );
    }

    return Scaffold(
      body: Row(
        children: [
          // Left Navigation Sidebar
          _buildSidebar(),

          // Main Content Area
          Expanded(
            child: Container(color: AppColors.background, child: content),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(right: BorderSide(color: Color(0xFFD7E7D8))),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Image.asset(
                      'assets/logo_pegadaian_syariah.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Panel Admin label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'PANEL ADMIN',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Database lokal',
                        style: TextStyle(
                          color: AppColors.successGreen.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Consumer<AppProvider>(
                        builder: (context, provider, _) {
                          return Text(
                            provider.branchName,
                            style: TextStyle(
                              color: AppColors.successGreen.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Navigation items
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Column(
                  children: [
                    _buildNavItem(
                      Icons.dashboard_outlined,
                      Icons.dashboard,
                      'Ringkasan',
                      0,
                    ),
                    _buildNavItem(
                      Icons.inventory_2_outlined,
                      Icons.inventory_2,
                      'Kelola Barang',
                      1,
                    ),
                    _buildNavItem(
                      Icons.add_box_outlined,
                      Icons.add_box,
                      'Tambah Barang',
                      2,
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      Icons.diamond_outlined,
                      Icons.diamond,
                      'Harga Emas',
                      3,
                    ),
                    _buildNavItem(
                      Icons.backup_outlined,
                      Icons.backup,
                      'Backup Data',
                      4,
                    ),
                    _buildNavItem(
                      Icons.account_balance_outlined,
                      Icons.account_balance,
                      'Pembiayaan',
                      5,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Keluar ke Katalog',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData iconOutline,
    IconData iconFilled,
    String title,
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? iconFilled : iconOutline,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dashboard Overview
class DashboardOverview extends StatefulWidget {
  final VoidCallback onNavigateToGoldPrice;
  const DashboardOverview({super.key, required this.onNavigateToGoldPrice});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  int _activeItemCount = 0;
  Map<String, dynamic>? _topCategory;
  List<Map<String, dynamic>> _recentItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final count = await provider.getActiveItemCount();
    final topCat = await provider.getTopCategory();
    final recent = await provider.getRecentItems(limit: 3);

    if (mounted) {
      setState(() {
        _activeItemCount = count;
        _topCategory = topCat;
        _recentItems = recent;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Katalog Outlet',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sistem Database Offline (SQLite) Aktif',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Hari Ini, $timeStr',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Workflow info card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFD7E7D8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.article_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Alur kerja: update harga emas, kelola barang, lalu backup database lokal.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Update Harga Emas button
                GestureDetector(
                  onTap: widget.onNavigateToGoldPrice,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Update\nHarga\nEmas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stat cards row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.successGreen,
                    label: 'Total Barang\nAktif',
                    value: '$_activeItemCount',
                    suffix: 'Barang',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.category_outlined,
                    iconColor: AppColors.primary,
                    label: 'Kategori\nTerbanyak',
                    value: _topCategory?['name'] ?? '-',
                    suffix: _topCategory != null
                        ? '(${_topCategory!['cnt']})'
                        : '',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Consumer<AppProvider>(
                    builder: (context, provider, _) {
                      String updateTime = 'Belum ada';
                      if (provider.goldPriceUpdatedAt != null) {
                        try {
                          final dt = DateTime.parse(provider.goldPriceUpdatedAt!);
                          updateTime =
                              'Hari Ini,\n${DateFormat('HH:mm').format(dt)}';
                        } catch (_) {
                          updateTime = 'Hari Ini';
                        }
                      }
                      return _buildStatCard(
                        icon: Icons.access_time,
                        iconColor: AppColors.textMuted,
                        label: 'Update\nTerakhir',
                        value: updateTime,
                        suffix: '',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Recent activity
          Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Aktivitas Terbaru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_recentItems.length} item terakhir',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_recentItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Belum ada aktivitas.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...List.generate(_recentItems.length, (index) {
                    final item = _recentItems[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _recentItems.length - 1 ? 12 : 0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail preview
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: FutureBuilder<List<ItemPhoto>>(
                                future: Provider.of<AppProvider>(context, listen: false).getItemPhotos(item['id']),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.file(
                                        File(snapshot.data!.first.localPath),
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.image_outlined,
                                          color: AppColors.textMuted,
                                          size: 24,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Icon(
                                    Icons.image_outlined,
                                    color: AppColors.textMuted,
                                    size: 24,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item['weight_gram']}g',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormatter.format(
                                (item['base_price'] as num).toDouble(),
                              ),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String suffix = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.035),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.15,
            ),
          ),
          if (suffix.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              suffix,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
