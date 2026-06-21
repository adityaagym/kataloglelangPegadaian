import 'package:flutter/material.dart';
import 'item_list_screen.dart';
import 'item_form_screen.dart';

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
        content = const DashboardOverview();
        break;
      case 1:
        content = const ItemListScreen();
        break;
      case 2:
        content = const ItemFormScreen();
        break;
      default:
        content = const DashboardOverview();
    }

    return Scaffold(
      body: Row(
        children: [
          // Left Navigation Drawer
          Container(
            width: 250,
            color: const Color(0xFF1B5E20),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Admin Panel',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildNavItem(Icons.dashboard, 'Ringkasan', 0),
                _buildNavItem(Icons.list_alt, 'Daftar Barang', 1),
                _buildNavItem(Icons.add_box, 'Tambah Barang', 2),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text('Keluar', style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    Navigator.pop(context); // Go back to Kiosk mode
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: Container(
              color: const Color(0xFFF5F7FA),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}

// Simple overview widget
class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selamat Datang, Admin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 32),
          Text('Gunakan menu di sebelah kiri untuk mengelola katalog lelang.'),
        ],
      ),
    );
  }
}
