import 'dart:ui';
import 'package:flutter/material.dart';

/// An exceptionally beautiful and artistic header widget.
/// It combines soft gradients, layered decorative shapes, and refined icons
/// to create a premium and delightful user experience.
class WelcomeHeader extends StatelessWidget {
  final String userName;
  final int notificationCount;

  const WelcomeHeader({
    Key? key,
    required this.userName,
    this.notificationCount = 0,
  }) : super(key: key);

  /// Determines the dynamic greeting based on the time of day.
  String _getGreeting() {
    // Current time is 4:40 PM
    final hour = DateTime.now().toUtc().add(const Duration(hours: 7)).hour;
    if (hour < 12) return 'Selamat Pagi ☀️';
    if (hour < 15) return 'Selamat Siang 🌤️';
    if (hour < 18) return 'Selamat Sore 🌇';
    return 'Selamat Malam 🌙';
  }

  /// Gets the initial from the user's name.
  String _getUserInitial() {
    if (userName.isEmpty) return "U";
    return userName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 40),
      decoration: _buildHeaderDecoration(),
      child: Stack(
        clipBehavior: Clip.none, // Allow shapes to go outside the bounds
        children: [
          // FIX: Decorative shapes are moved here directly from the old method.
          // They are placed first to be in the background.
          Positioned(
            top: -80,
            left: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          // The blurred filter for a frosted glass effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Main content is the last non-positioned child, defining the Stack's size.
          _buildMainContent(context),
        ],
      ),
    );
  }

  /// A beautiful gradient background decoration.
  BoxDecoration _buildHeaderDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF8E95F2), // Soft Purple-Blue
          Color(0xFFF39AB8), // Soft Pink
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF8E95F2).withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // FIX: The _buildDecorativeShapes method is no longer needed and has been removed.

  /// The main content row with text and action icons.
  Widget _buildMainContent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTextColumn(context),
        _buildActionIcons(context, _getUserInitial()),
      ],
    );
  }

  /// The text column with a clear typographic hierarchy.
  Widget _buildTextColumn(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final greeting = _getGreeting(); // Correctly shows "Selamat Sore"

    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            greeting,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                )
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Halo, $userName',
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  /// The action icons row with enhanced styling.
  Widget _buildActionIcons(BuildContext context, String initial) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNotificationIcon(context),
        const SizedBox(width: 16),
        _buildUserAvatar(initial),
      ],
    );
  }

  /// A beautifully styled notification icon with a glassmorphism effect.
  Widget _buildNotificationIcon(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 28,
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF37B7B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// A premium user avatar with a subtle inner gradient.
  Widget _buildUserAvatar(String initial) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Color(0xFF6A71C4),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
