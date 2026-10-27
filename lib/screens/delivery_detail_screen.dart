import 'package:flutter/material.dart';
import '../models/delivery_model.dart';
import '../services/mock_data_service.dart';
import 'watermark_camera_screen.dart';
import 'handover_screen.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final String deliveryId;

  const DeliveryDetailScreen({super.key, required this.deliveryId});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final MockDataService _service = MockDataService();

  void _openCameraForCheckpoint(int index, CheckpointEvent cp, DeliveryOrder delivery) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => WatermarkCameraScreen(
          title: cp.title,
          deliveryNumber: delivery.suratJalanNumber,
          defaultLocation: cp.locationName,
        ),
      ),
    );

    if (result != null && mounted) {
      final watermark = result['watermark'] as String?;
      final preset = result['preset'] as String?;
      _service.advanceCheckpoint(
        widget.deliveryId,
        index,
        notes: 'Check-in berhasil via kamera native [$preset].',
        watermarkText: watermark,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkpoint "${cp.title}" berhasil di-update dengan Watermark!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _showAddTransitDialog(DeliveryOrder delivery) {
    final nameCtrl = TextEditingController(text: 'Rest Area Tol / Pos Transit Mandiri');
    final noteCtrl = TextEditingController(text: 'Istirahat dan pengecekan segel box truk.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Titik Transit / Pos Istirahat', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sesuai SOP, sistem event-based tracking memperbarui posisi peta saat driver melaporkan titik istirahat/transit.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Titik Transit / Rest Area',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan Driver',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final locName = nameCtrl.text.trim();
              final notes = noteCtrl.text.trim();
              Navigator.of(ctx).pop();

              // Buka kamera untuk watermark titik transit ini
              final photoResult = await Navigator.of(context).push<Map<String, dynamic>>(
                MaterialPageRoute(
                  builder: (context) => WatermarkCameraScreen(
                    title: 'Foto Titik Transit: $locName',
                    deliveryNumber: delivery.suratJalanNumber,
                    defaultLocation: locName,
                  ),
                ),
              );

              final watermark = photoResult != null ? photoResult['watermark'] as String? : 'Watermark Verified';
              _service.addTransitCheckpoint(
                widget.deliveryId,
                locName,
                '-6.8201° S, 108.7723° E',
                notes,
                watermark ?? '',
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Titik transit ditambahkan ke rute & peta web admin diperbarui!'),
                    backgroundColor: Color(0xFF8B5CF6),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lanjut Foto Watermark'),
          ),
        ],
      ),
    );
  }

  void _showWatermarkDetailDialog(CheckpointEvent cp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 8),
            Text(cp.title, style: const TextStyle(fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lokasi: ${cp.locationName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                cp.photoWatermarkText ?? 'Tidak ada data watermark',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
            if (cp.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Catatan: ${cp.notes}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final delivery = _service.deliveries.firstWhere(
          (d) => d.id == widget.deliveryId,
          orElse: () => _service.deliveries.first,
        );

        final isCompleted = delivery.status == DeliveryStatus.completed;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(delivery.suratJalanNumber, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Bagikan Link Tracking Publik',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link Guest Tracking Resi ${delivery.resiNumber} disalin ke clipboard!'),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card Status & Rute
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: delivery.statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            delivery.statusLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: delivery.statusColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            delivery.routeType,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Resi: ${delivery.resiNumber}',
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      delivery.suratJalanNumber,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const Divider(height: 24),

                    // Asal & Tujuan Rute
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.radio_button_checked, size: 18, color: Color(0xFF3B82F6)),
                            Container(width: 2, height: 36, color: Colors.grey.shade300),
                            const Icon(Icons.location_on, size: 20, color: Color(0xFFEF4444)),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ASAL MUAT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                              Text(delivery.originWarehouse, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                              const SizedBox(height: 16),
                              Text('TUJUAN BONGKAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                              Text(delivery.destinationWarehouse, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Ringkasan Muatan / Koli
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF0F172A)),
                        const SizedBox(width: 8),
                        const Text(
                          'Daftar Muatan Barang',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const Spacer(),
                        Text(
                          'Total: ${delivery.totalExpectedKoli} Koli',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    ...delivery.cargoItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                              ),
                            ),
                            Text(
                              '${item.receivedQty} / ${item.expectedQty} ${item.unit}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: item.hasDiscrepancy ? Colors.red.shade700 : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Event-Based Checkpoint Tracker
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timeline, size: 20, color: Color(0xFF0F172A)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Event-Based Checkpoint & Peta',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                        if (!isCompleted)
                          OutlinedButton.icon(
                            onPressed: () => _showAddTransitDialog(delivery),
                            icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                            label: const Text('+ Transit', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8B5CF6),
                              side: const BorderSide(color: Color(0xFF8B5CF6)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ikon truk di peta web admin berpindah otomatis tiap kali sopir melakukan check-in titik di bawah ini.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 20),

                    ...delivery.checkpoints.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final cp = entry.value;
                      final isLast = idx == delivery.checkpoints.length - 1;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline Pillar & Indicator
                            Column(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: cp.isDone ? const Color(0xFF10B981) : Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      cp.isDone ? Icons.check : Icons.circle,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: cp.isDone ? const Color(0xFF10B981) : Colors.grey.shade300,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Content Info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cp.title,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: cp.isDone ? const Color(0xFF0F172A) : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                        if (cp.isDone)
                                          Text(
                                            '${cp.timestamp.hour.toString().padLeft(2, '0')}:${cp.timestamp.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cp.locationName,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                    ),
                                    if (cp.isDone && cp.photoWatermarkText != null) ...[
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () => _showWatermarkDetailDialog(cp),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A).withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.photo_camera, size: 14, color: Color(0xFF10B981)),
                                              SizedBox(width: 6),
                                              Text(
                                                'Lihat Bukti Foto Watermark',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (!cp.isDone) ...[
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _openCameraForCheckpoint(idx, cp, delivery),
                                        icon: const Icon(Icons.camera_alt, size: 16),
                                        label: const Text('Check-in & Foto Watermark', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0F172A),
                                          foregroundColor: Colors.white,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // BAST Box if completed
              if (isCompleted && delivery.handoverReport != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Text(
                            'Berita Acara Serah Terima (BAST) Selesai',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Penerima: ${delivery.handoverReport!.recipientName}', style: const TextStyle(fontSize: 13, color: Color(0xFF047857))),
                      Text('No. Kontak: ${delivery.handoverReport!.recipientPhone}', style: const TextStyle(fontSize: 13, color: Color(0xFF047857))),
                      Text('Status Komplain: ${delivery.handoverReport!.hasComplaint ? "Ada Catatan Selisih" : "Bongkar Bersih & Lengkap"}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: delivery.handoverReport!.hasComplaint ? Colors.orange.shade900 : Colors.green.shade900)),
                      if (delivery.handoverReport!.complaintNote.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Catatan: ${delivery.handoverReport!.complaintNote}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],
          ),
          bottomNavigationBar: isCompleted
              ? null
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2)),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HandoverScreen(delivery: delivery),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    label: const Text(
                      'Bongkar Muat & Tanda Tangan Penerima',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
