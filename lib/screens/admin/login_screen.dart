import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  final String _defaultPin = '123456'; // Fallback default PIN
  bool _isError = false;

  void _onKeypadTap(String value) {
    if (_pin.length < 6) {
      setState(() {
        _pin += value;
        _isError = false;
      });
      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('admin_pin') ?? _defaultPin;

    if (_pin == savedPin) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      }
    } else {
      setState(() {
        _isError = true;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Color(0xFF1B5E20)),
              const SizedBox(height: 16),
              const Text('Katalog Lelang Admin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Masukkan PIN Admin Cabang', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              
              // PIN Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length ? const Color(0xFF1B5E20) : Colors.grey.shade300,
                      border: _isError ? Border.all(color: Colors.red, width: 2) : null,
                    ),
                  );
                }),
              ),
              if (_isError)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text('PIN Salah, coba lagi.', style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 48),

              // Keypad
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) return const SizedBox(); // Empty space
                  if (index == 11) {
                    return InkWell(
                      onTap: _onBackspace,
                      customBorder: const CircleBorder(),
                      child: const Center(child: Icon(Icons.backspace_outlined, size: 28)),
                    );
                  }
                  final number = index == 10 ? '0' : '${index + 1}';
                  return InkWell(
                    onTap: () => _onKeypadTap(number),
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: Text(number, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
