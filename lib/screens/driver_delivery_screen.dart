import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/checkpoint_photos_view.dart';
import '../widgets/action_location_dialog.dart';
import '../widgets/confirmation_dialog.dart';

class DriverDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> shipment;

  const DriverDeliveryScreen({super.key, required this.shipment});

  @override
  State<DriverDeliveryScreen> createState() => _DriverDeliveryScreenState();
}

class _DriverDeliveryScreenState extends State<DriverDeliveryScreen> {
  final _apiService = ApiService();
  final _picker = ImagePicker();

  bool _isSubmitting = false;
  bool _isOpeningAction = false;
  String _submittingStatus = 'Mengirim data laporan ke kantor...';
  late Map<String, dynamic> _shipment;
  List<dynamic> _checkpoints = [];

  // Posisi GPS Driver Realtime
  Position? _currentPosition;
  double? _currentAccuracy;

  @override
  void initState() {
    super.initState();
    _shipment = Map<String, dynamic>.from(widget.shipment);
    _initDataAndGps();
  }

  Future<void> _initDataAndGps() async {
    final detail = await _apiService.getShipmentDetail(_shipment['id']);
    if (detail != null && mounted) {
      setState(() {
        _shipment = detail;
        _checkpoints = detail['checkpoints'] ?? [];
      });
    }
    await _refreshGps();
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

  // Helper mengambil foto HANYA DARI KAMERA ASLI (ImageSource.camera WAJIB)
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

  // 1. Aksi: Absen Foto Selfie di Depan Truk & Mulai Jalan (Langsung Kamera)
  // 1. Aksi: Absen Foto Selfie di Depan Truk & Mulai Jalan (Peta Lokasi + Wajib Foto Kamera)
  Future<void> _handleDepartureSelfie() async {
    if (_isSubmitting || _isOpeningAction) return;
    setState(() => _isOpeningAction = true);

    await _refreshGps();
    if (!mounted) return;
    setState(() => _isOpeningAction = false);

    final driverLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2, 106.816);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActionLocationDialog(
        title: 'Absen Mulai Perjalanan',
        subtitle: 'Peta rute awal • Ambil foto selfie bersama armada truk',
        showTextInput: false,
        inputLabel: '',
        inputHint: '',
        actionButtonText: 'MULAI JALAN SEKARANG',
        actionColor: AppTheme.primaryBlue,
        actionIcon: Icons.local_shipping,
        driverPosition: driverLatLng,
        accuracy: _currentAccuracy,
        originCity: _shipment['origin_city'] ?? 'Asal',
        destinationCity: _shipment['destination_city'] ?? 'Tujuan',
        checkpoints: _checkpoints,
        onPickCameraPhoto: _pickStrictCameraPhoto,
      ),
    );

    if (result == null || !mounted) return;

    final XFile? photo = result['photo'] as XFile?;
    if (photo == null) return;

    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Mulai Pengiriman?',
      message: 'Foto absen selfie Anda akan dikirim ke kantor pusat dan status pengiriman resmi dimulai.',
      confirmText: 'Ya, Mulai Jalan',
      confirmColor: AppTheme.primaryBlue,
      icon: Icons.local_shipping,
    );
    if (!confirm) return;

    setState(() {
      _isSubmitting = true;
      _submittingStatus = 'Mengunggah foto absen & mencatat rute berangkat...';
    });

    final photoUrl = await _apiService.uploadPhoto(photo);

    final success = await _apiService.sendCheckpoint(
      shipmentId: _shipment['id'],
      checkpointType: 'departure_selfie',
      statusLabel: 'Mulai Perjalanan (Absen Berangkat Sopir)',
      description: 'Sopir telah menyelesaikan persiapan armada dan mulai perjalanan.',
      photoUrl: photoUrl,
      latitude: _currentPosition?.latitude ?? -6.2,
      longitude: _currentPosition?.longitude ?? 106.816,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      _initDataAndGps();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absen Berangkat berhasil disimpan! Selamat bertugas.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }
  Future<void> _handleTransitUpdate() async {
    if (_isSubmitting || _isOpeningAction) return;
    setState(() => _isOpeningAction = true);

    await _refreshGps();
    if (!mounted) return;

    final driverLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2, 106.816);

    setState(() => _isOpeningAction = false);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActionLocationDialog(
        title: 'Lapor Posisi Lapangan (Transit)',
        subtitle: 'Peta lokasi terpasang â€¢ Supir wajib foto & tulis keterangan',
        inputLabel: 'Tuliskan Lokasi & Kegiatan Saat Ini:',
        inputHint: 'Contoh: Masuk Tol Cikampek KM 57, sedang istirahat makan & cek ban...',
        actionButtonText: 'KIRIM LAPORAN POSISI SEKARANG',
        actionColor: const Color(0xFF0F172A),
        actionIcon: Icons.add_location_alt,
        driverPosition: driverLatLng,
        accuracy: _currentAccuracy,
        originCity: _shipment['origin_city'] ?? 'Asal',
        destinationCity: _shipment['destination_city'] ?? 'Tujuan',
        checkpoints: _checkpoints,
        onPickCameraPhoto: _pickStrictCameraPhoto,
      ),
    );

    if (result == null) return;

    final note = result['note'] as String;
    final photo = result['photo'] as XFile?;

    if (!mounted) return;
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Kirim Laporan Posisi?',
      message: 'Lokasi GPS dan foto kegiatan Anda akan dicatat ke server kantor pusat.',
      confirmText: 'Ya, Kirim Posisi',
      confirmColor: const Color(0xFF0F172A),
      icon: Icons.add_location_alt,
    );
    if (!confirm) return;

    setState(() {
      _isSubmitting = true;
      _submittingStatus = 'Mengunggah foto posisi & menyinkronkan GPS transit...';
    });
    await _refreshGps();

    String? photoUrl;
    if (photo != null) {
      photoUrl = await _apiService.uploadPhoto(photo);
    }

    final success = await _apiService.sendCheckpoint(
      shipmentId: _shipment['id'],
      checkpointType: 'transit_update',
      statusLabel: 'Posisi Lapangan: ${note.length > 30 ? "${note.substring(0, 30)}..." : note}',
      description: note,
      photoUrl: photoUrl,
      latitude: _currentPosition?.latitude ?? -6.2,
      longitude: _currentPosition?.longitude ?? 106.816,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      _initDataAndGps();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan posisi lapangan berhasil dicatat!'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    }
  }

  // 3. Aksi: Lapor Kendala Darurat (Peta Lokasi Kejadian + Tulis Manual + Foto Kamera Wajib)
  Future<void> _handleIncidentReport() async {
    if (_isSubmitting || _isOpeningAction) return;
    setState(() => _isOpeningAction = true);

    await _refreshGps();
    if (!mounted) return;

    final driverLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2, 106.816);

    setState(() => _isOpeningAction = false);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActionLocationDialog(
        title: 'Lapor Kendala Darurat di Jalan',
        subtitle: 'Peta titik kendala tercatat â€¢ Wajib foto bukti kerusakan armada',
        inputLabel: 'Jelaskan Kerusakan / Hambatan di Jalan:',
        inputHint: 'Contoh: Ban belakang sebelah kiri pecah di KM 82 arah Bandung, sedang menunggu montir...',
        actionButtonText: 'KIRIM PERINGATAN KENDALA KE KANTOR',
        actionColor: AppTheme.dangerRed,
        actionIcon: Icons.warning_amber_rounded,
        driverPosition: driverLatLng,
        accuracy: _currentAccuracy,
        originCity: _shipment['origin_city'] ?? 'Asal',
        destinationCity: _shipment['destination_city'] ?? 'Tujuan',
        checkpoints: _checkpoints,
        onPickCameraPhoto: _pickStrictCameraPhoto,
      ),
    );

    if (result == null) return;

    final note = result['note'] as String;
    final photo = result['photo'] as XFile?;

    if (!mounted) return;
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Kirim Laporan Posisi?',
      message: 'Lokasi GPS dan foto kegiatan Anda akan dicatat ke server kantor pusat.',
      confirmText: 'Ya, Kirim Posisi',
      confirmColor: const Color(0xFF0F172A),
      icon: Icons.add_location_alt,
    );
    if (!confirm) return;

    setState(() {
      _isSubmitting = true;
      _submittingStatus = 'Mengunggah foto posisi & menyinkronkan GPS transit...';
    });
    await _refreshGps();

    String? photoUrl;
    if (photo != null) {
      photoUrl = await _apiService.uploadPhoto(photo);
    }

    final success = await _apiService.sendCheckpoint(
      shipmentId: _shipment['id'],
      checkpointType: 'incident',
      statusLabel: 'Kendala di Jalan: ${note.length > 30 ? "${note.substring(0, 30)}..." : note}',
      description: note,
      photoUrl: photoUrl,
      latitude: _currentPosition?.latitude ?? -6.2,
      longitude: _currentPosition?.longitude ?? 106.816,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      _initDataAndGps();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peringatan kendala berhasil dikirim ke kantor pusat!'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  // 3b. Selesaikan Kendala (Melanjutkan Jalan)
  Future<void> _handleResolveIncident() async {
    if (_isSubmitting) return;
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Selesaikan Kendala?',
      message: 'Pastikan perbaikan armada telah selesai dan Anda sudah siap melanjutkan perjalanan secara aman.',
      confirmText: 'Ya, Selesai Kendala',
      confirmColor: AppTheme.successGreen,
      icon: Icons.check_circle_outline,
    );
    if (!confirm) return;

    setState(() {
      _isSubmitting = true;
      _submittingStatus = 'Memperbarui status armada menjadi normal & melanjutkan rute...';
    });
    await _refreshGps();

    final success = await _apiService.sendCheckpoint(
      shipmentId: _shipment['id'],
      checkpointType: 'incident_resolved',
      statusLabel: 'Kendala Selesai / Melanjutkan Jalan',
      description: 'Kendala armada telah selesai ditangani, sopir lanjut jalan.',
      latitude: _currentPosition?.latitude ?? -6.2,
      longitude: _currentPosition?.longitude ?? 106.816,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      _initDataAndGps();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendala selesai! Selamat melanjutkan perjalanan.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  // 4. Aksi: Sudah Sampai di Gudang Tujuan (Peta Lokasi + Wajib Foto Gerbang)
  Future<void> _handleArrival() async {
    if (_isSubmitting || _isOpeningAction) return;
    setState(() => _isOpeningAction = true);

    await _refreshGps();
    if (!mounted) return;
    setState(() => _isOpeningAction = false);

    final driverLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2, 106.816);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActionLocationDialog(
        title: 'Konfirmasi Tiba di Gerbang Tujuan',
        subtitle: 'Peta lokasi tersinkronisasi • Wajib foto gerbang gudang penerima',
        showTextInput: false,
        inputLabel: 'Keterangan Kedatangan / Posisi Parkir:',
        inputHint: 'Contoh: Sudah sampai di pintu gerbang utama gudang penerima, parkir di dermaga...',
        actionButtonText: 'KIRIM BUKTI SUDAH SAMPAI DI TUJUAN',
        actionColor: AppTheme.successGreen,
        actionIcon: Icons.flag_circle,
        driverPosition: driverLatLng,
        accuracy: _currentAccuracy,
        originCity: _shipment['origin_city'] ?? 'Asal',
        destinationCity: _shipment['destination_city'] ?? 'Tujuan',
        checkpoints: _checkpoints,
        onPickCameraPhoto: _pickStrictCameraPhoto,
      ),
    );

    if (result == null || !mounted) return;

    final XFile? photo = result['photo'] as XFile?;
    final String note = (result['note'] as String? ?? '').trim();

    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Kirim Laporan Kedatangan?',
      message: 'Foto dan titik lokasi Anda akan dikirim. Status pengiriman resmi menjadi "Armada Tiba di Tujuan" dan penerima dapat melakukan konfirmasi terima barang.',
      confirmText: 'Ya, Kirim Sekarang',
      confirmColor: AppTheme.successGreen,
      icon: Icons.flag_circle,
    );
    if (!confirm) return;

    setState(() {
      _isSubmitting = true;
      _submittingStatus = 'Mengunggah foto bukti gerbang tiba & mencatat GPS lokasi...';
    });

    String? photoUrl;
    if (photo != null) {
      photoUrl = await _apiService.uploadPhoto(photo);
    }

    final success = await _apiService.sendCheckpoint(
      shipmentId: _shipment['id'],
      checkpointType: 'arrival_driver',
      statusLabel: 'Armada Tiba di Tujuan (Menunggu Penerima)',
      description: note.isNotEmpty ? note : 'Armada telah sampai di gerbang gudang penerima. Menunggu tanda terima resmi.',
      photoUrl: photoUrl,
      latitude: _currentPosition?.latitude ?? -6.2,
      longitude: _currentPosition?.longitude ?? 106.816,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      _initDataAndGps();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successGreen, size: 26),
              SizedBox(width: 10),
              Text('Sampai di Tujuan', style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          content: const Text(
            'Laporan kedatangan berhasil dicatat! Status paket kini menjadi "Sampai di Tujuan". Menunggu pihak penerima memeriksa barang dan menandatangani tanda terima.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK, Mengerti'),
            ),
          ],
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final status = _shipment['status'] as String? ?? 'tertunda';
    final hasActiveIssue = _shipment['has_active_issue'] == true;
    final isArrived = _shipment['driver_arrived'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _shipment['resi'] ?? 'Detail Tugas',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
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
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
                // 1. Banner Peringatan jika Ada Kendala Aktif
                if (hasActiveIssue || status == 'kendala') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning, color: AppTheme.dangerRed, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Laporan Kendala Aktif!',
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
                          'Armada Anda saat ini ditandai sedang mengalami kendala di peta kantor pusat.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _handleResolveIncident,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('KENDALA SELESAI, LANJUT JALAN'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. KARTU DETAIL SURAT JALAN (PREMIUM DRIVER UI PRO-MAX)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Kartu
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
                              child: const Icon(Icons.description,
                                  color: AppTheme.primaryBlue, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Surat Jalan Pengiriman',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkNavy,
                              ),
                            ),
                            const Spacer(),
                            _buildStatusPill(status, isArrived),
                          ],
                        ),
                      ),

                      // Rute Visual Hero Banner
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
                          child: Row(
                            children: [
                              const Icon(Icons.trip_origin, color: Color(0xFF4ADE80), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _shipment['origin_city'] ?? 'Asal',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward, color: Colors.white60, size: 16),
                              const SizedBox(width: 8),
                              const Icon(Icons.location_on, color: Color(0xFFF87171), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _shipment['destination_city'] ?? 'Tujuan',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Info Rincian Kolom
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              Icons.business,
                              'Penerima / PT Tujuan',
                              _shipment['receiver_company'] ?? '-',
                              isPrimary: true,
                            ),
                            _buildInfoTile(
                              Icons.place_outlined,
                              'Alamat Bongkar',
                              _shipment['destination_address'] ?? '-',
                            ),
                            _buildInfoTile(
                              Icons.phone_outlined,
                              'Nomor Telepon Penerima',
                              _shipment['receiver_phone'] ?? '-',
                            ),
                            _buildInfoTile(
                              Icons.inventory_2_outlined,
                              'Muatan Kargo',
                              '${_shipment['total_colli'] ?? 1} Koli â€¢ ${_shipment['actual_weight_kg'] ?? 0} Kg',
                            ),
                            _buildInfoTile(
                              Icons.local_shipping_outlined,
                              'Nomor Plat Truk',
                              _shipment['nopol'] ?? '-',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. GALERI BUKTI LAPANGAN (HASIL FOTO KAMERA)
                CheckpointPhotosView(checkpoints: _checkpoints),
                const SizedBox(height: 24),

                // 4. 4 TOMBOL AKSI UTAMA BESAR PRO-MAX
                const Text(
                  'Tombol Aksi Lapangan (Wajib Foto Langsung):',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // 1. Absen Berangkat
                ElevatedButton.icon(
                  onPressed: (status == 'tertunda') ? _handleDepartureSelfie : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('1. FOTO ABSEN & MULAI JALAN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Lapor Posisi Sekarang
                ElevatedButton.icon(
                  onPressed: (status != 'terkirim' && !isArrived) ? _handleTransitUpdate : null,
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
                  onPressed: (status != 'terkirim' && !hasActiveIssue) ? _handleIncidentReport : null,
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
                const SizedBox(height: 12),

                // 4. Sudah Sampai di Tujuan
                ElevatedButton.icon(
                  onPressed: (status != 'terkirim' && !isArrived) ? _handleArrival : null,
                  icon: const Icon(Icons.flag_circle),
                  label: const Text('4. SUDAH SAMPAI DI GUDANG TUJUAN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isArrived ? const Color(0xFFE2E8F0) : AppTheme.successGreen,
                    foregroundColor: isArrived ? AppTheme.textMuted : Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 28),
              ],
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

          // OVERLAY LOADING ANTI-SPAM (MENCEGAH TEKAN BERULANG-ULANG)
          if (_isSubmitting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryBlue,
                            strokeWidth: 3.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Sedang Mengirim...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _submittingStatus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Mohon tunggu, jangan tutup aplikasi.',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
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

  Widget _buildStatusPill(String status, bool isArrived) {
    String text = 'Belum Berangkat';
    Color bg = const Color(0xFFFEF3C7);
    Color color = const Color(0xFFB45309);

    if (status == 'terkirim') {
      text = 'Selesai Terkirim';
      bg = const Color(0xFFD1FAE5);
      color = const Color(0xFF065F46);
    } else if (status == 'kendala') {
      text = 'Ada Kendala';
      bg = const Color(0xFFFEE2E2);
      color = const Color(0xFF991B1B);
    } else if (isArrived) {
      text = 'Sampai di Tujuan';
      bg = const Color(0xFFEDE9FE);
      color = const Color(0xFF5B21B6);
    } else if (status == 'dalam_pengiriman') {
      text = 'Dalam Perjalanan';
      bg = const Color(0xFFDBEAFE);
      color = const Color(0xFF1E40AF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: isPrimary ? AppTheme.primaryBlue : AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isPrimary ? 14 : 13,
                    fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
                    color: isPrimary ? AppTheme.darkNavy : AppTheme.textDark,
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

