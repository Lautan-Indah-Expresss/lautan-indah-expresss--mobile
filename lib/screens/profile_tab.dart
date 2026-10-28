import 'package:flutter/material.dart';
import '../services/mock_data_service.dart';
import 'login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final MockDataService _service = MockDataService();

  // Checklist SOP Pra-Perjalanan Armada (Poin 74 di Dokumen)
  bool _boxCleanChecked = true;
  bool _tiresChecked = true;
  bool _sealChecked = true;
  bool _coolantChecked = true;

  void _showPreTripDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Checklist Awal Armada (SOP Gudang Muat)', style: TextStyle(fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sesuai ketentuan SOP logistik, sebelum berangkat armada wajib diperiksa kelayakan fisiknya:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Kebersihan & Keringnya Lantai Box', style: TextStyle(fontSize: 13)),
                  value: _boxCleanChecked,
                  onChanged: (v) {
                    setDialogState(() => _boxCleanChecked = v ?? false);
                    setState(() {});
                  },
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Pemeriksaan Tekanan Ban & Baut Roda', style: TextStyle(fontSize: 13)),
                  value: _tiresChecked,
                  onChanged: (v) {
                    setDialogState(() => _tiresChecked = v ?? false);
                    setState(() {});
                  },
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Segel Box Terpasang Rapat (No. SG-8819)', style: TextStyle(fontSize: 13)),
                  value: _sealChecked,
                  onChanged: (v) {
                    setDialogState(() => _sealChecked = v ?? false);
                    setState(() {});
                  },
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Air Radiator, Aki & Rem Berfungsi Normal', style: TextStyle(fontSize: 13)),
                  value: _coolantChecked,
                  onChanged: (v) {
                    setDialogState(() => _coolantChecked = v ?? false);
                    setState(() {});
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pemeriksaan checklist awal berhasil dikonfirmasi.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan Checklist'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final driver = _service.driver;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Profil Driver & Sistem', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Driver Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFF0F172A),
                      child: Text(
                        driver.name[0],
                        style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      driver.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${driver.id} • ${driver.phone}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      driver.companyName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bagian Sesi JWT 45 Hari (Terkunci Sesuai Dokumen Arsitektur)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, size: 20, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text(
                          'Autentikasi & Sesi Driver (JWT 45 Hari)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Disimpan terenkripsi di "flutter_secure_storage". Token di-renew otomatis secara siluman di latar belakang saat mendekati kedaluwarsa.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Masa Aktif Token Saat Ini', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              'Sisa ${driver.sessionDaysRemaining} Hari',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _service.renewJwtSession();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Simulasi sukses: Token JWT diperbarui menjadi 45 hari penuh.'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          },
                          icon: const Icon(Icons.autorenew, size: 16),
                          label: const Text('Simulasi Auto-Renew', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Checklist & Kelayakan Armada
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.fact_check_outlined, color: Color(0xFF0F172A)),
                      title: const Text('Checklist Awal Armada (SOP Muat)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Kebersihan box, segel, dan ban sebelum berangkat', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showPreTripDialog,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.local_shipping_outlined, color: Color(0xFF0F172A)),
                      title: const Text('Armada Ditugaskan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text('${driver.licensePlate} • ${driver.truckType}', style: const TextStyle(fontSize: 12)),
                      trailing: const Text('Terverifikasi', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Logout / Reset Demo
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Keluar Akun (Logout)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Sistem Logistik & Tracking Armada v1.0.0 (Temporary UI Prototype)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
