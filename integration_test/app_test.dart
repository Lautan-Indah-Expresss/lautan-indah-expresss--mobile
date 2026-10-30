import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/driver_delivery_screen.dart';
import 'package:mobile/widgets/action_location_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Driver Logistics E2E & Button Anti-Spam Validation Suite', () {
    testWidgets('1. App login input validation & visibility toggle', (tester) async {
      await tester.pumpWidget(const LieDriverApp());
      await tester.pump();

      // Skip splash screen delay
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Check login elements
      expect(find.text('DRIVER'), findsOneWidget);
      expect(find.text('PT LAUTAN INDAH EXPRESS'), findsOneWidget);

      // Verify empty field validation
      final loginBtn = find.text('MASUK KE APLIKASI');
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();
      expect(find.text('Nama pengguna dan kata sandi wajib diisi.'), findsOneWidget);

      // Verify typing
      final usernameInput = find.widgetWithText(TextField, 'Masukkan nama pengguna...');
      await tester.enterText(usernameInput, 'driver_budi');

      final passwordInput = find.widgetWithText(TextField, 'Masukkan kata sandi...');
      await tester.enterText(passwordInput, 'aman1234');
      await tester.pumpAndSettle();

      expect(find.text('driver_budi'), findsOneWidget);

      // Password toggle
      final toggle = find.byIcon(Icons.visibility);
      if (toggle.evaluate().isNotEmpty) {
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      }
    });

    testWidgets('2. Delivery action buttons state validation (Absen, Posisi, Kendala, Selesai/Tiba)', (tester) async {
      final mockShipment = {
        'id': 101,
        'resi': 'LIE-JKT-SBY-001',
        'status': 'tertunda',
        'origin_city': 'Jakarta',
        'destination_city': 'Surabaya',
        'receiver_company': 'PT Sejahtera Abadi',
        'destination_address': 'Jl. Rungkut Industri No. 45',
        'receiver_phone': '081234567890',
        'total_colli': 10,
        'actual_weight_kg': 500,
        'nopol': 'B 9876 XYZ',
        'has_active_issue': false,
        'driver_arrived': false,
        'checkpoints': <dynamic>[],
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DriverDeliveryScreen(
            shipment: mockShipment,
            isDriverCurrentlyDriving: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi detail surat jalan
      expect(find.text('LIE-JKT-SBY-001'), findsOneWidget);
      expect(find.text('PT Sejahtera Abadi'), findsOneWidget);

      // Verifikasi tombol absen (tampak di viewport awal)
      final btnAbsen = find.text('1. FOTO ABSEN & MULAI JALAN');
      expect(btnAbsen, findsOneWidget);

      final btnAbsenWidget = tester.widget<ElevatedButton>(find.ancestor(of: btnAbsen, matching: find.byType(ElevatedButton)));
      expect(btnAbsenWidget.enabled, isTrue, reason: 'Tombol absen harus aktif sebelum berangkat');

      // Scroll ke bawah untuk melihat tombol posisi, kendala, dan sampai
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      final btnPosisi = find.text('2. LIHAT PETA & LAPOR POSISI');
      final btnKendala = find.text('3. LAPOR KENDALA DI JALAN');
      final btnSampai = find.text('4. SUDAH SAMPAI DI GUDANG TUJUAN');

      expect(btnPosisi, findsOneWidget);
      expect(btnKendala, findsOneWidget);
      expect(btnSampai, findsOneWidget);

      final btnPosisiWidget = tester.widget<ElevatedButton>(find.ancestor(of: btnPosisi, matching: find.byType(ElevatedButton)));
      final btnKendalaWidget = tester.widget<ElevatedButton>(find.ancestor(of: btnKendala, matching: find.byType(ElevatedButton)));
      final btnSampaiWidget = tester.widget<ElevatedButton>(find.ancestor(of: btnSampai, matching: find.byType(ElevatedButton)));

      expect(btnPosisiWidget.enabled, isFalse, reason: 'Tombol posisi harus disable sebelum absen');
      expect(btnKendalaWidget.enabled, isFalse, reason: 'Tombol kendala harus disable sebelum absen');
      expect(btnSampaiWidget.enabled, isFalse, reason: 'Tombol tiba harus disable sebelum absen');
    });

    testWidgets('3. Action dialog photo requirement & mandatory description validation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ActionLocationDialog(
              title: 'Lapor Kendala Darurat di Jalan',
              subtitle: 'Wajib foto bukti kendala & tulis alasan',
              showTextInput: true,
              inputLabel: 'Jelaskan Kerusakan:',
              inputHint: 'Contoh: Ban bocor...',
              actionButtonText: 'KIRIM PERINGATAN KENDALA',
              actionColor: Colors.red,
              actionIcon: Icons.warning_amber_rounded,
              driverPosition: const LatLng(-6.2, 106.8),
              originCity: 'Jakarta',
              destinationCity: 'Surabaya',
              onPickCameraPhoto: () async => null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final submitBtn = find.text('KIRIM PERINGATAN KENDALA');
      expect(submitBtn, findsOneWidget);

      // Validasi 1: Tekan kirim tanpa isi keterangan
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Harap isi keterangan/alasan terlebih dahulu!'), findsOneWidget);

      // Isi keterangan
      final inputField = find.widgetWithText(TextField, 'Contoh: Ban bocor...');
      await tester.enterText(inputField, 'Ban pecah di KM 88');
      await tester.pumpAndSettle();

      // Validasi 2: Tekan kirim keterangan sudah ada TAPI belum ambil foto kamera
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Wajib ambil foto bukti kamera terlebih dahulu!'), findsOneWidget);
    });

    testWidgets('4. Single-drop task lock validation when driver is currently driving another trip', (tester) async {
      final mockShipment = {
        'id': 102,
        'resi': 'LIE-BDG-SMG-002',
        'status': 'tertunda',
        'origin_city': 'Bandung',
        'destination_city': 'Semarang',
        'nopol': 'D 1234 ABC',
        'has_active_issue': false,
        'driver_arrived': false,
        'checkpoints': <dynamic>[],
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DriverDeliveryScreen(
            shipment: mockShipment,
            // Sopir sedang aktif berkendara di resi/tugas lain
            isDriverCurrentlyDriving: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Harus muncul banner peringatan bahwa tugas ini terkunci
      expect(
        find.text('Anda sedang aktif dalam perjalanan tugas lain. Selesaikan tugas berjalan sebelum memulai tugas pengiriman ini.'),
        findsOneWidget,
      );

      // Tombol absen harus berubah teks menjadi terkunci dan berstatus disabled
      final lockedBtn = find.text('1. TERKUNCI (MENUNGGU TUGAS AKTIF)');
      expect(lockedBtn, findsOneWidget);

      final buttonWidget = tester.widget<ElevatedButton>(find.ancestor(of: lockedBtn, matching: find.byType(ElevatedButton)));
      expect(buttonWidget.enabled, isFalse, reason: 'Tombol harus terkunci saat driver aktif menyetir tugas lain');
    });

    testWidgets('5. Active delivery state enables Posisi, Kendala, and Arrival buttons', (tester) async {
      final mockShipment = {
        'id': 103,
        'resi': 'LIE-SUB-MLG-003',
        'status': 'dalam_pengiriman',
        'origin_city': 'Surabaya',
        'destination_city': 'Malang',
        'checkpoints': <dynamic>[],
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DriverDeliveryScreen(
            shipment: mockShipment,
            isDriverCurrentlyDriving: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll ke bawah agar tombol aksi 2, 3, 4 masuk ke viewport
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Pada status 'dalam_pengiriman':
      // Tombol 2 (Posisi), 3 (Kendala), 4 (Sampai) harus enabled
      final btnPosisi = find.text('2. LIHAT PETA & LAPOR POSISI');
      final btnKendala = find.text('3. LAPOR KENDALA DI JALAN');
      final btnSampai = find.text('4. SUDAH SAMPAI DI GUDANG TUJUAN');

      expect(btnPosisi, findsOneWidget);
      expect(btnKendala, findsOneWidget);
      expect(btnSampai, findsOneWidget);

      final btnPosisiWidget = tester.widget<ElevatedButton>(find.ancestor(of: btnPosisi, matching: find.byType(ElevatedButton)));
      final btnKendalaWidget = tester.widget<ElevatedButton>(find.ancestor(of: btnKendala, matching: find.byType(ElevatedButton)));
      final btnSampaiWidget = tester.widget<ElevatedButton>(find.ancestor(of: btnSampai, matching: find.byType(ElevatedButton)));

      expect(btnPosisiWidget.enabled, isTrue);
      expect(btnKendalaWidget.enabled, isTrue);
      expect(btnSampaiWidget.enabled, isTrue);
    });
  });
}
