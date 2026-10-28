import 'package:flutter/material.dart';
import '../models/delivery_model.dart';
import '../services/mock_data_service.dart';
import '../widgets/signature_pad.dart';
import 'watermark_camera_screen.dart';

class HandoverScreen extends StatefulWidget {
  final DeliveryOrder delivery;

  const HandoverScreen({super.key, required this.delivery});

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  final MockDataService _service = MockDataService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _recipientNameCtrl;
  late TextEditingController _recipientPhoneCtrl;
  late TextEditingController _recipientPinCtrl;
  late TextEditingController _complaintNoteCtrl;

  late List<CargoItem> _cargoList;
  List<Offset?> _signaturePoints = [];
  bool _hasComplaint = false;
  String? _handoverWatermark;

  @override
  void initState() {
    super.initState();
    _recipientNameCtrl = TextEditingController(text: 'Bpk. Agus Santoso');
    _recipientPhoneCtrl = TextEditingController(text: '081399881122');
    _recipientPinCtrl = TextEditingController(text: '8921');
    _complaintNoteCtrl = TextEditingController();

    // Clone list kargo agar bisa diedit secara independen
    _cargoList = widget.delivery.cargoItems.map((item) {
      return CargoItem(
        id: item.id,
        name: item.name,
        expectedQty: item.expectedQty,
        receivedQty: item.receivedQty,
        damagedQty: item.damagedQty,
        unit: item.unit,
        notes: item.notes,
      );
    }).toList();
  }

  @override
  void dispose() {
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _recipientPinCtrl.dispose();
    _complaintNoteCtrl.dispose();
    super.dispose();
  }

  void _openCameraForWatermark() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => WatermarkCameraScreen(
          title: 'Foto Serah Terima & Bongkar Muat',
          deliveryNumber: widget.delivery.suratJalanNumber,
          defaultLocation: widget.delivery.destinationWarehouse,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _handoverWatermark = result['watermark'] as String?;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto serah terima dengan watermark berhasil direkam!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  void _submitBAST() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_signaturePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajib mengisi tanda tangan penerima di atas layar!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Submit ke service
    _service.submitHandover(
      deliveryId: widget.delivery.id,
      recipientName: _recipientNameCtrl.text.trim(),
      recipientPhone: _recipientPhoneCtrl.text.trim(),
      recipientPin: _recipientPinCtrl.text.trim(),
      signaturePoints: _signaturePoints,
      complaintNote: _complaintNoteCtrl.text.trim(),
      hasComplaint: _hasComplaint,
      updatedCargo: _cargoList,
      handoverWatermark: _handoverWatermark,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.verified, size: 56, color: Color(0xFF10B981)),
        title: const Text('Serah Terima & BAST Berhasil!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status pengiriman kini telah Selesai (Completed). Berita Acara Serah Terima telah disimpan secara digital.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No. SJ: ${widget.delivery.suratJalanNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Penerima: ${_recipientNameCtrl.text}', style: const TextStyle(fontSize: 12)),
                  Text('Status Komplain: ${_hasComplaint ? "Ada Catatan Selisih" : "Muatan Diterima Lengkap & Baik"}',
                      style: TextStyle(fontSize: 12, color: _hasComplaint ? Colors.orange.shade800 : Colors.green.shade800, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Tutup dialog
              Navigator.of(context).pop(); // Kembali ke detail / home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Kembali ke Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Bongkar Muat & BAST'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Info Surat Jalan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TAHAP AKHIR: SERAH TERIMA',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0E7490)),
                        ),
                      ),
                      const Spacer(),
                      Text(widget.delivery.resiNumber, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'monospace')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.delivery.suratJalanNumber,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.warehouse_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tujuan: ${widget.delivery.destinationWarehouse}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 1: Cek Fisik Muatan & Rekonsiliasi Koli
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: Color(0xFF0F172A), size: 20),
                SizedBox(width: 8),
                Text(
                  '1. Rekonsiliasi Jumlah Barang Fisik',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pastikan kuantitas yang diterima sesuai dengan fisik yang dibongkar di lokasi.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            ..._cargoList.map((item) {
              final isDiscrepant = item.hasDiscrepancy;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDiscrepant ? const Color(0xFFFEF2F2) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDiscrepant ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SJ: ${item.expectedQty} ${item.unit}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Text('Diterima Baik: ', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                        const Spacer(),
                        // Counter minus
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 22, color: Colors.blueGrey),
                          onPressed: () {
                            if (item.receivedQty > 0) {
                              setState(() {
                                item.receivedQty--;
                                if (item.hasDiscrepancy) _hasComplaint = true;
                              });
                            }
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.receivedQty} ${item.unit}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1D4ED8)),
                          ),
                        ),
                        // Counter plus
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.blueGrey),
                          onPressed: () {
                            setState(() {
                              item.receivedQty++;
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Jumlah Rusak / Cacat: ', style: TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 22, color: Colors.blueGrey),
                          onPressed: () {
                            if (item.damagedQty > 0) {
                              setState(() {
                                item.damagedQty--;
                              });
                            }
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: item.damagedQty > 0 ? Colors.red.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.damagedQty} ${item.unit}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: item.damagedQty > 0 ? const Color(0xFFB91C1C) : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.blueGrey),
                          onPressed: () {
                            setState(() {
                              item.damagedQty++;
                              _hasComplaint = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // Section 2: Catatan / Ruang Komplain (Codename: "komplain")
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.feedback_outlined, size: 18, color: Color(0xFF0F172A)),
                      const SizedBox(width: 8),
                      const Text(
                        'Ruang Komplain & Catatan Khusus',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const Spacer(),
                      Switch(
                        value: _hasComplaint,
                        activeThumbColor: const Color(0xFFEF4444),
                        onChanged: (val) {
                          setState(() {
                            _hasComplaint = val;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_hasComplaint) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ada catatan selisih/kerusakan. Komplain akan diteruskan ke Admin Web & tercatat pada BAST.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _complaintNoteCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tuliskan detail barang rusak, koli basah, atau selisih kuantitas...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 3: Foto Bukti Watermark
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFF0F172A)),
                      const SizedBox(width: 8),
                      const Text(
                        'Foto Dokumentasi Serah Terima',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_handoverWatermark != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Foto Watermark GPS & Waktu Server Tersimpan',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: _openCameraForWatermark,
                            child: const Text('Ganti', style: TextStyle(color: Color(0xFF38BDF8))),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: _openCameraForWatermark,
                      icon: const Icon(Icons.camera),
                      label: const Text('Ambil Foto Kamera Native (Wajib Watermark)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFF0F172A)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 4: Data Penerima & Tanda Tangan Digital
            const Row(
              children: [
                Icon(Icons.badge_outlined, color: Color(0xFF0F172A), size: 20),
                SizedBox(width: 8),
                Text(
                  '2. Identitas Penerima & Validasi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _recipientNameCtrl,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap Penerima (Gudang/Customer)',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Nama penerima wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _recipientPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Nomor WhatsApp / HP',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Nomor kontak wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _recipientPinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'PIN Resi (Fisik)',
                      prefixIcon: const Icon(Icons.pin_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Interactive Signature Pad
            const Row(
              children: [
                Icon(Icons.draw_outlined, color: Color(0xFF0F172A), size: 20),
                SizedBox(width: 8),
                Text(
                  '3. Tanda Tangan Digital Penerima',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Silakan serahkan HP kepada penerima untuk menandatangani Berita Acara langsung di bawah ini.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            SignaturePad(
              onSigned: (points) {
                setState(() {
                  _signaturePoints = points;
                });
              },
              onClear: () {
                setState(() {
                  _signaturePoints.clear();
                });
              },
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _submitBAST,
              icon: const Icon(Icons.assignment_turned_in, size: 22),
              label: const Text(
                'Simpan BAST & Selesaikan Pengiriman',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // Emerald
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
