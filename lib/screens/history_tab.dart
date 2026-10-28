import 'package:flutter/material.dart';
import '../models/delivery_model.dart';
import '../services/mock_data_service.dart';
import '../widgets/signature_pad.dart';
import 'delivery_detail_screen.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MockDataService();

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final completedOrders = service.deliveries
            .where((d) => d.status == DeliveryStatus.completed)
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Riwayat Pengiriman & BAST', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: completedOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_toggle_off, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada pengiriman yang diselesaikan.',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Setelah proses bongkar & tanda tangan BAST, arsip akan muncul di sini.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: completedOrders.length,
                  itemBuilder: (context, index) {
                    final order = completedOrders[index];
                    final report = order.handoverReport;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'BAST TERBIT',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                  ),
                                ),
                                const Spacer(),
                                if (report != null && report.hasComplaint)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: const Text(
                                      'Ada Catatan Selisih',
                                      style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              order.suratJalanNumber,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Resi: ${order.resiNumber} • ${order.destinationWarehouse}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const Divider(height: 24),

                            if (report != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Diterima oleh:', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                        Text(report.recipientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('Kontak: ${report.recipientPhone}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                        if (report.complaintNote.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Catatan: "${report.complaintNote}"',
                                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.red.shade800),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Mini Signature Preview
                                  if (report.signaturePoints.isNotEmpty)
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CustomPaint(
                                            painter: SignaturePainter(points: report.signaturePoints),
                                            size: Size.infinite,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                            ],

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => DeliveryDetailScreen(deliveryId: order.id),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.description_outlined, size: 16),
                                  label: const Text('Rincian Lengkap & Foto Watermark'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
