import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';

class DriverMapView extends StatefulWidget {
  final LatLng? driverPosition;
  final double? accuracy;
  final LatLng? originPosition;
  final LatLng? destinationPosition;
  final String originCity;
  final String destinationCity;
  final List<dynamic> checkpoints;

  const DriverMapView({
    super.key,
    required this.driverPosition,
    this.accuracy,
    this.originPosition,
    this.destinationPosition,
    required this.originCity,
    required this.destinationCity,
    this.checkpoints = const [],
  });

  @override
  State<DriverMapView> createState() => _DriverMapViewState();
}

class _DriverMapViewState extends State<DriverMapView> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    // Pusat peta: posisi driver, atau tujuan, atau default Indonesia (Jakarta)
    final center = widget.driverPosition ??
        widget.destinationPosition ??
        widget.originPosition ??
        const LatLng(-6.200000, 106.816666);

    // Kumpulkan titik polyline dari checkpoints
    final List<LatLng> routePoints = [];
    if (widget.originPosition != null) {
      routePoints.add(widget.originPosition!);
    }

    for (final cp in widget.checkpoints) {
      final lat = double.tryParse(cp['latitude']?.toString() ?? '');
      final lng = double.tryParse(cp['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        routePoints.add(LatLng(lat, lng));
      }
    }

    if (widget.driverPosition != null) {
      routePoints.add(widget.driverPosition!);
    }

    if (widget.destinationPosition != null) {
      routePoints.add(widget.destinationPosition!);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.lautanindah.express.driver',
                ),

                // Polyline rute
                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 4.0,
                        color: AppTheme.primaryBlue.withValues(alpha: 0.8),
                      ),
                    ],
                  ),

                // Marker-marker lokasi
                MarkerLayer(
                  markers: [
                    // 1. Asal
                    if (widget.originPosition != null)
                      Marker(
                        point: widget.originPosition!,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.warehouse_rounded,
                          color: Color(0xFF16A34A),
                          size: 30,
                        ),
                      ),

                    // 2. Tujuan
                    if (widget.destinationPosition != null)
                      Marker(
                        point: widget.destinationPosition!,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.location_on,
                          color: AppTheme.dangerRed,
                          size: 34,
                        ),
                      ),

                    // 3. Posisi Driver Sekarang (Truk berkedip / pulsing icon)
                    if (widget.driverPosition != null)
                      Marker(
                        point: widget.driverPosition!,
                        width: 48,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryBlue,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Badge Info GPS & Akurasi Realtime di Atas Peta
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, size: 16, color: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.driverPosition != null
                                ? 'GPS Driver: ${widget.driverPosition!.latitude.toStringAsFixed(5)}, ${widget.driverPosition!.longitude.toStringAsFixed(5)}'
                                : 'Mencari sinyal GPS...',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkNavy,
                            ),
                          ),
                          Text(
                            widget.accuracy != null
                                ? 'Tingkat Akurasi: ±${widget.accuracy!.toStringAsFixed(1)} meter'
                                : 'Akurasi: Menunggu koordinat',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.center_focus_strong, size: 20),
                      color: AppTheme.primaryBlue,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Pusatkan ke Truk',
                      onPressed: () {
                        if (widget.driverPosition != null) {
                          _mapController.move(widget.driverPosition!, 14.0);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
