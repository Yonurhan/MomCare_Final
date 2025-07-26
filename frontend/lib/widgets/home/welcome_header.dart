import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  final String userName;

  const WelcomeHeader({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String greeting;
    final hour = TimeOfDay.now().hour;
    if (hour < 12) {
      greeting = 'Selamat Pagi ☀️';
    } else if (hour < 15) {
      greeting = 'Selamat Siang 🌤️';
    } else if (hour < 18) {
      greeting = 'Selamat Sore 🌇';
    } else {
      greeting = 'Selamat Malam 🌙';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.pink.withOpacity(0.1),
            child: const Icon(
              Icons.person_outline,
              color: Colors.pink,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
