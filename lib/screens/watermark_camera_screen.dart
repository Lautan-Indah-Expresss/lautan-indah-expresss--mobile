import 'dart:async';
import 'package:flutter/material.dart';
import '../services/mock_data_service.dart';

class WatermarkCameraScreen extends StatefulWidget {
  final String title;
  final String deliveryNumber;
  final String defaultLocation;

  const WatermarkCameraScreen({
    super.key,
    required this.title,
    required this.deliveryNumber,
    required this.defaultLocation,
  });

  @override
  State<WatermarkCameraScreen> createState() => _WatermarkCameraScreenState();
}

class _WatermarkCameraScreenState extends State<WatermarkCameraScreen> {
  final MockDataService _service = MockDataService();
  late Timer _timer;
  late DateTime _currentTime;
  bool _isCaptured = false;
  String _selectedPreset = 'Muatan & Segel Box';

  final List<String> _presets = [
    'Muatan & Segel Box',
    'Posisi Truk di Lokasi',
    'Fisik Koli Barang',
    'Kondisi Kerusakan / Selisih',
    'Penyerahan Dokumen',
  ];

  // Mocked dynamic coordinates
  final String _currentCoordinates = '-6.192518° S, 106.945281° E (Akurasi: 3.5m)';

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isCaptured) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second WIB';
  }

  String get _watermarkString {
    final driver = _service.driver;
    return '• KOORDINAT : $_currentCoordinates\n'
        '• WAKTU SERVER : ${_formatDateTime(_currentTime)}\n'
        '• NOPOL ARMADA : ${driver.licensePlate} (${driver.truckType})\n'
        '• DRIVER : ${driver.name} [${driver.id}]\n'
        '• SURAT JALAN : ${widget.deliveryNumber}\n'
        '• LOKASI/EVENT : ${widget.defaultLocation} [$_selectedPreset]';
  }

  void _capturePhoto() {
    setState(() {
      _isCaptured = true;
    });
  }

  void _retakePhoto() {
    setState(() {
      _isCaptured = false;
    });
  }

  void _confirmPhoto() {
    Navigator.of(context).pop({
      'watermark': _watermarkString,
      'preset': _selectedPreset,
      'timestamp': _currentTime,
      'coordinates': _currentCoordinates,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _isCaptured ? 'Hasil Foto (Watermark Aktif)' : widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_isCaptured)
            IconButton(
              icon: const Icon(Icons.flash_auto),
              tooltip: 'Flash Auto',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Flash disetel ke Otomatis'), duration: Duration(seconds: 1)),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Preset Selector saat belum jepret
            if (!_isCaptured)
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presets.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final p = _presets[index];
                    final isSelected = p == _selectedPreset;
                    return ChoiceChip(
                      label: Text(p, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
                      selected: isSelected,
                      selectedColor: const Color(0xFFF59E0B),
                      backgroundColor: Colors.grey.shade900,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPreset = p;
                          });
                        }
                      },
                    );
                  },
                ),
              ),

            // Viewfinder Camera Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isCaptured ? const Color(0xFF10B981) : Colors.white24,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Viewfinder Simulation (Realistic Graphic)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isCaptured
                                ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                                : [const Color(0xFF334155), const Color(0xFF0F172A)],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _selectedPreset.contains('Kerusakan')
                                    ? Icons.report_problem_outlined
                                    : _selectedPreset.contains('Segel')
                                        ? Icons.lock_outline
                                        : Icons.local_shipping_outlined,
                                size: 80,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'SIMULASI KAMERA NATIVE DRIVER',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.3),
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Subjek: $_selectedPreset',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Grid lines kamera saat aktif
                      if (!_isCaptured)
                        CustomPaint(
                          painter: CameraGridPainter(),
                          size: Size.infinite,
                        ),

                      // WATERMARK OVERLAY DI BAGIAN BAWAH FOTO (Native requirement)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.90),
                                Colors.black.withOpacity(0.60),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'VERIFIED WATERMARK',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.gps_fixed, size: 14, color: Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'GPS LOCKED',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _watermarkString,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontFamily: 'monospace',
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Controls di bagian bawah (Shutter / Review actions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _isCaptured
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _retakePhoto,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text('Ambil Ulang', style: TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white38),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _confirmPhoto,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Gunakan Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                          tooltip: 'Galeri (Disable untuk keamanan SOP)',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('SOP: Upload dari galeri dinonaktifkan. Foto wajib diambil langsung via kamera.'),
                              ),
                            );
                          },
                        ),
                        // Shutter Button
                        GestureDetector(
                          onTap: _capturePhoto,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 28),
                          tooltip: 'Ganti Kamera',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kamera belakang aktif (Rekomendasi untuk dokumentasi muatan)'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.0;

    // Garis vertikal 1 & 2
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);

    // Garis horizontal 1 & 2
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
