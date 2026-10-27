import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../models/delivery_model.dart';

class MockDataService extends ChangeNotifier {
  static final MockDataService instance = MockDataService._internal();

  factory MockDataService() {
    return instance;
  }

  MockDataService._internal() {
    _initMockData();
  }

  late DriverProfile driver;
  late List<DeliveryOrder> deliveries;
  String? activeDeliveryId;

  DeliveryOrder? get activeDelivery {
    if (activeDeliveryId == null) {
      final activeList = deliveries.where((d) => d.status != DeliveryStatus.completed).toList();
      return activeList.isNotEmpty ? activeList.first : null;
    }
    return deliveries.firstWhere((d) => d.id == activeDeliveryId, orElse: () => deliveries.first);
  }

  void _initMockData() {
    driver = DriverProfile(
      id: 'DRV-0082',
      name: 'Bambang Supriyanto',
      phone: '+62 812-3456-7890',
      licensePlate: 'B 9482 TEK',
      truckType: 'Hino Dutro Box 6-Wheeler (CDD)',
      companyName: 'PT Logistik Mandiri Sejahtera',
      isClockedIn: true,
      clockInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 25)),
      sessionDaysRemaining: 44,
      autoRenewActive: true,
    );

    deliveries = [
      DeliveryOrder(
        id: 'DEL-101',
        suratJalanNumber: 'SJ/LOG/2026/X/0491',
        resiNumber: 'EXP-9921820',
        originWarehouse: 'Gudang Pusat Cakung, Jakarta Timur',
        destinationWarehouse: 'Gudang Distribusi Kaligawe, Semarang',
        routeType: 'Multi-Drop Transit',
        scheduledDate: DateTime.now(),
        status: DeliveryStatus.departed,
        cargoItems: [
          CargoItem(
            id: 'ITM-1',
            name: 'Minyak Goreng Sawit 2L (Karton isi 6)',
            expectedQty: 250,
            receivedQty: 250,
            unit: 'Dus',
          ),
          CargoItem(
            id: 'ITM-2',
            name: 'Gula Pasir Kristal Putih Premium 50kg',
            expectedQty: 80,
            receivedQty: 80,
            unit: 'Karung',
          ),
          CargoItem(
            id: 'ITM-3',
            name: 'Tepung Terigu Segitiga Cakra 25kg',
            expectedQty: 120,
            receivedQty: 120,
            unit: 'Sak',
          ),
          CargoItem(
            id: 'ITM-4',
            name: 'Biskuit Kaleng Aneka Rasa (Export)',
            expectedQty: 60,
            receivedQty: 60,
            unit: 'Karton',
          ),
        ],
        checkpoints: [
          CheckpointEvent(
            id: 'CP-1',
            title: 'Check-in Muat Gudang Asal',
            locationName: 'Gudang Pusat Cakung DC 1, Jakarta',
            coordinates: '-6.1925° S, 106.9452° E',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
            photoUrl: 'mock_asset_origin',
            photoWatermarkText: 'GPS: -6.1925, 106.9452\nTime: 2026-10-24 08:35:10 WIB\nNopol: B 9482 TEK | Driver: Bambang S.\nSJ: SJ/LOG/2026/X/0491 [Gudang Cakung]',
            notes: 'Pemeriksaan ban, kebersihan box dan segel nomor SG-8819 oke.',
            isDone: true,
          ),
          CheckpointEvent(
            id: 'CP-2',
            title: 'Titik Transit / Rest Area',
            locationName: 'Rest Area KM 207A Tol Palikanci, Cirebon',
            coordinates: '-6.7820° S, 108.5630° E',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            photoUrl: 'mock_asset_transit',
            photoWatermarkText: 'GPS: -6.7820, 108.5630\nTime: 2026-10-24 10:45:00 WIB\nNopol: B 9482 TEK | Driver: Bambang S.\nSJ: SJ/LOG/2026/X/0491 [Rest Area KM 207A]',
            notes: 'Istirahat 30 menit, periksa suhu pendingin & segel box tetap aman.',
            isDone: true,
          ),
          CheckpointEvent(
            id: 'CP-3',
            title: 'Gudang Transit Drop 1',
            locationName: 'Hub Transit Brebes Timur',
            coordinates: '-6.8712° S, 109.0415° E',
            timestamp: DateTime.now().add(const Duration(hours: 1)),
            notes: 'Drop dokumen & periksa alur rute jalan Pantura.',
            isDone: false,
          ),
          CheckpointEvent(
            id: 'CP-4',
            title: 'Tiba di Gudang Tujuan Akhir',
            locationName: 'Gudang Distribusi Kaligawe, Semarang',
            coordinates: '-6.9531° S, 110.4502° E',
            timestamp: DateTime.now().add(const Duration(hours: 3)),
            notes: 'Bongkar muat, cek fisik barang & tanda tangan BAST.',
            isDone: false,
          ),
        ],
      ),
      DeliveryOrder(
        id: 'DEL-102',
        suratJalanNumber: 'SJ/LOG/2026/X/0502',
        resiNumber: 'EXP-9922001',
        originWarehouse: 'Gudang Pusat Cakung, Jakarta',
        destinationWarehouse: 'Gudang Logistik Cilegon, Banten',
        routeType: 'Point-to-Point',
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        status: DeliveryStatus.waiting,
        cargoItems: [
          CargoItem(
            id: 'ITM-201',
            name: 'Pipa PVC Industri Ukuran 4 inch',
            expectedQty: 300,
            receivedQty: 300,
            unit: 'Batang',
          ),
          CargoItem(
            id: 'ITM-202',
            name: 'Fitting & Sambungan Pipa Tipe T',
            expectedQty: 50,
            receivedQty: 50,
            unit: 'Kotak',
          ),
        ],
        checkpoints: [
          CheckpointEvent(
            id: 'CP-201',
            title: 'Check-in Muat Gudang Asal',
            locationName: 'Gudang Pusat Cakung DC 2, Jakarta',
            coordinates: '-6.1925° S, 106.9452° E',
            timestamp: DateTime.now().add(const Duration(hours: 20)),
            isDone: false,
          ),
          CheckpointEvent(
            id: 'CP-202',
            title: 'Tiba di Gudang Tujuan',
            locationName: 'Gudang Industri Krakatau, Cilegon',
            coordinates: '-6.0121° S, 106.0422° E',
            timestamp: DateTime.now().add(const Duration(hours: 24)),
            isDone: false,
          ),
        ],
      ),
      DeliveryOrder(
        id: 'DEL-100',
        suratJalanNumber: 'SJ/LOG/2026/X/0410',
        resiNumber: 'EXP-9918731',
        originWarehouse: 'Gudang Karawang Barat',
        destinationWarehouse: 'Gudang Ritel Cikarang Dry Port',
        routeType: 'Point-to-Point',
        scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
        status: DeliveryStatus.completed,
        cargoItems: [
          CargoItem(
            id: 'ITM-99',
            name: 'Elektronik Kulkas 2 Pintu Inverter',
            expectedQty: 40,
            receivedQty: 40,
            unit: 'Unit',
          ),
          CargoItem(
            id: 'ITM-100',
            name: 'Mesin Cuci Front Loading 8.5kg',
            expectedQty: 30,
            receivedQty: 29,
            damagedQty: 1,
            unit: 'Unit',
            notes: '1 unit kardus penyok ujung kanan bawah.',
          ),
        ],
        checkpoints: [
          CheckpointEvent(
            id: 'CP-901',
            title: 'Check-in Muat Gudang Asal',
            locationName: 'Gudang Karawang Barat',
            coordinates: '-6.3012° S, 107.2911° E',
            timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
            isDone: true,
          ),
          CheckpointEvent(
            id: 'CP-902',
            title: 'Tiba di Gudang Tujuan',
            locationName: 'Gudang Ritel Cikarang Dry Port',
            coordinates: '-6.2711° S, 107.1523° E',
            timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
            isDone: true,
          ),
        ],
        handoverReport: HandoverReport(
          recipientName: 'Hendra Gunawan (Kepala Gudang Cikarang)',
          recipientPhone: '+62 821-9988-7711',
          recipientPin: '7721',
          signedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3, minutes: 40)),
          signaturePoints: [
            const Offset(50, 40),
            const Offset(90, 80),
            const Offset(130, 45),
            const Offset(160, 90),
            null,
            const Offset(170, 70),
            const Offset(220, 65),
          ],
          hasComplaint: true,
          complaintNote: 'Kardus 1 unit mesin cuci tertekan saat transit, sudah dibuatkan klaim garansi vendor.',
          handoverPhotoWatermark: 'GPS: -6.2711, 107.1523\nTime: 2026-10-23 15:20:00 WIB\nNopol: B 9482 TEK | Driver: Bambang S.\nBAST: SJ/LOG/2026/X/0410 [Penerima: Hendra G.]',
        ),
      ),
    ];
  }

  // Actions
  void toggleClockIn() {
    if (driver.isClockedIn) {
      driver.clockOut();
    } else {
      driver.clockIn();
    }
    notifyListeners();
  }

  void renewJwtSession() {
    driver.renewSession();
    notifyListeners();
  }

  void selectActiveDelivery(String id) {
    activeDeliveryId = id;
    notifyListeners();
  }

  void updateDeliveryStatus(String id, DeliveryStatus newStatus) {
    final order = deliveries.firstWhere((d) => d.id == id);
    order.status = newStatus;
    notifyListeners();
  }

  void advanceCheckpoint(String deliveryId, int checkpointIndex, {String? notes, String? watermarkText}) {
    final order = deliveries.firstWhere((d) => d.id == deliveryId);
    if (checkpointIndex >= 0 && checkpointIndex < order.checkpoints.length) {
      final old = order.checkpoints[checkpointIndex];
      order.checkpoints[checkpointIndex] = old.copyWith(
        isDone: true,
        timestamp: DateTime.now(),
        notes: notes ?? old.notes,
        photoWatermarkText: watermarkText ?? old.photoWatermarkText,
      );

      // Otomatis update status pengiriman sesuai titik
      if (checkpointIndex == 0) {
        order.status = DeliveryStatus.departed;
      } else if (checkpointIndex < order.checkpoints.length - 1) {
        order.status = DeliveryStatus.inTransit;
      } else {
        order.status = DeliveryStatus.arrived;
      }

      notifyListeners();
    }
  }

  void addTransitCheckpoint(String deliveryId, String locationTitle, String coords, String notes, String watermark) {
    final order = deliveries.firstWhere((d) => d.id == deliveryId);
    final newEvent = CheckpointEvent(
      id: 'CP-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Update Titik: $locationTitle',
      locationName: locationTitle,
      coordinates: coords,
      timestamp: DateTime.now(),
      notes: notes,
      photoWatermarkText: watermark,
      isDone: true,
    );
    // Masukkan sebelum checkpoint terakhir (tujuan)
    final insertIdx = order.checkpoints.length > 1 ? order.checkpoints.length - 1 : order.checkpoints.length;
    order.checkpoints.insert(insertIdx, newEvent);
    order.status = DeliveryStatus.inTransit;
    notifyListeners();
  }

  void submitHandover({
    required String deliveryId,
    required String recipientName,
    required String recipientPhone,
    required String recipientPin,
    required List<Offset?> signaturePoints,
    required String complaintNote,
    required bool hasComplaint,
    required List<CargoItem> updatedCargo,
    String? handoverWatermark,
  }) {
    final order = deliveries.firstWhere((d) => d.id == deliveryId);

    // Update cargo discrepancy
    for (int i = 0; i < updatedCargo.length; i++) {
      if (i < order.cargoItems.length) {
        order.cargoItems[i].receivedQty = updatedCargo[i].receivedQty;
        order.cargoItems[i].damagedQty = updatedCargo[i].damagedQty;
        order.cargoItems[i].notes = updatedCargo[i].notes;
      }
    }

    order.handoverReport = HandoverReport(
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      recipientPin: recipientPin,
      signedAt: DateTime.now(),
      signaturePoints: signaturePoints,
      complaintNote: complaintNote,
      hasComplaint: hasComplaint,
      handoverPhotoWatermark: handoverWatermark,
    );

    // Tandai semua checkpoint selesai
    for (int i = 0; i < order.checkpoints.length; i++) {
      order.checkpoints[i] = order.checkpoints[i].copyWith(isDone: true);
    }

    order.status = DeliveryStatus.completed;
    notifyListeners();
  }
}
