import 'dart:async';
import 'package:flutter/material.dart';

class IdleTimeoutWrapper extends StatefulWidget {
  final Widget child;
  final Duration timeoutDuration;
  final VoidCallback onTimeout;

  const IdleTimeoutWrapper({
    super.key,
    required this.child,
    this.timeoutDuration = const Duration(minutes: 3),
    required this.onTimeout,
  });

  @override
  State<IdleTimeoutWrapper> createState() => _IdleTimeoutWrapperState();
}

class _IdleTimeoutWrapperState extends State<IdleTimeoutWrapper> {
  Timer? _timer;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_isDialogShowing) return;

    _timer = Timer(widget.timeoutDuration, _showTimeoutWarning);
  }

  void _handleUserInteraction([_]) {
    _startTimer();
  }

  void _showTimeoutWarning() {
    if (_isDialogShowing) return;
    setState(() => _isDialogShowing = true);

    int countdown = 10;
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (countdown > 0) {
                setStateDialog(() {
                  countdown--;
                });
              } else {
                timer.cancel();
                Navigator.of(context).pop(true); // Return true meaning timeout reached
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Column(
                children: [
                  Icon(Icons.timer, color: Color(0xFF1B5E20), size: 48),
                  SizedBox(height: 16),
                  Text('Masih di Sini?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Layar akan kembali ke halaman utama katalog dalam', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: countdown / 10,
                          backgroundColor: Colors.grey[200],
                          color: const Color(0xFF1B5E20),
                          strokeWidth: 8,
                        ),
                      ),
                      Text('$countdown', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('detik untuk nasabah berikutnya.', textAlign: TextAlign.center),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        countdownTimer?.cancel();
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('Ya, Tetap di Sini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        countdownTimer?.cancel();
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Kembali ke Beranda', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      countdownTimer?.cancel();
      setState(() => _isDialogShowing = false);
      if (result == true) {
        widget.onTimeout();
      } else {
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
