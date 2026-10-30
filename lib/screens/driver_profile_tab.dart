import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/session_manager.dart';
import 'driver_login_screen.dart';

class DriverProfileTab extends StatefulWidget {
  const DriverProfileTab({super.key});

  @override
  State<DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends State<DriverProfileTab> {
  String _driverName = 'Memuat...';
  String _driverUsername = '-';
  String _driverPhone = '-';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await SessionManager.getDriverName();
    final username = await SessionManager.getDriverUsername();
    final phone = await SessionManager.getDriverPhone();

    if (mounted) {
      setState(() {
        _driverName = name;
        _driverUsername = username;
        _driverPhone = phone.isNotEmpty ? phone : '-';
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar drag
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Animated / friendly icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFEE2E2), width: 3),
              ),
              child: const Center(
                child: Icon(
                  Icons.power_settings_new_rounded,
                  color: AppTheme.dangerRed,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Istirahat Dulu, Driver?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.darkNavy,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Pastikan semua tugas pengiriman hari ini sudah selesai ya!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Aksi Sejajar: Batal (Besar & Jelas) vs Keluar Akun
            Row(
              children: [
                // Tombol Batal Besar & Nyaman Diklik
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFF8FAFC),
                    ),
                    child: const Text(
                      'Lanjut Kerja',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkNavy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol Ya Keluar
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Ya, Keluar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await SessionManager.clearSession();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        // 1. Hero Card Profil Pengemudi
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _driverName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ID Sopir: $_driverUsername',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Color(0xFF86EFAC)),
                          SizedBox(width: 4),
                          Text(
                            'Sopir Aktif Bertugas',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF86EFAC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 2. Section: Data Sopir (Mudah Dipahami & Ramah Pengguna)
        const Text(
          'Data Akun',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkNavy,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSimpleTile(
                icon: Icons.badge_outlined,
                title: 'Nama Lengkap',
                value: _driverName,
              ),
              const Divider(height: 1, indent: 52),
              _buildSimpleTile(
                icon: Icons.phone_android_outlined,
                title: 'Nomor Handphone',
                value: _driverPhone,
              ),
              const Divider(height: 1, indent: 52),
              _buildSimpleTile(
                icon: Icons.local_shipping_outlined,
                title: 'Layanan Pengiriman',
                value: 'LIE Cargo (PT Lautan Indah Express)',
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Section: Status Aplikasi & Bantuan
        const Text(
          'Aplikasi & Bantuan',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkNavy,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSimpleTile(
                icon: Icons.verified_user_outlined,
                title: 'Status Akun',
                value: 'Terhubung & Siap Jalan',
                valueColor: const Color(0xFF15803D),
              ),
              const Divider(height: 1, indent: 52),
              _buildSimpleTile(
                icon: Icons.info_outline,
                title: 'Versi Aplikasi',
                value: 'Versi 1.1.0',
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // 4. Tombol Keluar dari Aplikasi
        ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout, size: 20),
          label: const Text('KELUAR DARI APLIKASI'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFEF2F2),
            foregroundColor: AppTheme.dangerRed,
            elevation: 0,
            side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),

        const SizedBox(height: 24),

        // Footer Hak Cipta Sederhana
        const Center(
          child: Text(
            'PT Lautan Indah Express\nAplikasi Tugas & Absensi Pengemudi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
