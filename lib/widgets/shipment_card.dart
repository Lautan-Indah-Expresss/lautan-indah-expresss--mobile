import 'package:flutter/material.dart';
import '../core/theme.dart';

class ShipmentCard extends StatelessWidget {
  final Map<String, dynamic> shipment;
  final VoidCallback onTap;

  const ShipmentCard({
    super.key,
    required this.shipment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = shipment['status'] as String? ?? 'tertunda';
    final isArrived = shipment['driver_arrived'] == true;
    final hasActiveIssue = shipment['has_active_issue'] == true;

    // Menentukan label & warna badge status dengan bahasa supir yang jelas
    String statusText = 'Belum Berangkat';
    Color statusBg = const Color(0xFFFEF3C7);
    Color statusColor = const Color(0xFFB45309);
    IconData statusIcon = Icons.pending_actions;

    if (status == 'terkirim') {
      statusText = 'Selesai Terkirim';
      statusBg = const Color(0xFFD1FAE5);
      statusColor = const Color(0xFF065F46);
      statusIcon = Icons.check_circle;
    } else if (status == 'kendala' || hasActiveIssue) {
      statusText = 'Ada Kendala di Jalan';
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFF991B1B);
      statusIcon = Icons.warning_amber_rounded;
    } else if (isArrived) {
      statusText = 'Sampai di Tujuan (Menunggu Diterima)';
      statusBg = const Color(0xFFEDE9FE);
      statusColor = const Color(0xFF5B21B6);
      statusIcon = Icons.warehouse;
    } else if (status == 'dalam_pengiriman') {
      statusText = 'Dalam Perjalanan';
      statusBg = const Color(0xFFDBEAFE);
      statusColor = const Color(0xFF1E40AF);
      statusIcon = Icons.local_shipping;
    }

    final resi = shipment['resi'] ?? '-';
    final originCity = shipment['origin_city'] ?? 'Asal';
    final destCity = shipment['destination_city'] ?? 'Tujuan';
    final receiver = shipment['receiver_company'] ?? '-';
    final nopol = shipment['nopol'] ?? '-';
    final colli = shipment['total_colli'] ?? 1;
    final weight = shipment['actual_weight_kg'] ?? 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasActiveIssue
                ? const Color(0xFFFCA5A5)
                : const Color(0xFFE2E8F0),
            width: hasActiveIssue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Kartu: Nomor Resi & Badge Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOMOR RESI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        resi,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 5),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Isi Kartu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rute Perjalanan
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.route,
                            size: 18, color: AppTheme.primaryBlue),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$originCity ➔ $destCity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Penerima / Lokasi Bongkar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.business_outlined,
                          size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Penerima / Lokasi Bongkar:',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            Text(
                              receiver,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info Truk & Muatan Kargo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined,
                                size: 16, color: AppTheme.primaryBlue),
                            const SizedBox(width: 6),
                            Text(
                              nopol,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkNavy,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$colli Koli • $weight Kg',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notifikasi Kendala jika ada
                  if (hasActiveIssue && shipment['current_issue_note'] != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.report_problem,
                              size: 14, color: AppTheme.dangerRed),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Kendala: ${shipment['current_issue_note']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF991B1B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Petunjuk Aksi Driver
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        status == 'terkirim'
                            ? 'Lihat Bukti Pengiriman'
                            : 'Buka Lembar Kontrol & Lapor',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios,
                          size: 12, color: AppTheme.primaryBlue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
