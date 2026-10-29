import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/action_location_dialog.dart';
import '../widgets/checkpoint_photos_view.dart';
import '../widgets/confirmation_dialog.dart';
import 'driver_delivery_screen.dart';

class DriverMultiDropScreen extends StatefulWidget {
  final String tripCode;
  final List<Map<String, dynamic>> shipments;
  final bool isBlockedByOtherTrip;

  const DriverMultiDropScreen({
    super.key,
    required this.tripCode,
    required this.shipments,
    this.isBlockedByOtherTrip = false,
  });

  @override
  State<DriverMultiDropScreen> createState() => _DriverMultiDropScreenState();
}

class _DriverMultiDropScreenState extends State<DriverMultiDropScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  late List<Map<String, dynamic>> _shipmentList;
  List<dynamic> _checkpoints = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _submittingStatus = '';
  bool _isOpeningAction = false;

  Position? _currentPosition;
  double? _currentAccuracy;

  @override
  void initState() {
    super.initState();
    _shipmentList = List<Map<String, dynamic>>.from(widget.shipments);
    _sortShipments();
    _initDataAndGps();
  }

  void _sortShipments() {
    _shipmentList.sort((a, b) =>
        ((a['drop_sequence'] as int? ?? 1).compareTo(b['drop_sequence'] as int? ?? 1)));
  }

  Future<void> _initDataAndGps() async {
    setState(() => _isLoading = true);
    await _refreshGps();
    await _fetchTripData();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTripData() async {
    try {
      // Ambil daftar resi terbaru supir untuk memperbarui data trip ini
      final all = await _apiService.getShipments();
      final updatedTripShipments = all
          .where((s) => (s['trip_code'] as String? ?? '').trim() == widget.tripCode)
          .map((s) => s as Map<String, dynamic>)
          .toList();

      if (updatedTripShipments.isNotEmpty) {
        _shipmentList = updatedTripShipments;
        _sortShipments();
      }

      // Ambil riwayat checkpoint dari shipment representatif pertama
      if (_shipmentList.isNotEmpty) {
        final firstId = _shipmentList.first['id'];
        final detail = await _apiService.getShipmentDetail(firstId);
        if (detail != null && detail['checkpoints'] != null) {
          _checkpoints = detail['checkpoints'] as List<dynamic>;
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        setState(() {
          _currentPosition = last;
          _currentAccuracy = last.accuracy;
        });
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _currentAccuracy = pos.accuracy;
        });
      }
    } catch (_) {}
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

  // 1. Absen Berangkat Multi-Drop
  Future<void> _handleDepartureSelfie() async {
    if (_isSubmitting || _isOpeningAction) return;
    setState(() => _isOpeningAction = true);

    await _refreshGps();
    if (!mounted) return;
    setState(() => _isOpeningAction = false);

    final sample = _shipmentList.first;
    final driverLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2, 106.816);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActionLocationDialog(
        title: 'Absen Mulai Perjalanan Multi-Drop',
        subtitle: 'Peta rute awal armada • Ambil foto selfie bersama armada truk',
        showTextInput: false,
        inputLabel: '',
        inputHint: '',
        actionButtonText: 'MULAI JALAN MULTI-DROP SEKARANG',
        actionColor: AppTheme.primaryBlue,
        actionIcon: Icons.local_shipping,
        driverPosition: driverLatLng,
        accuracy: _currentAccuracy,
        originCity: sample['origin_city'] ?? 'Asal',
        destinationCity: 'Multi-Drop (${_shipmentList.length} Tujuan)',
        checkpoints: _checkpoints,
        onPickCameraPhoto: _pickStrictCameraPhoto,
      ),
    );

    if (result == null || !mounted) return;

    final XFile? photo = result['photo'] as XFile?;
    if (photo == null) return;

    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Mulai Trip Multi-Drop?',
      message: 'Foto selfie armada akan dicatat dan perjalanan resmi dimulai untuk seluruh ${_shipmentList.length} resi sekaligus.',
      confirmText: 'Ya, Mulai Jalan',
      confirmColor: AppTheme.primaryBlue,
      icon: Icons.local_shipping,
    );
    if (!confirm || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _submittingStatus = 'Mengunggah foto absen & mencatat awal rute multi-drop...';
    });

    final photoUrl = await _apiService.uploadPhoto(photo);

    final success = await _apiService.sendCheckpoint(
      shipmentId: sample['id'],
      checkpointType: 'departure_selfie',
      statusLabel: 'Mulai Perjalanan Multi-Drop (Absen Berangkat Sopir)',
      description: 'Sopir telah menyelesaikan persiapan armada dan mulai perjalanan multi-drop untuk ${_shipmentList.length} resi.',
      photoUrl: photoUrl,
      latitude: _currentPosition?.latitude ?? -6.2,
      longitude: _currentPosition?.longitude ?? 106.816,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      await _initDataAndGps();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Absen Berangkat Multi-Drop (${_shipmentList.length} resi) berhasil disimpan! Selamat bertugas.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  // 2. Lapor Posisi Multi-Drop
  Future<void> _handleTransitUpdate() async {
    if (_isSubmitting || _isOpeningAction) return;
    setState(() => _isOpeningAction = true);

    await _refreshGps();
    if (!mounted) return;

    final sample = _shipmentList.first;
    final driverLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2, 106.816);

    setState(() => _isOpeningAction = false);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActionLocationDialog(
        title: 'Lapor Posisi Multi-Drop',
        subtitle: 'Laporan posisi berlaku serentak untuk seluruh ${_shipmentList.length} resi rombongan',
        inputLabel: 'Tuliskan Lokasi & Posisi Armada Saat Ini:',
        inputHint: 'Contoh: Istirahat di Rest Area Tol KM 102, cek kondisi ban & mesin armada...',
        actionButtonText: 'KIRIM LAPORAN POSISI MULTI-DROP',
        actionColor: const Color(0xFF0F172A),
        actionIcon: Icons.add_location_alt,
        driverPosition: driverLatLng,
        accuracy: _currentAccuracy,
        originCity: sample['origin_city'] ?? 'Asal',
        destinationCity: 'Multi-Drop (${_shipmentList.length} Tujuan)',
        checkpoints: _checkpoints,
        onPickCameraPhoto: _pickStrictCameraPhoto,
      ),
    );

    if (result == null || !mounted) return;

    final String note = (result['note'] as String? ?? '').trim();
    final XFile? photo = result['photo'] as XFile?;

    if (note.isEmpty && photo == null) return;

    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Kirim Laporan Posisi Multi-Drop?',
      message: 'Laporan posisi armada akan disinkronkan ke seluruh ${_shipmentList.length} resi rombongan di peta kantor pusat.',
      confirmText: 'Ya, Kirim Posisi',
      confirmColor: const Color(0xFF0F172A),
      icon: Icons.add_location_alt,
    );
    if (!confirm || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _submittingStatus = 'Menyinkronkan laporan posisi armada ke seluruh resi...';
    });

    String? photoUrl;
    if (photo != null) {
      photoUrl = await _apiService.uploadPhoto(photo);
    }

    final success = await _apiService.sendCheckpoint(
      shipmentId: sample['id'],
      checkpointType: 'transit_update',
      statusLabel: 'Posisi Multi-Drop: ${note.length > 30 ? "${note.substring(0, 30)}..." : note}',
      description: note.isNotEmpty ? note : 'Pembaruan lokasi rute armada multi-drop di jalan.',
      photoUrl: photoUrl,
      latitude: _currentPosition?.latitude ?? -6.2,
      longitude: _currentPosition?.longitude ?? 106.816,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      await _initDataAndGps();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laporan posisi tersimpan serentak untuk ${_shipmentList.length} muatan!'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    }
  }

  // 3. Lapor Kendala Multi-Drop
  Future<void> _handleIncidentReport() async {
    if (_isSubmitting || _isOpeningAction) return;
    setState(() => _isOpeningAction = true);

    await _refreshGps();
    if (!mounted) return;

    final sample = _shipmentList.first;
    final driverLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2, 106.816);

    setState(() => _isOpeningAction = false);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActionLocationDialog(
        title: 'Lapor Kendala Armada Multi-Drop',
        subtitle: 'Peringatan kendala otomatis menandai seluruh ${_shipmentList.length} resi rombongan',
        inputLabel: 'Jelaskan Kerusakan / Kendala Armada:',
        inputHint: 'Contoh: Ban belakang kanan pecah di KM 80, sedang menunggu bantuan mekanik...',
        actionButtonText: 'KIRIM PERINGATAN KENDALA KE KANTOR',
        actionColor: AppTheme.dangerRed,
        actionIcon: Icons.warning_amber_rounded,
        driverPosition: driverLatLng,
        accuracy: _currentAccuracy,
        originCity: sample['origin_city'] ?? 'Asal',
        destinationCity: 'Multi-Drop (${_shipmentList.length} Tujuan)',
        checkpoints: _checkpoints,
        onPickCameraPhoto: _pickStrictCameraPhoto,
      ),
    );

    if (result == null || !mounted) return;

    final String note = (result['note'] as String? ?? '').trim();
    final XFile? photo = result['photo'] as XFile?;

    if (note.isEmpty && photo == null) return;

    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Kirim Peringatan Kendala?',
      message: 'Seluruh ${_shipmentList.length} resi rombongan akan ditandai dalam status kendala armada di dashboard kantor pusat.',
      confirmText: 'Ya, Kirim Kendala',
      confirmColor: AppTheme.dangerRed,
      icon: Icons.warning_amber_rounded,
    );
    if (!confirm || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _submittingStatus = 'Mengirim peringatan kendala armada ke seluruh resi...';
    });

    String? photoUrl;
    if (photo != null) {
      photoUrl = await _apiService.uploadPhoto(photo);
    }

    final success = await _apiService.sendCheckpoint(
      shipmentId: sample['id'],
      checkpointType: 'incident',
      statusLabel: 'Kendala Armada: ${note.length > 30 ? "${note.substring(0, 30)}..." : note}',
      description: note.isNotEmpty ? note : 'Armada mengalami kendala operasional dalam perjalanan multi-drop.',
      photoUrl: photoUrl,
      latitude: _currentPosition?.latitude ?? -6.2,
      longitude: _currentPosition?.longitude ?? 106.816,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      await _initDataAndGps();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kendala armada berhasil dicatat untuk seluruh ${_shipmentList.length} resi!'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  // Selesaikan Kendala Multi-Drop
  Future<void> _handleResolveIncident() async {
    if (_isSubmitting) return;

    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Selesaikan Kendala Armada?',
      message: 'Status kendala di seluruh ${_shipmentList.length} resi rombongan akan dicabut dan armada kembali berstatus Dalam Perjalanan normal.',
      confirmText: 'Ya, Selesai & Lanjut Jalan',
      confirmColor: AppTheme.successGreen,
      icon: Icons.check_circle_outline,
    );
    if (!confirm || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _submittingStatus = 'Mencabut status kendala armada & melanjutkan perjalanan...';
    });
    await _refreshGps();

    final sample = _shipmentList.first;
    final success = await _apiService.sendCheckpoint(
      shipmentId: sample['id'],
      checkpointType: 'incident_resolved',
      statusLabel: 'Kendala Selesai / Melanjutkan Jalan',
      description: 'Kendala armada telah selesai ditangani, sopir lanjut jalan menyelesaikan rute multi-drop.',
      latitude: _currentPosition?.latitude ?? -6.2,
      longitude: _currentPosition?.longitude ?? 106.816,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      await _initDataAndGps();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendala armada selesai! Selamat melanjutkan perjalanan multi-drop.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool allPending = _shipmentList.isNotEmpty &&
        _shipmentList.every((it) => it['status'] == 'tertunda');
    final bool hasAnyActiveIssue = _shipmentList.any(
        (it) => it['has_active_issue'] == true || it['status'] == 'kendala');
    final bool hasDeparted = !allPending ||
        _checkpoints.any((c) => c['checkpoint_type'] == 'departure_selfie');

    final sampleNopol = (_shipmentList.isNotEmpty ? _shipmentList.first['nopol'] : '-') ?? '-';
    final sampleVehicle = (_shipmentList.isNotEmpty ? _shipmentList.first['vehicle_name'] : null) as String?;
    final sampleOrigin = (_shipmentList.isNotEmpty ? _shipmentList.first['origin_city'] : 'Asal') ?? 'Asal';

    final armadaSubtitle = (sampleVehicle != null && sampleVehicle.trim().isNotEmpty)
        ? '$sampleVehicle • $sampleNopol'
        : 'Armada $sampleNopol';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tripCode,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              armadaSubtitle,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Data',
            onPressed: () async {
              await _refreshGps();
              await _initDataAndGps();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryBlue),
                      SizedBox(height: 14),
                      Text('Memuat rincian perjalanan multi-drop...',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // Banner Kendala Aktif
                    if (hasAnyActiveIssue) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning, color: AppTheme.dangerRed, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Laporan Kendala Armada Aktif!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF991B1B),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Armada saat ini ditandai mengalami kendala di dashboard kantor pusat untuk seluruh resi rombongan ini.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _handleResolveIncident,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('KENDALA SELESAI / LANJUT JALAN'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Kartu Rangkuman Perjalanan Multi-Drop
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.alt_route, color: AppTheme.primaryBlue, size: 18),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: const Text(
                                    'Surat Jalan Terpadu Multi-Drop',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.darkNavy,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: hasDeparted ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: hasDeparted ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: Text(
                                    hasDeparted ? 'DALAM PERJALANAN' : 'TERTUNDA',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: hasDeparted ? const Color(0xFF1E40AF) : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Visual Kota Asal ke Seluruh Tujuan
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.trip_origin, color: Color(0xFF4ADE80), size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Asal: $sampleOrigin',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 7),
                                    child: SizedBox(
                                      height: 12,
                                      child: VerticalDivider(color: Colors.white38, thickness: 1.5),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Color(0xFFF87171), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Drop Urutan: ${_shipmentList.map((s) => s['destination_city'] ?? '-').join(' ➔ ')}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Daftar Resi Rincian Multi-Drop
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Daftar Resi & Tujuan Drop Rombongan:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._shipmentList.asMap().entries.map((entry) {
                                  final idx = entry.key + 1;
                                  final s = entry.value;
                                  final r = s['resi'] ?? '-';
                                  final dest = s['destination_city'] ?? '-';
                                  final comp = s['receiver_company'] ?? '-';
                                  final isArr = s['driver_arrived'] == true;
                                  final isDeliv = s['status'] == 'terkirim';

                                  return InkWell(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DriverDeliveryScreen(shipment: s),
                                        ),
                                      );
                                      _fetchTripData();
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: isDeliv
                                                ? AppTheme.successGreen
                                                : (isArr ? Colors.amber[700] : AppTheme.primaryBlue),
                                            child: Text(
                                              '$idx',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      r,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 13,
                                                        fontFamily: 'monospace',
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '($dest)',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.primaryBlue,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  comp,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.textMuted,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isDeliv)
                                            const Chip(
                                              label: Text('SELESAI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                              backgroundColor: Color(0xFFDCFCE7),
                                              labelPadding: EdgeInsets.symmetric(horizontal: 4),
                                              visualDensity: VisualDensity.compact,
                                            )
                                          else if (isArr)
                                            const Chip(
                                              label: Text('TIBA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                              backgroundColor: Color(0xFFFEF3C7),
                                              labelPadding: EdgeInsets.symmetric(horizontal: 4),
                                              visualDensity: VisualDensity.compact,
                                            )
                                          else
                                            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Galeri Bukti Lapangan Terpusat
                    CheckpointPhotosView(checkpoints: _checkpoints),
                    const SizedBox(height: 24),

                    // 3 Tombol Aksi Lapangan Multi-Drop
                    const Text(
                      'Aksi Perjalanan Truk (Serentak):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Banner Info jika Terkunci oleh Trip Aktif Lain
                    if (widget.isBlockedByOtherTrip && !hasDeparted) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Armada sedang aktif di perjalanan tugas lain. Selesaikan atau tuntaskan trip berjalan sebelum memulai absen trip ini.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF92400E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 1. Absen Berangkat Multi-Drop
                    ElevatedButton.icon(
                      onPressed: (!hasDeparted && !widget.isBlockedByOtherTrip) ? _handleDepartureSelfie : null,
                      icon: Icon(widget.isBlockedByOtherTrip ? Icons.lock : Icons.camera_alt),
                      label: Text(
                        widget.isBlockedByOtherTrip
                            ? '1. TERKUNCI (MENUNGGU TRIP LAIN)'
                            : '1. FOTO ABSEN & MULAI JALAN',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isBlockedByOtherTrip
                            ? const Color(0xFF64748B)
                            : AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Lapor Posisi Sekarang
                    ElevatedButton.icon(
                      onPressed: hasDeparted ? _handleTransitUpdate : null,
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('2. LIHAT PETA & LAPOR POSISI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Lapor Kendala
                    ElevatedButton.icon(
                      onPressed: (hasDeparted && !hasAnyActiveIssue) ? _handleIncidentReport : null,
                      icon: const Icon(Icons.build_circle),
                      label: const Text('3. LAPOR KENDALA DI JALAN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        foregroundColor: AppTheme.dangerRed,
                        side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),

          // Loading Overlay Saat Submit Aksi
          if (_isSubmitting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
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
                          _submittingStatus,
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

          // OVERLAY LOADING SAAT MEMBUKA AKSI / MENGAMBIL GPS & KAMERA
          if (_isOpeningAction)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Mempersiapkan lokasi GPS & kamera...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
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
    );
  }
}
