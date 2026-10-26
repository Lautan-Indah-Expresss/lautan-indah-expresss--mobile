import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/session_manager.dart';
import '../services/api_service.dart';
import 'driver_login_screen.dart';
import 'driver_delivery_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _apiService = ApiService();
  String _driverName = 'Sopir';
  List<dynamic> _shipments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final name = await SessionManager.getDriverName();
    final data = await _apiService.getShipments();
    if (!mounted) return;
    setState(() {
      _driverName = name;
      _shipments = data;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tugas Saya Hari Ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Sopir: $_driverName',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Keluar dari Akun?'),
                  content: const Text('Anda perlu masuk kembali dengan kata sandi.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text('Ya, Keluar',
                          style: TextStyle(color: AppTheme.dangerRed)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _shipments.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 80),
                      Icon(Icons.assignment_turned_in_outlined,
                          size: 64, color: AppTheme.textMuted),
                      SizedBox(height: 16),
                      Text(
                        'Tidak Ada Tugas Pengiriman Aktif',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tarik layar ke bawah untuk memperbarui data tugas baru dari kantor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shipments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _shipments[index];
                      final status = item['status'] as String? ?? 'tertunda';
                      final isArrived = item['driver_arrived'] == true;

                      // Translate status to simple driver words
                      String statusText = 'Belum Berangkat';
                      Color statusBg = const Color(0xFFFEF3C7);
                      Color statusColor = const Color(0xFFB45309);

                      if (status == 'terkirim') {
                        statusText = 'Selesai Terkirim';
                        statusBg = const Color(0xFFD1FAE5);
                        statusColor = const Color(0xFF065F46);
                      } else if (status == 'kendala') {
                        statusText = 'Ada Kendala di Jalan';
                        statusBg = const Color(0xFFFEE2E2);
                        statusColor = const Color(0xFF991B1B);
                      } else if (isArrived) {
                        statusText = 'Sampai di Tujuan (Menunggu Penerima)';
                        statusBg = const Color(0xFFE0E7FF);
                        statusColor = const Color(0xFF3730A3);
                      } else if (status == 'dalam_pengiriman') {
                        statusText = 'Dalam Perjalanan';
                        statusBg = const Color(0xFFDBEAFE);
                        statusColor = const Color(0xFF1E40AF);
                      }

                      return InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DriverDeliveryScreen(shipment: item),
                            ),
                          );
                          _loadData();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['resi'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 18, color: AppTheme.textMuted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${item['origin_city']} ➔ ${item['destination_city']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.business_outlined,
                                      size: 18, color: AppTheme.textMuted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Tujuan: ${item['receiver_company'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined,
                                      size: 18, color: AppTheme.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${item['nopol'] ?? '-'} • ${item['total_colli'] ?? 1} Koli (${item['actual_weight_kg'] ?? 0} kg)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
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
      ),
    );
  }
}
