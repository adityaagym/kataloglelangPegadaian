import 'dart:io';
import 'dart:async';
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
import 'contact_screen.dart';
import 'bulk_import_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  String _getMenuTitle(int index) {
    switch (index) {
      case 0:
        return 'Ringkasan';
      case 1:
        return 'Kelola Barang';
      case 2:
        return 'Tambah Barang';
      case 3:
        return 'Harga Emas';
      case 4:
        return 'Backup Data';
      case 5:
        return 'Pembiayaan';
      case 6:
        return 'Informasi Kontak';
      case 7:
        return 'Import Massal';
      default:
        return 'Panel Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).size.width < 900;
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
      case 6:
        content = const ContactScreen();
        break;
      case 7:
        content = const BulkImportScreen();
        break;
      default:
        content = DashboardOverview(
          onNavigateToGoldPrice: () => setState(() => _selectedIndex = 3),
        );
    }

    return Scaffold(
      appBar: isPortrait
          ? AppBar(
              title: Text(
                _getMenuTitle(_selectedIndex),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: const Color(0xFFD7E7D8),
                  height: 1,
                ),
              ),
              leading: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: AppColors.textDark,
                      size: 24,
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              ),
            )
          : null,
      drawer: isPortrait
          ? Drawer(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: _buildSidebar(isDrawer: true),
            )
          : null,
      body: Row(
        children: [
          // Left Navigation Sidebar
          if (!isPortrait) _buildSidebar(isDrawer: false),

          // Main Content Area
          Expanded(
            child: Container(color: AppColors.background, child: content),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool isDrawer}) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: isDrawer
            ? null
            : const Border(right: BorderSide(color: Color(0xFFD7E7D8))),
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
                    color: const Color.fromARGB(255, 255, 255, 255),
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
                    horizontal: 70,
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
                      isDrawer: isDrawer,
                    ),
                    _buildNavItem(
                      Icons.diamond_outlined,
                      Icons.diamond,
                      'Harga Emas',
                      3,
                      isDrawer: isDrawer,
                    ),
                    _buildNavItem(
                      Icons.account_balance_outlined,
                      Icons.account_balance,
                      'Pembiayaan',
                      5,
                      isDrawer: isDrawer,
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      Icons.add_box_outlined,
                      Icons.add_box,
                      'Tambah Barang',
                      2,
                      isDrawer: isDrawer,
                    ),
                    _buildNavItem(
                      Icons.file_upload_outlined,
                      Icons.file_upload,
                      'Import Massal',
                      7,
                      isDrawer: isDrawer,
                    ),
                    _buildNavItem(
                      Icons.inventory_2_outlined,
                      Icons.inventory_2,
                      'Kelola Barang',
                      1,
                      isDrawer: isDrawer,
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      Icons.backup_outlined,
                      Icons.backup,
                      'Backup Data',
                      4,
                      isDrawer: isDrawer,
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      Icons.info_outline,
                      Icons.info,
                      'Informasi Kontak',
                      6,
                      isDrawer: isDrawer,
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
              onTap: () {
                if (isDrawer) {
                  Navigator.pop(context);
                }
                Navigator.pop(context);
              },
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
    int index, {
    required bool isDrawer,
  }) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => _selectedIndex = index);
          if (isDrawer) {
            Navigator.pop(context);
          }
        },
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
  double _totalBasePrice = 0;
  List<Map<String, dynamic>> _categoryBreakdown = [];
  bool _isLoading = true;
  DateTime _currentDeviceTime = DateTime.now();
  Timer? _timeTimer;

  @override
  void initState() {
    super.initState();
    _currentDeviceTime = DateTime.now();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDeviceTime = DateTime.now();
        });
      }
    });
    _loadStats();
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final count = await provider.getActiveItemCount();
    final topCat = await provider.getTopCategory();
    final recent = await provider.getRecentItems(limit: 3);
    final total = await provider.getTotalBasePrice();
    final breakdown = await provider.getCategoryBreakdown();

    if (mounted) {
      setState(() {
        _activeItemCount = count;
        _topCategory = topCat;
        _recentItems = recent;
        _totalBasePrice = total;
        _categoryBreakdown = breakdown;
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
    final timeStr = DateFormat('HH:mm').format(_currentDeviceTime);
    final isPortrait = MediaQuery.of(context).size.width < 900;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.all(isPortrait ? 20 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20), // Lower the header
            // Title row
            isPortrait
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Katalog Outlet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sistem Database Offline (SQLite) Aktif',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9), // Pegadaian light green
                          borderRadius: BorderRadius.circular(6), // Sharp corporate corners
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Text(
                          'Hari Ini, $timeStr',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ringkasan Katalog Outlet',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Sistem Database Offline (SQLite) Aktif',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9), // Pegadaian light green
                          borderRadius: BorderRadius.circular(6), // Sharp corporate corners
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Text(
                          'Hari Ini, $timeStr',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
  
            // Workflow info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6), // Sharp corners
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: isPortrait
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.article_outlined,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Alur kerja: update harga emas, kelola barang, lalu backup database lokal.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: widget.onNavigateToGoldPrice,
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text(
                              'Update Harga Emas',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.article_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Alur kerja: update harga emas, kelola barang, lalu backup database lokal.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Update Harga Emas button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: widget.onNavigateToGoldPrice,
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text(
                              'Update Harga Emas',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
  
            // Stat cards row
            isPortrait
                ? Column(
                    children: [
                      _buildStatCard(
                        icon: Icons.inventory_2_outlined,
                        iconColor: AppColors.successGreen,
                        label: 'Total Barang Aktif',
                        value: '$_activeItemCount',
                        suffix: 'Barang',
                      ),
                      const SizedBox(height: 16),
                      _buildTopCategoryCard(),
                      const SizedBox(height: 16),
                      Consumer<AppProvider>(
                        builder: (context, provider, _) {
                          String updateTime = 'Belum ada';
                          if (provider.lastItemUpdatedAt != null) {
                            try {
                              final dt = DateTime.parse(provider.lastItemUpdatedAt!);
                              final now = DateTime.now();
                              final isToday = dt.year == now.year &&
                                  dt.month == now.month &&
                                  dt.day == now.day;
                              if (isToday) {
                                updateTime =
                                    'Hari Ini, ${DateFormat('HH:mm').format(dt)}';
                              } else {
                                updateTime =
                                    DateFormat('dd MMM, HH:mm').format(dt);
                              }
                            } catch (_) {
                              updateTime = 'Baru saja';
                            }
                          }
                          return _buildStatCard(
                            icon: Icons.access_time,
                            iconColor: AppColors.textMuted,
                            label: 'Update Terakhir',
                            value: updateTime,
                            suffix: '',
                          );
                        },
                      ),
                    ],
                  )
                : IntrinsicHeight(
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
                        Expanded(child: _buildTopCategoryCard()),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Consumer<AppProvider>(
                            builder: (context, provider, _) {
                              String updateTime = 'Belum ada';
                              if (provider.lastItemUpdatedAt != null) {
                                try {
                                  final dt = DateTime.parse(provider.lastItemUpdatedAt!);
                                  final now = DateTime.now();
                                  final isToday = dt.year == now.year &&
                                      dt.month == now.month &&
                                      dt.day == now.day;
                                  if (isToday) {
                                    updateTime =
                                        'Hari Ini,\n${DateFormat('HH:mm').format(dt)}';
                                  } else {
                                    updateTime =
                                        DateFormat('dd MMM,\nHH:mm').format(dt);
                                  }
                                } catch (_) {
                                  updateTime = 'Baru saja';
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
            const SizedBox(height: 24),

            // Nilai Transaksi card
            _buildTransactionValueCard(currencyFormatter),
            const SizedBox(height: 28),
  
            // Recent activity
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE5E7EB)),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Text(
                          '${_recentItems.length} item terakhir',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
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
                          style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_recentItems.length, (index) {
                      final item = _recentItems[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < _recentItems.length - 1 ? 10 : 0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              // Thumbnail preview
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: FutureBuilder<List<ItemPhoto>>(
                                  future: Provider.of<AppProvider>(context, listen: false).getItemPhotos(item['id']),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.file(
                                          File(snapshot.data!.first.localPath),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.image_outlined,
                                            color: AppColors.textMuted,
                                            size: 20,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Icon(
                                      Icons.image_outlined,
                                      color: AppColors.textMuted,
                                      size: 20,
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
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textDark,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Berat: ${item['weight_gram']}g',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
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
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
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
      ),
    );
  }

  // Returns the official category text color
  Color _categoryColor(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('perhiasan') || (n.contains('emas') && !n.contains('logam'))) {
      return const Color(0xFFD97706);
    } else if (n.contains('logam')) {
      return const Color(0xFF475569);
    } else if (n.contains('elektronik')) {
      return const Color(0xFF4338CA);
    } else if (n.contains('kendaraan')) {
      return const Color(0xFF1E3A8A);
    }
    return AppColors.textSecondary;
  }

  Color _categoryBgColor(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('perhiasan') || (n.contains('emas') && !n.contains('logam'))) {
      return const Color(0xFFFEF3C7);
    } else if (n.contains('logam')) {
      return const Color(0xFFE2E8F0);
    } else if (n.contains('elektronik')) {
      return const Color(0xFFEDE9FE);
    } else if (n.contains('kendaraan')) {
      return const Color(0xFFDBEAFE);
    }
    return const Color(0xFFF3F4F6);
  }

  Color _categoryBorderColor(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('perhiasan') || (n.contains('emas') && !n.contains('logam'))) {
      return const Color(0xFFFDE68A);
    } else if (n.contains('logam')) {
      return const Color(0xFFCBD5E1);
    } else if (n.contains('elektronik')) {
      return const Color(0xFFC4B5FD);
    } else if (n.contains('kendaraan')) {
      return const Color(0xFFBFDBFE);
    }
    return const Color(0xFFE5E7EB);
  }

  Widget _buildTopCategoryCard() {
    final catName = _topCategory?['name'] as String?;
    final cnt = _topCategory?['cnt'];
    final color = _categoryColor(catName);
    final bgColor = _categoryBgColor(catName);
    final borderColor = _categoryBorderColor(catName);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Kategori\nTerbanyak',
                  style: TextStyle(
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
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.category_outlined, color: AppColors.primary, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (catName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                catName.toUpperCase(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            )
          else
            const Text(
              '-',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                height: 1.15,
              ),
            ),
          if (cnt != null) ...[
            const SizedBox(height: 6),
            Text(
              '($cnt barang)',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionValueCard(NumberFormat currencyFormatter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nilai Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Total nilai harga dasar seluruh barang aktif',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Grand total badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'GRAND TOTAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(_totalBasePrice),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_categoryBreakdown.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            // Per-category breakdown
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _categoryBreakdown.map((cat) {
                final catName = cat['name'] as String?;
                final cnt = cat['cnt'];
                final totalVal = (cat['total_value'] as num?)?.toDouble() ?? 0;
                final color = _categoryColor(catName);
                final bgColor = _categoryBgColor(catName);
                final borderColor = _categoryBorderColor(catName);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (catName ?? '-').toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormatter.format(totalVal),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$cnt barang',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6), // Sharp corporate corners
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
