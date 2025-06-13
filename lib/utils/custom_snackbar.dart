// lib/utils/custom_snackbar.dart

import 'package:flutter/material.dart';

// Enum untuk menentukan tipe notifikasi
enum NotificationType { success, error, info }

class CustomSnackBar {
  // Metode statis agar bisa dipanggil langsung tanpa membuat instance class
  static void show(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info, // Defaultnya adalah info
  }) {
    // Tentukan warna dan ikon berdasarkan tipe notifikasi
    Color backgroundColor;
    IconData iconData;

    switch (type) {
      case NotificationType.success:
        backgroundColor = Colors.green.shade700;
        iconData = Icons.check_circle_outline;
        break;
      case NotificationType.error:
        backgroundColor = Colors.red.shade800;
        iconData = Icons.error_outline;
        break;
      case NotificationType.info:
        backgroundColor = Colors.blue.shade700;
        iconData = Icons.info_outline;
        break;
    }

    // Buat dan tampilkan SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Konten utama yang berisi Ikon dan Pesan
        content: Row(
          children: [
            Icon(iconData, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
        
        // Styling SnackBar
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating, // Membuatnya mengambang
        margin: const EdgeInsets.all(16),   // Memberi jarak dari tepi layar
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Membuat sudut melengkung
        ),
        duration: const Duration(seconds: 3), // Durasi tampil
      ),
    );
  }
}