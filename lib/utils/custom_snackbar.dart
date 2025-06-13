// lib/utils/custom_snackbar.dart
import 'package:flutter/material.dart';


enum NotificationType { success, error, info }

class CustomSnackBar {
  
  static void show(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info, 
  }) {
    
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

    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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

        
        
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating, 
        margin: const EdgeInsets.all(16),   
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
        ),
        duration: const Duration(seconds: 3), // Durasi tampil
      ),
    );
  }
}
