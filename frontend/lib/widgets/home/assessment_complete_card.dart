import 'package:flutter/material.dart';

class AssessmentCompleteCard extends StatelessWidget {
  // 1. Tambahkan parameter onTap agar bisa menerima aksi
  final VoidCallback onTap;

  const AssessmentCompleteCard({Key? key, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 2. Bungkus dengan Material dan InkWell agar ada efek ripple saat di-tap
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 12),
              // 3. Gunakan Expanded agar teks tidak overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan Anda sudah terbaru!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                        fontSize: 16,
                      ),
                    ),
                    // 4. Tambahkan subtitle sebagai petunjuk
                    Text(
                      'Ketuk untuk melihat lagi',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 5. Tambahkan ikon panah sebagai petunjuk visual
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.green.shade700),
            ],
          ),
        ),
      ),
    );
  }
}
