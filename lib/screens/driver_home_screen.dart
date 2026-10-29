import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/session_manager.dart';
import '../services/api_service.dart';
import '../widgets/shipment_card.dart';
import 'driver_delivery_screen.dart';
import 'driver_multi_drop_screen.dart';
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

  // GPS State

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

    // Kelompokkan muatan aktif HANYA berdasarkan trip_code resmi dari Admin
    // HANYA muatan yang MASIH DI JALAN (belum 'terkirim' DAN belum 'driver_arrived')
    final Map<String, List<Map<String, dynamic>>> activeTripGroups = {};
    for (final it in items) {
      final status = it['status'] as String? ?? 'tertunda';
      final isArrived = it['driver_arrived'] == true;
      final tripCode = (it['trip_code'] as String? ?? '').trim();
      if (tripCode.isNotEmpty && status != 'terkirim' && !isArrived) {
        activeTripGroups.putIfAbsent(tripCode, () => []).add(it as Map<String, dynamic>);
      }
    }

    // Ambil SEMUA grup multi-drop aktif (bisa lebih dari 1 trip card jika admin buat beberapa rombongan)
    final List<Map<String, dynamic>> multiDropTripList = [];
    for (final entry in activeTripGroups.entries) {
      if (entry.value.length > 1) {
        final tripItems = List<Map<String, dynamic>>.from(entry.value);
        tripItems.sort((a, b) => ((a['drop_sequence'] as int? ?? 1).compareTo(b['drop_sequence'] as int? ?? 1)));

        final tripCode = entry.key;
        final nopol = (tripItems.first['nopol'] as String? ?? '-').trim();
        final vehicle = (tripItems.first['vehicle_name'] as String? ?? '').trim();
        final allPending = tripItems.every((it) => it['status'] == 'tertunda');
        final hasAnyActiveIssue = tripItems.any((it) => it['has_active_issue'] == true || it['status'] == 'kendala');

        multiDropTripList.add({
          'tripCode': tripCode,
          'items': tripItems,
          'nopol': nopol,
          'vehicle': vehicle,
          'allPending': allPending,
          'hasAnyActiveIssue': hasAnyActiveIssue,
        });
      }
    }

    // Cek apakah driver saat ini sedang dalam perjalanan (driving) di salah satu pengiriman/trip
    final bool isDriverCurrentlyDriving = items.any(
      (s) => s['status'] == 'dalam_pengiriman' || s['status'] == 'kendala',
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ==========================================
        // MULTI-DROP HUB CONTROL BANNERS (Mendukung Multi-Trip Cards)
        // ==========================================
        if (!isHistoryTab && multiDropTripList.isNotEmpty) ...[
          for (final tripData in multiDropTripList) ...[
            _buildMultiDropTripCard(
              tripData: tripData,
              isDriverCurrentlyDriving: isDriverCurrentlyDriving,
            ),
            const SizedBox(height: 16),
          ],
        ],

        // Daftar Surat Jalan Individual di bawah
        ...items.map((itemRaw) {
          final item = itemRaw as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShipmentCard(
              shipment: item,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverDeliveryScreen(
                      shipment: item,
                      isDriverCurrentlyDriving: isDriverCurrentlyDriving,
                    ),
                  ),
                );
                _loadData();
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMultiDropTripCard({
    required Map<String, dynamic> tripData,
    required bool isDriverCurrentlyDriving,
  }) {
    final String tripCode = tripData['tripCode'];
    final List<Map<String, dynamic>> tripItems = tripData['items'];
    final String nopol = tripData['nopol'];
    final String vehicle = tripData['vehicle'];
    final bool allPending = tripData['allPending'];
    final bool hasAnyActiveIssue = tripData['hasAnyActiveIssue'];

    // Jika trip ini belum berangkat (allPending), tapi supir SUDAH dalam perjalanan di trip/resi lain,
    // maka trip ini berstatus menunggu antrean (terkunci)
    final bool isBlockedByOtherActiveTrip = allPending && isDriverCurrentlyDriving;

    final String titleArmada = vehicle.isNotEmpty ? '$vehicle • $nopol' : 'Truk $nopol';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasAnyActiveIssue ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAnyActiveIssue
              ? const Color(0xFFFCA5A5)
              : (isBlockedByOtherActiveTrip ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Rombongan: Icon, Judul & Badge Sisa Resi
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasAnyActiveIssue
                      ? const Color(0xFFFEE2E2)
                      : (isBlockedByOtherActiveTrip ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasAnyActiveIssue
                      ? Icons.warning_amber_rounded
                      : (isBlockedByOtherActiveTrip ? Icons.lock_outline : Icons.alt_route),
                  color: hasAnyActiveIssue
                      ? AppTheme.dangerRed
                      : (isBlockedByOtherActiveTrip ? AppTheme.textMuted : Colors.white),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAnyActiveIssue
                          ? 'KENDALA ARMADA'
                          : (isBlockedByOtherActiveTrip
                              ? 'TRIP MENUNGGU (ANTREAN)'
                              : (allPending ? 'TRIP MULTI-DROP' : 'TRIP BERJALAN')),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: hasAnyActiveIssue
                            ? AppTheme.dangerRed
                            : (isBlockedByOtherActiveTrip ? AppTheme.textMuted : AppTheme.primaryBlue),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '$titleArmada • $tripCode',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hasAnyActiveIssue
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasAnyActiveIssue
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  '${tripItems.length} Resi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: hasAnyActiveIssue
                        ? AppTheme.dangerRed
                        : AppTheme.darkNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Teks Penjelasan Singkat & Padat
          Text(
            isBlockedByOtherActiveTrip
                ? 'Selesaikan trip aktif Anda terlebih dahulu sebelum memulai jalan trip ini.'
                : (allPending
                    ? 'Ada ${tripItems.length} pengiriman searah. Absen mulai jalan cukup 1x untuk rombongan ini.'
                    : 'Lapor posisi dan kendala jalan otomatis tercatat ke ${tripItems.length} resi rombongan.'),
            style: TextStyle(
              fontSize: 12,
              color: isBlockedByOtherActiveTrip ? const Color(0xFFB45309) : const Color(0xFF475569),
              fontWeight: isBlockedByOtherActiveTrip ? FontWeight.w700 : FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          // Daftar Pil Resi Terang & Kontras
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tripItems.map((s) {
                final r = s['resi'] ?? '-';
                final d = s['destination_city'] ?? '';
                final isCurIssue = s['has_active_issue'] == true || s['status'] == 'kendala';
                final dropSeq = s['drop_sequence'] as int? ?? 1;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurIssue ? const Color(0xFFFEE2E2) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurIssue ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    '#$dropSeq $r ($d)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isCurIssue ? AppTheme.dangerRed : AppTheme.darkNavy,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // ==========================================
          // TOMBOL AKSI HUB MULTI-DROP
          // ==========================================
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverMultiDropScreen(
                    tripCode: tripCode,
                    shipments: tripItems,
                    isBlockedByOtherTrip: isBlockedByOtherActiveTrip,
                  ),
                ),
              ).then((_) => _loadData());
            },
            icon: Icon(
              isBlockedByOtherActiveTrip ? Icons.visibility : Icons.alt_route,
              size: 18,
            ),
            label: Text(
              isBlockedByOtherActiveTrip
                  ? 'LIHAT RINCIAN TRIP (TERKUNCI)'
                  : (allPending
                      ? 'MULAI JALAN TRIP MULTI-DROP'
                      : 'KONTROL PERJALANAN MULTI-DROP'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlockedByOtherActiveTrip
                  ? const Color(0xFF64748B)
                  : const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
