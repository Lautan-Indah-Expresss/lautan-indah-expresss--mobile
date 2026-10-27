import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/session_manager.dart';
import '../services/api_service.dart';
import '../widgets/shipment_card.dart';
import 'driver_delivery_screen.dart';
import 'driver_profile_tab.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;
  final _apiService = ApiService();
  String _driverName = 'Sopir';
  List<dynamic> _shipments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = await SessionManager.getDriverName();
    final data = await _apiService.getShipments();

    if (!mounted) return;
    setState(() {
      _driverName = name;
      _shipments = data;
      _isLoading = false;
    });
  }

  // Filter pengiriman: Aktif (belum selesai) vs Riwayat (selesai)
  List<dynamic> get _activeShipments =>
      _shipments.where((s) => s['status'] != 'terkirim').toList();

  List<dynamic> get _historyShipments =>
      _shipments.where((s) => s['status'] == 'terkirim').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryBlue,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentIndex == 0
                  ? 'Tugas Pengiriman Aktif'
                  : _currentIndex == 1
                      ? 'Riwayat Pengiriman'
                      : 'Profil Pengemudi',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.account_circle, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  _driverName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_currentIndex != 2)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Perbarui Data',
              onPressed: _loadData,
            ),
        ],
      ),

      // Body disesuaikan dengan BottomNavigationBar
      body: _currentIndex == 2
          ? const DriverProfileTab()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryBlue,
              child: _buildShipmentList(
                _currentIndex == 0 ? _activeShipments : _historyShipments,
                isHistoryTab: _currentIndex == 1,
              ),
            ),

      // Bottom Navigation Bar Premium
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping,
                  label: 'Tugas Aktif',
                  badgeCount: _activeShipments.length,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.history_toggle_off_rounded,
                  activeIcon: Icons.history_rounded,
                  label: 'Riwayat',
                  badgeCount: _historyShipments.length,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil Saya',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int? badgeCount,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
                  size: 22,
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentList(List<dynamic> items, {required bool isHistoryTab}) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            SizedBox(height: 16),
            Text(
              'Memuat data surat jalan...',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            ),
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            isHistoryTab
                ? Icons.receipt_long_outlined
                : Icons.assignment_turned_in_outlined,
            size: 68,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            isHistoryTab
                ? 'Belum Ada Riwayat Pengiriman'
                : 'Belum Ada Tugas Pengiriman Aktif',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppTheme.darkNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHistoryTab
                ? 'Semua pengiriman yang sudah selesai terkirim akan muncul di riwayat ini.'
                : 'Saat ini semua penugasan armada sudah selesai atau belum ada penugasan baru.\nTarik layar ke bawah untuk cek tugas baru.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.45,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        return ShipmentCard(
          shipment: item,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DriverDeliveryScreen(shipment: item),
              ),
            );
            _loadData();
          },
        );
      },
    );
  }
}
