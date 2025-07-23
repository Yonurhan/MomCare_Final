// lib/theme/app_bar_clipper.dart
import 'package:flutter/material.dart';

class AppBarClipper extends CustomClipper<Path> {
  // Changed to public class name 'AppBarClipper'
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30); // Start from bottom-left, slightly up
    path.quadraticBezierTo(
      size.width / 2, size.height, // Control point at bottom center
      size.width, size.height - 30, // End at bottom-right, slightly up
    );
    path.lineTo(size.width, 0); // Line to top-right
    path.close(); // Close the path to top-left
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
