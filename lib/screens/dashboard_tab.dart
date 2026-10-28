import 'package:flutter/material.dart';
import '../models/delivery_model.dart';
import '../services/mock_data_service.dart';
import 'delivery_detail_screen.dart';

class DashboardTab extends StatelessWidget {
  final Function(int) onNavigateTab;

  const DashboardTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final service = MockDataService();

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final driver = service.driver;
        final activeDelivery = service.activeDelivery;
        final totalDeliveries = service.deliveries.length;
        final completedDeliveries = service.deliveries.where((d) => d.status == DeliveryStatus.completed).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping, color: Color(0xFF38BDF8), size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SISTEM LOGISTIK & ARMADA',
                      style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      driver.companyName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tidak ada notifikasi darurat dari Admin Dispatch.')),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Driver Attendance & Profile Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF38BDF8),
                            child: Text(
                              driver.name.isNotEmpty ? driver.name[0] : 'D',
                              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${driver.id} • ${driver.phone}',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: driver.isClockedIn ? const Color(0xFF10B981) : Colors.grey.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              driver.isClockedIn ? 'SHIFT AKTIF' : 'OFF SHIFT',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.airport_shuttle, color: Color(0xFFF59E0B), size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driver.licensePlate,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                  Text(
                                    driver.truckType,
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                service.toggleClockIn();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(driver.isClockedIn
                                        ? 'Absensi Masuk Berhasil! Status shift aktif.'
                                        : 'Absensi Pulang Selesai. Selamat beristirahat.'),
                                    backgroundColor: driver.isClockedIn ? const Color(0xFF10B981) : Colors.orange,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: driver.isClockedIn ? Colors.red.shade700 : const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: Text(driver.isClockedIn ? 'Absen Keluar' : 'Absen Masuk'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // JWT Session Info Bar (Requirement 45 Hari)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sesi Token JWT: Sisa ${driver.sessionDaysRemaining} hari (Auto-renew aktif di background)',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          service.renewJwtSession();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Token JWT berhasil di-renew siluman (45 hari baru)!')),
                          );
                        },
                        child: const Text('Renew', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Penugasan Surat Jalan Aktif
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Surat Jalan Berjalan Saat Ini',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    TextButton(
                      onPressed: () => onNavigateTab(1), // Pindah ke tab Penugasan
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),

                if (activeDelivery != null) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.blue.shade100, width: 1.5),
                    ),
                    color: Colors.white,
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
                                  color: activeDelivery.statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  activeDelivery.statusLabel.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: activeDelivery.statusColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                activeDelivery.resiNumber,
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.blueGrey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            activeDelivery.suratJalanNumber,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tipe: ${activeDelivery.routeType} • ${activeDelivery.totalExpectedKoli} Koli Muatan',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.trip_origin, size: 16, color: Color(0xFF3B82F6)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activeDelivery.originWarehouse,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Color(0xFFEF4444)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activeDelivery.destinationWarehouse,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => DeliveryDetailScreen(deliveryId: activeDelivery.id),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.alt_route),
                                  label: const Text('Buka Alur Rute & Checkpoint'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F172A),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade400),
                          const SizedBox(height: 8),
                          const Text('Semua penugasan pengiriman telah diselesaikan!', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Quick Operational Stats
                const Text(
                  'Performa & Operasional Pengiriman',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Total Tugas',
                        value: '$totalDeliveries SJ',
                        icon: Icons.assignment_outlined,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Tuntas (BAST)',
                        value: '$completedDeliveries Selesai',
                        icon: Icons.task_alt,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Ketepatan Waktu',
                        value: '98.5%',
                        icon: Icons.timer_outlined,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Model Tracking',
                        value: 'Event-Based',
                        icon: Icons.map_outlined,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
