import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import '../core/session_manager.dart';
import '../services/api_service.dart';
import '../widgets/action_location_dialog.dart';
import '../widgets/confirmation_dialog.dart';
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
  final _picker = ImagePicker();
  String _driverName = 'Sopir';
  List<dynamic> _shipments = [];
  bool _isLoading = true;
  bool _isActionSubmitting = false;
  String _actionSubmittingStatus = 'Memproses laporan armada...';
  String? _errorMessage;

  // GPS State
  Position? _currentPosition;
  double? _currentAccuracy;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshGps();
  }

  Future<void> _refreshGps() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _currentAccuracy = pos.accuracy;
        });
      }
    } catch (_) {
      if (mounted && _currentPosition == null) {
        setState(() {
          _currentPosition = Position(
            latitude: -6.200000,
            longitude: 106.816666,
            timestamp: DateTime.now(),
            accuracy: 30,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          _currentAccuracy = 30;
        });
      }
    }
  }

  Future<XFile?> _pickStrictCameraPhoto() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1280,
        imageQuality: 75,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamera tidak dapat diakses. Berikan izin kamera di pengaturan HP.'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
      return null;
    }
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

  // Multi-Drop Handlers
  Future<void> _handleMultiDropTransit(Map<String, dynamic> sampleShipment, List<Map<String, dynamic>> items) async {
    if (_isActionSubmitting) return;
    await _refreshGps();
    if (!mounted) return;

    final driverLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2, 106.816);

    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActionLocationDialog(
        title: 'Lapor Posisi Multi-Drop',
        subtitle: 'Laporan posisi berlaku untuk seluruh ${items.length} resi rombongan',
        inputLabel: 'Tuliskan Lokasi & Posisi Armada Saat Ini:',
        inputHint: 'Contoh: Istirahat di Rest Area Tol KM 102, cek kondisi ban & mesin...',
        actionButtonText: 'KIRIM LAPORAN POSISI MULTI-DROP',
        actionColor: const Color(0xFF0F172A),
        actionIcon: Icons.add_location_alt,
        driverPosition: driverLatLng,
        accuracy: _currentAccuracy,
        originCity: sampleShipment['origin_city'] ?? 'Asal',
        destinationCity: 'Multi-Drop Tujuan',
        onPickCameraPhoto: _pickStrictCameraPhoto,
      ),
    );

    if (res == null || !mounted) return;
    final note = res['note'] as String;
    final photo = res['photo'] as XFile?;

    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Kirim Laporan Posisi Multi-Drop?',
      message: 'Laporan posisi dan foto akan dicatat sekaligus untuk semua ${items.length} resi rombongan armada ini.',
      confirmText: 'Ya, Kirim Posisi',
      confirmColor: const Color(0xFF0F172A),
      icon: Icons.add_location_alt,
    );
    if (!confirm || !mounted) return;

    setState(() {
      _isActionSubmitting = true;
      _actionSubmittingStatus = 'Menyinkronkan laporan posisi ke semua muatan...';
    });

    String? photoUrl;
    if (photo != null) {
      photoUrl = await _apiService.uploadPhoto(photo);
    }

    final success = await _apiService.sendCheckpoint(
      shipmentId: sampleShipment['id'],
      checkpointType: 'transit_update',
      statusLabel: 'Posisi Multi-Drop: ${note.length > 30 ? "${note.substring(0, 30)}..." : note}',
      description: note,
      photoUrl: photoUrl,
      latitude: _currentPosition?.latitude ?? -6.2,
      longitude: _currentPosition?.longitude ?? 106.816,
    );

    setState(() => _isActionSubmitting = false);
    if (!mounted) return;

    if (success) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laporan posisi tersimpan serentak untuk ${items.length} muatan!'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    }
  }

  Future<void> _handleMultiDropIncident(Map<String, dynamic> sampleShipment, List<Map<String, dynamic>> items) async {
    if (_isActionSubmitting) return;
    await _refreshGps();
    if (!mounted) return;

    final driverLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2, 106.816);

    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActionLocationDialog(
        title: 'Lapor Kendala Armada Multi-Drop',
        subtitle: 'Peringatan kendala armada otomatis menandai seluruh ${items.length} resi rombongan',
        inputLabel: 'Jelaskan Kerusakan / Kendala Armada:',
        inputHint: 'Contoh: Ban belakang pecah di KM 80, sedang menunggu montir bengkel...',
        actionButtonText: 'KIRIM PERINGATAN KENDALA KE KANTOR',
        actionColor: AppTheme.dangerRed,
        actionIcon: Icons.warning_amber_rounded,
        driverPosition: driverLatLng,
        accuracy: _currentAccuracy,
        originCity: sampleShipment['origin_city'] ?? 'Asal',
        destinationCity: 'Multi-Drop Tujuan',
        onPickCameraPhoto: _pickStrictCameraPhoto,
      ),
    );

    if (res == null || !mounted) return;
    final note = res['note'] as String;
    final photo = res['photo'] as XFile?;

    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Kirim Peringatan Kendala?',
      message: 'Status kendala akan diterapkan serentak ke semua ${items.length} muatan armada ini di dashboard kantor.',
      confirmText: 'Ya, Kirim Kendala',
      confirmColor: AppTheme.dangerRed,
      icon: Icons.warning_amber_rounded,
    );
    if (!confirm || !mounted) return;

    setState(() {
      _isActionSubmitting = true;
      _actionSubmittingStatus = 'Mengirim status kendala ke semua resi rombongan...';
    });

    String? photoUrl;
    if (photo != null) {
      photoUrl = await _apiService.uploadPhoto(photo);
    }

    final success = await _apiService.sendCheckpoint(
      shipmentId: sampleShipment['id'],
      checkpointType: 'incident',
      statusLabel: 'Kendala Armada: ${note.length > 30 ? "${note.substring(0, 30)}..." : note}',
      description: note,
      photoUrl: photoUrl,
      latitude: _currentPosition?.latitude ?? -6.2,
      longitude: _currentPosition?.longitude ?? 106.816,
    );

    setState(() => _isActionSubmitting = false);
    if (!mounted) return;

    if (success) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kendala armada berhasil dicatat untuk seluruh ${items.length} resi!'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  Future<void> _handleMultiDropResolveIncident(Map<String, dynamic> sampleShipment, List<Map<String, dynamic>> items) async {
    if (_isActionSubmitting) return;

    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Selesaikan Kendala Armada?',
      message: 'Status kendala di semua ${items.length} resi rombongan akan dicabut dan armada kembali berstatus Dalam Perjalanan normal.',
      confirmText: 'Ya, Selesai & Lanjut Jalan',
      confirmColor: AppTheme.successGreen,
      icon: Icons.check_circle_outline,
    );
    if (!confirm || !mounted) return;

    setState(() {
      _isActionSubmitting = true;
      _actionSubmittingStatus = 'Mencabut status kendala dan melanjutkan trip multi-drop...';
    });
    await _refreshGps();

    final success = await _apiService.sendCheckpoint(
      shipmentId: sampleShipment['id'],
      checkpointType: 'incident_resolved',
      statusLabel: 'Kendala Selesai / Melanjutkan Jalan',
      description: 'Kendala armada telah selesai ditangani, sopir lanjut jalan ke drop point berikutnya.',
      latitude: _currentPosition?.latitude ?? -6.2,
      longitude: _currentPosition?.longitude ?? 106.816,
    );

    setState(() => _isActionSubmitting = false);
    if (!mounted) return;

    if (success) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status kendala armada dicabut! Selamat melanjutkan perjalanan.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

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
      body: Stack(
        children: [
          _currentIndex == 2
              ? const DriverProfileTab()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.primaryBlue,
                  child: _buildShipmentList(
                    _currentIndex == 0 ? _activeShipments : _historyShipments,
                    isHistoryTab: _currentIndex == 1,
                  ),
                ),

          // Global Action Submitting Loading Overlay
          if (_isActionSubmitting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.primaryBlue),
                        const SizedBox(height: 18),
                        Text(
                          _actionSubmittingStatus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // Bottom Navigation Bar
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

    // Kelompokkan muatan aktif berdasarkan nopol
    // HANYA muatan yang MASIH DI JALAN (belum 'terkirim' DAN belum 'driver_arrived' / belum sampai di tujuan)
    final Map<String, List<Map<String, dynamic>>> activeNopolGroups = {};
    for (final it in items) {
      final status = it['status'] as String? ?? 'tertunda';
      final isArrived = it['driver_arrived'] == true;
      if (status != 'terkirim' && !isArrived) {
        final nopol = (it['nopol'] as String? ?? '').trim();
        if (nopol.isNotEmpty) {
          activeNopolGroups.putIfAbsent(nopol, () => []).add(it as Map<String, dynamic>);
        }
      }
    }

    String? multiDropNopol;
    List<Map<String, dynamic>> multiDropItems = [];
    for (final entry in activeNopolGroups.entries) {
      if (entry.value.length > 1) {
        multiDropNopol = entry.key;
        multiDropItems = entry.value;
        break;
      }
    }

    // Cek status rombongan multi-drop
    final bool allPending = multiDropItems.isNotEmpty &&
        multiDropItems.every((it) => it['status'] == 'tertunda');
    final bool hasAnyActiveIssue = multiDropItems.any(
        (it) => it['has_active_issue'] == true || it['status'] == 'kendala');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ==========================================
        // MULTI-DROP HUB CONTROL BANNER
        // Hanya muncul jika sisa muatan aktif > 1
        // ==========================================
        if (!isHistoryTab && multiDropNopol != null && multiDropItems.length > 1) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasAnyActiveIssue
                    ? [const Color(0xFF7F1D1D), const Color(0xFF450A0A)]
                    : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasAnyActiveIssue ? const Color(0xFFEF4444) : const Color(0xFF334155),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (hasAnyActiveIssue ? Colors.red : const Color(0xFF3B82F6))
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        hasAnyActiveIssue ? Icons.warning_amber_rounded : Icons.alt_route,
                        color: hasAnyActiveIssue ? Colors.redAccent : const Color(0xFF60A5FA),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasAnyActiveIssue
                                ? 'MULTI-DROP: KENDALA ARMADA'
                                : allPending
                                    ? 'MULTI-DROP TERDETEKSI'
                                    : 'MULTI-DROP KONTROL AKTIF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: hasAnyActiveIssue
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFF93C5FD),
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Armada $multiDropNopol',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasAnyActiveIssue ? Colors.red : const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${multiDropItems.length} Sisa Muatan',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  allPending
                      ? 'Terdeteksi ada ${multiDropItems.length} muatan untuk Armada $multiDropNopol. Mulai jalan serentak untuk rombongan muatan ini:'
                      : 'Armada sedang membawa ${multiDropItems.length} muatan aktif. Lapor posisi dan kendala jalanan otomatis tercatat ke seluruh muatan rombongan:',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFCBD5E1),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),

                // Daftar Pil Resi
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daftar Resi dalam Armada:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: multiDropItems.map((s) {
                          final r = s['resi'] ?? '-';
                          final d = s['destination_city'] ?? '';
                          final isCurIssue = s['has_active_issue'] == true || s['status'] == 'kendala';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCurIssue
                                  ? Colors.red.withValues(alpha: 0.3)
                                  : const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(8),
                              border: isCurIssue ? Border.all(color: Colors.redAccent) : null,
                            ),
                            child: Text(
                              '$r ($d)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE2E8F0),
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ==========================================
                // TOMBOL AKSI HUB MULTI-DROP
                // ==========================================
                if (allPending) ...[
                  // 1. Kondisi Belum Berangkat: Tombol Mulai Jalan Multi-Drop
                  ElevatedButton.icon(
                    onPressed: () {
                      final firstDrop = multiDropItems.first;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverDeliveryScreen(shipment: firstDrop),
                        ),
                      ).then((_) => _loadData());
                    },
                    icon: const Icon(Icons.play_circle_fill, size: 18),
                    label: const Text('MULAI JALAN TRIP MULTI-DROP (ABSEN 1X)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ] else ...[
                  // 2. Kondisi Sudah Berangkat: Kontrol Lapor Posisi & Kendala Bersama
                  if (hasAnyActiveIssue) ...[
                    ElevatedButton.icon(
                      onPressed: () => _handleMultiDropResolveIncident(multiDropItems.first, multiDropItems),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('KENDALA ARMADA SELESAI, LANJUT JALAN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        // Tombol Lapor Posisi Semua Muatan
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleMultiDropTransit(multiDropItems.first, multiDropItems),
                            icon: const Icon(Icons.add_location_alt, size: 16),
                            label: const Text('LAPOR POSISI'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Tombol Lapor Kendala Armada
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleMultiDropIncident(multiDropItems.first, multiDropItems),
                            icon: const Icon(Icons.warning_amber_rounded, size: 16),
                            label: const Text('LAPOR KENDALA'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
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
                    builder: (_) => DriverDeliveryScreen(shipment: item),
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
}
