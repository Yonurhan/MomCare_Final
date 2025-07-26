// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Membuat instance tunggal dari plugin notifikasi
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Method untuk menginisialisasi plugin
  static void initialize() {
    // Pengaturan inisialisasi untuk Android
    // Pastikan Anda memiliki ikon bernama 'ic_launcher' di folder android/app/src/main/res/mipmap
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Pengaturan inisialisasi utama
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      // Tambahkan pengaturan untuk iOS/macOS di sini jika diperlukan
    );

    // Menjalankan inisialisasi plugin
    _notificationsPlugin.initialize(initializationSettings);
  }

  // Method untuk menampilkan notifikasi
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Detail spesifik untuk notifikasi Android
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'assessment_channel_id', // ID unik untuk channel
      'Pengingat Asesmen', // Nama channel yang terlihat oleh pengguna
      channelDescription:
          'Channel untuk notifikasi pengingat asesmen mingguan.',
      importance: Importance.max,
      priority: Priority.high,
    );

    // Menggabungkan detail notifikasi untuk berbagai platform
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // Menampilkan notifikasi
    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }
}
