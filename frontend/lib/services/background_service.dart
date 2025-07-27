import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';

// Nama unik untuk tugas background
const assessmentTask = "assessmentReminderTask";

// Fungsi ini HARUS berada di level atas (top-level) atau static
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == assessmentTask) {
      // Inisialisasi service notifikasi di dalam background context
      NotificationService.initialize();
      // Tampilkan notifikasi
      await NotificationService.showNotification(
        id: 1,
        title: 'Jangan Lupa Asesmen Mingguan Anda!',
        body:
            'Luangkan waktu sejenak untuk mengisi laporan kesehatan Anda minggu ini.',
      );
    }
    return Future.value(true);
  });
}
