import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

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
  late Map<String, dynamic> _shipment;

  @override
  void initState() {
    super.initState();
    _shipment = Map<String, dynamic>.from(widget.shipment);
  }

  // Helper mendapatkan GPS cepat
  Future<Position> _getGpsPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      // Fallback coordinate jika GPS gagal (Jakarta)
      return Position(
        latitude: -6.200000,
        longitude: 106.816666,
        timestamp: DateTime.now(),
        accuracy: 50,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  // 1. Absen Berangkat
  Future<void> _handleDepartureSelfie() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 75,
    );
    if (photo == null) return;

    setState(() => _isSubmitting = true);
    final pos = await _getGpsPosition();
    final photoUrl = await _apiService.uploadPhoto(photo);

    final success = await _apiService.sendCheckpoint(
      shipmentId: _shipment['id'],
      checkpointType: 'departure_selfie',
      statusLabel: 'Mulai Perjalanan (Absen Berangkat Sopir)',
      description: 'Sopir telah menyelesaikan persiapan armada dan mulai jalan.',
      photoUrl: photoUrl,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      setState(() {
        _shipment['status'] = 'dalam_pengiriman';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absen Berangkat berhasil disimpan! Selamat bertugas.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  // 2. Lapor Posisi Sekarang
  Future<void> _handleTransitUpdate() async {
    String? selectedPlace = 'Masuk Gerbang Tol';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Lapor Posisi Sekarang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih titik singgah:',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              ...[
                'Masuk Gerbang Tol',
                'Istirahat di Rest Area',
                'Keluar Gerbang Tol',
                'Perjalanan Lancar Tanpa Hambatan',
              ].map((place) => RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(place, style: const TextStyle(fontSize: 13)),
                    value: place,
                    groupValue: selectedPlace,
                    onChanged: (val) {
                      setDialogState(() => selectedPlace = val);
                    },
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 42),
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: const Text('Kirim Posisi'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    final pos = await _getGpsPosition();

    final success = await _apiService.sendCheckpoint(
      shipmentId: _shipment['id'],
      checkpointType: 'transit_update',
      statusLabel: 'Titik Posisi: $selectedPlace',
      description: 'Armada melintas dalam kondisi aman ($selectedPlace).',
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Titik "$selectedPlace" berhasil dicatat.'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    }
  }

  // 3. Lapor Kendala Darurat
  Future<void> _handleIncidentReport() async {
    String? selectedIncident = 'Ban Belakang Bocor / Meledak';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed),
              SizedBox(width: 8),
              Text('Lapor Kendala di Jalan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih masalah armada:',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              ...[
                'Ban Belakang Bocor / Meledak',
                'Mesin Overheat / Mogok di Tol',
                'Macet Total Parah (> 2 Jam)',
                'Akses Terputus (Banjir/Longsor)',
              ].map((inc) => RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(inc, style: const TextStyle(fontSize: 13)),
                    value: inc,
                    groupValue: selectedIncident,
                    onChanged: (val) {
                      setDialogState(() => selectedIncident = val);
                    },
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 42),
                backgroundColor: AppTheme.dangerRed,
              ),
              child: const Text('Kirim Kendala'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    final pos = await _getGpsPosition();

    final success = await _apiService.sendCheckpoint(
      shipmentId: _shipment['id'],
      checkpointType: 'incident',
      statusLabel: 'Kendala di Jalan: $selectedIncident',
      description: 'Armada mengalami kendala di perjalanan: $selectedIncident.',
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      setState(() {
        _shipment['status'] = 'kendala';
        _shipment['has_active_issue'] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peringatan kendala berhasil dikirim ke kantor.'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  // 3b. Selesaikan Kendala
  Future<void> _handleResolveIncident() async {
    setState(() => _isSubmitting = true);
    final pos = await _getGpsPosition();

    final success = await _apiService.sendCheckpoint(
      shipmentId: _shipment['id'],
      checkpointType: 'incident_resolved',
      statusLabel: 'Kendala Selesai / Melanjutkan Jalan',
      description: 'Kendala armada telah selesai ditangani, sopir lanjut jalan.',
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      setState(() {
        _shipment['status'] = 'dalam_pengiriman';
        _shipment['has_active_issue'] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendala selesai! Selamat melanjutkan perjalanan.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  // 4. Sudah Sampai di Tujuan
  Future<void> _handleArrival() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 75,
    );
    if (photo == null) return;

    setState(() => _isSubmitting = true);
    final pos = await _getGpsPosition();
    final photoUrl = await _apiService.uploadPhoto(photo);

    final success = await _apiService.sendCheckpoint(
      shipmentId: _shipment['id'],
      checkpointType: 'arrival_driver',
      statusLabel: 'Armada Tiba di Tujuan (Menunggu Penerima)',
      description: 'Armada telah sampai di gerbang gudang penerima. Menunggu tanda terima resmi.',
      photoUrl: photoUrl,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      setState(() {
        _shipment['driver_arrived'] = true;
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successGreen),
              SizedBox(width: 8),
              Text('Sampai di Tujuan'),
            ],
          ),
          content: const Text(
            'Laporan tiba berhasil dicatat!\n\nHarap tunggu pihak gudang penerima memeriksa barang dan menandatangani tanda terima di sistem web.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 42),
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: const Text('Mengerti'),
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
      appBar: AppBar(
        title: Text(_shipment['resi'] ?? 'Detail Tugas'),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengirim data ke server...',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Warning jika ada kendala aktif
                if (hasActiveIssue || status == 'kendala') ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning, color: AppTheme.dangerRed),
                            SizedBox(width: 8),
                            Text('Laporan Kendala Aktif!',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF991B1B))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Armada Anda ditandai sedang mengalami kendala di peta kantor.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _handleResolveIncident,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                          ),
                          child: const Text('KENDALA SELESAI, LANJUT JALAN'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Kartu Info Pengiriman
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Pengiriman',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20),
                      _buildInfoRow('Tujuan', _shipment['receiver_company'] ?? '-'),
                      _buildInfoRow('Alamat', _shipment['destination_address'] ?? '-'),
                      _buildInfoRow('Kota', '${_shipment['origin_city']} ➔ ${_shipment['destination_city']}'),
                      _buildInfoRow('Muatan', '${_shipment['total_colli'] ?? 1} Koli (${_shipment['actual_weight_kg'] ?? 0} kg)'),
                      _buildInfoRow('Truk/Armada', _shipment['nopol'] ?? '-'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4 TOMBOL AKSI UTAMA BESAR RAMAH SUPIR
                const Text(
                  'Tombol Aksi Sopir:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
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
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Lapor Posisi Sekarang
                ElevatedButton.icon(
                  onPressed: (status != 'terkirim' && !isArrived) ? _handleTransitUpdate : null,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('2. LAPOR POSISI SEKARANG'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Lapor Kendala
                ElevatedButton.icon(
                  onPressed: (status != 'terkirim' && !hasActiveIssue) ? _handleIncidentReport : null,
                  icon: const Icon(Icons.build_circle),
                  label: const Text('3. LAPOR KENDALA DI JALAN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2),
                    foregroundColor: AppTheme.dangerRed,
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
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
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          const Text(': ', style: TextStyle(color: AppTheme.textMuted)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
