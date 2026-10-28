import 'package:flutter/material.dart';

enum DeliveryStatus {
  waiting,    // Menunggu Muat / Keberangkatan
  departed,   // Dalam Perjalanan (Sudah Check-in Gudang Asal)
  inTransit,  // Sedang di titik transit / rest area
  arrived,    // Tiba di Gudang Tujuan (Siap Bongkar)
  completed,  // Selesai (Serah Terima & BAST Ditandatangani)
}

class CargoItem {
  final String id;
  final String name;
  final int expectedQty;
  int receivedQty;
  int damagedQty;
  String unit;
  String notes;

  CargoItem({
    required this.id,
    required this.name,
    required this.expectedQty,
    int? receivedQty,
    this.damagedQty = 0,
    this.unit = 'Koli',
    this.notes = '',
  }) : receivedQty = receivedQty ?? expectedQty;

  bool get hasDiscrepancy => receivedQty != expectedQty || damagedQty > 0;
}

class CheckpointEvent {
  final String id;
  final String title;
  final String locationName;
  final String coordinates;
  final DateTime timestamp;
  final String? photoUrl;
  final String? photoWatermarkText;
  final String notes;
  final bool isDone;

  CheckpointEvent({
    required this.id,
    required this.title,
    required this.locationName,
    required this.coordinates,
    required this.timestamp,
    this.photoUrl,
    this.photoWatermarkText,
    this.notes = '',
    this.isDone = false,
  });

  CheckpointEvent copyWith({
    String? id,
    String? title,
    String? locationName,
    String? coordinates,
    DateTime? timestamp,
    String? photoUrl,
    String? photoWatermarkText,
    String? notes,
    bool? isDone,
  }) {
    return CheckpointEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      locationName: locationName ?? this.locationName,
      coordinates: coordinates ?? this.coordinates,
      timestamp: timestamp ?? this.timestamp,
      photoUrl: photoUrl ?? this.photoUrl,
      photoWatermarkText: photoWatermarkText ?? this.photoWatermarkText,
      notes: notes ?? this.notes,
      isDone: isDone ?? this.isDone,
    );
  }
}

class HandoverReport {
  final String recipientName;
  final String recipientPhone;
  final String recipientPin;
  final DateTime signedAt;
  final List<Offset?> signaturePoints;
  final String complaintNote;
  final bool hasComplaint;
  final String? handoverPhotoWatermark;

  HandoverReport({
    required this.recipientName,
    required this.recipientPhone,
    this.recipientPin = '8921',
    required this.signedAt,
    required this.signaturePoints,
    this.complaintNote = '',
    this.hasComplaint = false,
    this.handoverPhotoWatermark,
  });
}

class DeliveryOrder {
  final String id;
  final String suratJalanNumber;
  final String resiNumber;
  final String originWarehouse;
  final String destinationWarehouse;
  final String routeType; // 'Point-to-Point' atau 'Multi-Drop Transit'
  final DateTime scheduledDate;
  DeliveryStatus status;
  final List<CargoItem> cargoItems;
  final List<CheckpointEvent> checkpoints;
  HandoverReport? handoverReport;

  DeliveryOrder({
    required this.id,
    required this.suratJalanNumber,
    required this.resiNumber,
    required this.originWarehouse,
    required this.destinationWarehouse,
    this.routeType = 'Point-to-Point',
    required this.scheduledDate,
    required this.status,
    required this.cargoItems,
    required this.checkpoints,
    this.handoverReport,
  });

  int get totalExpectedKoli =>
      cargoItems.fold(0, (sum, item) => sum + item.expectedQty);

  int get totalReceivedKoli =>
      cargoItems.fold(0, (sum, item) => sum + item.receivedQty);

  String get statusLabel {
    switch (status) {
      case DeliveryStatus.waiting:
        return 'Menunggu Keberangkatan';
      case DeliveryStatus.departed:
        return 'Dalam Perjalanan';
      case DeliveryStatus.inTransit:
        return 'Titik Transit';
      case DeliveryStatus.arrived:
        return 'Tiba di Tujuan';
      case DeliveryStatus.completed:
        return 'Selesai (BAST)';
    }
  }

  Color get statusColor {
    switch (status) {
      case DeliveryStatus.waiting:
        return const Color(0xFFF59E0B); // Amber
      case DeliveryStatus.departed:
        return const Color(0xFF3B82F6); // Blue
      case DeliveryStatus.inTransit:
        return const Color(0xFF8B5CF6); // Purple
      case DeliveryStatus.arrived:
        return const Color(0xFF06B6D4); // Cyan
      case DeliveryStatus.completed:
        return const Color(0xFF10B981); // Emerald Green
    }
  }
}
