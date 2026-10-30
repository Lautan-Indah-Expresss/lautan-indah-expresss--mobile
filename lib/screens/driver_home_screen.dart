import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/session_manager.dart';
import '../services/api_service.dart';
import '../widgets/shipment_card.dart';
import 'driver_delivery_screen.dart';
import 'driver_multi_drop_screen.dart';
import 'driver_profile_tab.dart';

enum _TabMode {
  inTransit,
  queued,
  history,
}

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

  // 1. Sedang Berjalan (in-transit, kendala, atau tiba belum selesai terkirim)
  List<dynamic> get _inTransitShipments => _shipments.where((s) {
        final st = s['status'] as String? ?? 'tertunda';
        // Resi yang sudah terkirim / selesai TIDAK BOLEH masuk ke tab sedang jalan!
        if (st == 'terkirim') return false;
        return st == 'dalam_pengiriman' || st == 'kendala' || s['driver_arrived'] == true;
      }).toList();

  // 2. Antrean Tugas (tertunda belum berangkat dan belum terkirim)
  List<dynamic> get _queuedShipments => _shipments.where((s) {
        final st = s['status'] as String? ?? 'tertunda';
        if (st == 'terkirim') return false;
        return st == 'tertunda' && s['driver_arrived'] != true;
      }).toList();

  // 3. Riwayat Selesai
  List<dynamic> get _historyShipments =>
      _shipments.where((s) => s['status'] == 'terkirim').toList();

  // Helper cek apakah supir sedang aktif menyetir di jalan
  bool get _isDriverCurrentlyDriving => _shipments.any(
        (s) => s['status'] == 'dalam_pengiriman' || s['status'] == 'kendala',
      );

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
                  ? 'Sedang Dikerjakan (Aktif)'
                  : _currentIndex == 1
                      ? 'Antrean Tugas Pengiriman'
                      : _currentIndex == 2
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
          if (_currentIndex != 3)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Perbarui Data',
              onPressed: _loadData,
            ),
        ],
      ),

      // Body sesuai 4 tab (0: Sedang Jalan, 1: Antrean, 2: Riwayat, 3: Profil)
      body: _currentIndex == 3
          ? const DriverProfileTab()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryBlue,
              child: _buildShipmentList(
                _currentIndex == 0
                    ? _inTransitShipments
                    : _currentIndex == 1
                        ? _queuedShipments
                        : _historyShipments,
                tabMode: _currentIndex == 0
                    ? _TabMode.inTransit
                    : _currentIndex == 1
                        ? _TabMode.queued
                        : _TabMode.history,
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.directions_run_outlined,
                  activeIcon: Icons.directions_run,
                  label: 'Sedang Jalan',
                  badgeCount: _inTransitShipments.length,
                  badgeColor: _isDriverCurrentlyDriving ? AppTheme.successGreen : null,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment,
                  label: 'Antrean',
                  badgeCount: _queuedShipments.length,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.history_toggle_off_rounded,
                  activeIcon: Icons.history_rounded,
                  label: 'Riwayat',
                  badgeCount: _historyShipments.length,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
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
    Color? badgeColor,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.18 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
                    size: 20,
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor ?? (isSelected ? AppTheme.primaryBlue : AppTheme.textMuted),
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
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              child: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 7),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryBlue,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentList(List<dynamic> rawItems, {required _TabMode tabMode}) {
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

    final isHistoryTab = tabMode == _TabMode.history;
    final isInTransitTab = tabMode == _TabMode.inTransit;

    if (rawItems.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 70),
          Icon(
            isHistoryTab
                ? Icons.receipt_long_outlined
                : (isInTransitTab
                    ? Icons.directions_boat_outlined
                    : Icons.inbox_outlined),
            size: 68,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            isHistoryTab
                ? 'Belum Ada Riwayat Pengiriman'
                : (isInTransitTab
                    ? 'Tidak Ada Perjalanan Aktif'
                    : 'Tidak Ada Antrean Tugas'),
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
                : (isInTransitTab
                    ? 'Saat ini truk sedang tidak dalam perjalanan.\nBuka tab "Antrean" untuk memilih tugas dan mulai jalan.'
                    : 'Semua tugas pengiriman saat ini sudah dimulai atau belum ada tugas baru dari admin.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.45,
            ),
          ),
          if (isInTransitTab && _queuedShipments.isNotEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _currentIndex = 1),
                icon: const Icon(Icons.assignment_outlined, size: 18),
                label: Text('Lihat ${_queuedShipments.length} Antrean Tugas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Buat copy items dan urutkan secara cerdas:
    // 1. Resi kendala / aktif paling atas
    // 2. Jika sama-sama aktif, urutkan berdasarkan drop_sequence (Drop 1, 2, 3)
    final List<Map<String, dynamic>> items = rawItems
        .map((it) => Map<String, dynamic>.from(it as Map<String, dynamic>))
        .toList();

    items.sort((a, b) {
      final stA = a['status'] as String? ?? 'tertunda';
      final stB = b['status'] as String? ?? 'tertunda';

      int rank(String st, Map<String, dynamic> s) {
        if (s['has_active_issue'] == true || st == 'kendala') return 0; // Paling genting
        if (st == 'dalam_pengiriman') return 1; // Sedang jalan
        if (s['driver_arrived'] == true) return 2; // Sudah tiba
        if (st == 'tertunda') return 3; // Menunggu
        return 4; // Terkirim
      }

      final rankA = rank(stA, a);
      final rankB = rank(stB, b);
      if (rankA != rankB) return rankA.compareTo(rankB);

      // Jika sama-sama trip rombongan, urutkan drop_sequence 1, 2, 3
      final dropA = a['drop_sequence'] as int? ?? 1;
      final dropB = b['drop_sequence'] as int? ?? 1;
      if (dropA != dropB) return dropA.compareTo(dropB);

      return (a['resi'] as String? ?? '').compareTo(b['resi'] as String? ?? '');
    });

    // Kelompokkan muatan aktif berdasarkan trip_code resmi dari Admin
    final Map<String, List<Map<String, dynamic>>> activeTripGroups = {};
    for (final it in items) {
      final status = it['status'] as String? ?? 'tertunda';
      final isArrived = it['driver_arrived'] == true;
      final tripCode = (it['trip_code'] as String? ?? '').trim();
      if (tripCode.isNotEmpty && status != 'terkirim' && !isArrived) {
        activeTripGroups.putIfAbsent(tripCode, () => []).add(it);
      }
    }

    // Ambil SEMUA grup multi-drop aktif
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
        final isTripDeparted = !allPending;

        multiDropTripList.add({
          'tripCode': tripCode,
          'items': tripItems,
          'nopol': nopol,
          'vehicle': vehicle,
          'allPending': allPending,
          'hasAnyActiveIssue': hasAnyActiveIssue,
          'isTripDeparted': isTripDeparted,
        });
      }
    }

    // Urutkan multiDropTripList: Trip yang sedang jalan / kendala di atas sendiri
    multiDropTripList.sort((a, b) {
      final aActive = (a['isTripDeparted'] == true || a['hasAnyActiveIssue'] == true) ? 0 : 1;
      final bActive = (b['isTripDeparted'] == true || b['hasAnyActiveIssue'] == true) ? 0 : 1;
      return aActive.compareTo(bActive);
    });

    // Cek apakah driver saat ini sedang dalam perjalanan (driving) di salah satu pengiriman/trip
    final bool isDriverCurrentlyDriving = _shipments.any(
      (s) => s['status'] == 'dalam_pengiriman' || s['status'] == 'kendala',
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ==========================================
        // MULTI-DROP HUB CONTROL BANNERS (Mendukung Multi-Trip Cards)
        // Yang sedang jalan / kendala otomatis di urutan teratas
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

        // Subheader Daftar Surat Jalan
        if (!isHistoryTab && items.isNotEmpty) ...[
          Row(
            children: [
              Text(
                isInTransitTab ? 'Daftar Resi dalam Perjalanan:' : 'Daftar Surat Jalan:',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} Resi',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // Daftar Surat Jalan Individual di bawah (Terurut Cerdas)
        ...items.map((item) {
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
