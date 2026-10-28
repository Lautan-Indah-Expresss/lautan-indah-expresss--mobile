import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import 'driver_map_view.dart';

class ActionLocationDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool showTextInput;
  final String inputLabel;
  final String inputHint;
  final String actionButtonText;
  final Color actionColor;
  final IconData actionIcon;
  final LatLng driverPosition;
  final double? accuracy;
  final String originCity;
  final String destinationCity;
  final List<dynamic> checkpoints;
  final Future<XFile?> Function() onPickCameraPhoto;

  const ActionLocationDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.showTextInput = true,
    required this.inputLabel,
    required this.inputHint,
    required this.actionButtonText,
    required this.actionColor,
    required this.actionIcon,
    required this.driverPosition,
    this.accuracy,
    required this.originCity,
    required this.destinationCity,
    this.checkpoints = const [],
    required this.onPickCameraPhoto,
  });

  @override
  State<ActionLocationDialog> createState() => _ActionLocationDialogState();
}

class _ActionLocationDialogState extends State<ActionLocationDialog> {
  final TextEditingController _noteController = TextEditingController();
  XFile? _capturedPhoto;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });
    final photo = await widget.onPickCameraPhoto();
    setState(() {
      _capturedPhoto = photo;
      _isCapturing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.actionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.actionIcon, color: widget.actionColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.darkNavy,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Body Form & Map
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // 1. PETA INTERAKTIF POSISI REALTIME DRIVER
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DriverMapView(
                      driverPosition: widget.driverPosition,
                      accuracy: widget.accuracy,
                      originCity: widget.originCity,
                      destinationCity: widget.destinationCity,
                      checkpoints: widget.checkpoints,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (widget.showTextInput) ...[
                // 2. INPUT MANUAL KEGIATAN / KENDALA (SUPIR TIDAK BISA ASAL PILIH)
                Text(
                  widget.inputLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  onChanged: (_) {
                    if (_errorMessage != null) setState(() => _errorMessage = null);
                  },
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: widget.inputHint,
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: widget.actionColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                ],
                // 3. FOTO WAJIB DARI KAMERA
                const Text(
                  'Foto Bukti Lapangan (Wajib Kamera):',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),

                if (_capturedPhoto == null) ...[
                  InkWell(
                    onTap: _isCapturing ? null : _takePhoto,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.actionColor.withValues(alpha: 0.1),
                              ),
                              child: Icon(Icons.camera_alt,
                                  color: widget.actionColor, size: 24),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isCapturing
                                  ? 'Membuka kamera...'
                                  : 'Tekan untuk Buka Kamera Langsung',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: widget.actionColor,
                              ),
                            ),
                            const Text(
                              'Foto hanya bisa diambil dari kamera resmi saat ini',
                              style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_capturedPhoto!.path),
                            width: 75,
                            height: 75,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Foto Berhasil Diambil',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Kamera resmi • Lokasi & Waktu GPS disematkan',
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
                          tooltip: 'Foto Ulang',
                          onPressed: _takePhoto,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Action Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.dangerRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.dangerRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ElevatedButton.icon(
                  onPressed: () {
                    final note = _noteController.text.trim();
                    if (widget.showTextInput && note.isEmpty) {
                      setState(() {
                        _errorMessage = 'Harap isi keterangan/alasan terlebih dahulu!';
                      });
                      return;
                    }
                    if (_capturedPhoto == null) {
                      setState(() {
                        _errorMessage = 'Wajib ambil foto bukti kamera terlebih dahulu!';
                      });
                      return;
                    }

                    Navigator.pop(context, {
                      'note': note,
                      'photo': _capturedPhoto,
                    });
                  },
                  icon: Icon(widget.actionIcon),
                  label: Text(widget.actionButtonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.actionColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

