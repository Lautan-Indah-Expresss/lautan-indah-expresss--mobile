import 'package:flutter/material.dart';

class SignaturePad extends StatefulWidget {
  final Function(List<Offset?>) onSigned;
  final VoidCallback onClear;
  final List<Offset?>? initialPoints;
  final bool readOnly;

  const SignaturePad({
    super.key,
    required this.onSigned,
    required this.onClear,
    this.initialPoints,
    this.readOnly = false,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  late List<Offset?> _points;

  @override
  void initState() {
    super.initState();
    _points = widget.initialPoints != null
        ? List<Offset?>.from(widget.initialPoints!)
        : [];
  }

  void _clear() {
    if (widget.readOnly) return;
    setState(() {
      _points.clear();
    });
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blueGrey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Panduan garis tanda tangan
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Container(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
              ),
              Positioned(
                bottom: 16,
                left: 24,
                child: Text(
                  'Tanda Tangan Penerima di Atas Garis',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_points.isEmpty && !widget.readOnly)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.draw_outlined, size: 36, color: Colors.grey.shade300),
                      const SizedBox(height: 6),
                      Text(
                        'Sentuh layar dan goreskan tanda tangan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              // Canvas penangkap coretan
              GestureDetector(
                onPanStart: widget.readOnly
                    ? null
                    : (details) {
                        setState(() {
                          final RenderBox renderBox = context.findRenderObject() as RenderBox;
                          _points.add(renderBox.globalToLocal(details.globalPosition));
                        });
                      },
                onPanUpdate: widget.readOnly
                    ? null
                    : (details) {
                        setState(() {
                          final RenderBox renderBox = context.findRenderObject() as RenderBox;
                          _points.add(renderBox.globalToLocal(details.globalPosition));
                        });
                      },
                onPanEnd: widget.readOnly
                    ? null
                    : (details) {
                        setState(() {
                          _points.add(null);
                        });
                        widget.onSigned(_points);
                      },
                child: CustomPaint(
                  painter: SignaturePainter(points: _points),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _points.isEmpty ? null : _clear,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Hapus & Tanda Tangan Ulang'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A) // Slate 900 ink
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawCircle(points[i]!, 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) {
    return true;
  }
}
