import 'package:flutter/material.dart';
import '../models/delivery_model.dart';
import '../services/mock_data_service.dart';
import 'delivery_detail_screen.dart';
import 'handover_screen.dart';

class DeliveriesTab extends StatefulWidget {
  const DeliveriesTab({super.key});

  @override
  State<DeliveriesTab> createState() => _DeliveriesTabState();
}

class _DeliveriesTabState extends State<DeliveriesTab> {
  final MockDataService _service = MockDataService();
  String _filter = 'Semua';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final allOrders = _service.deliveries;

        final filteredOrders = allOrders.where((d) {
          final matchesSearch = d.suratJalanNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.resiNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.destinationWarehouse.toLowerCase().contains(_searchQuery.toLowerCase());

          if (!matchesSearch) return false;

          if (_filter == 'Aktif') {
            return d.status == DeliveryStatus.departed || d.status == DeliveryStatus.inTransit || d.status == DeliveryStatus.arrived;
          } else if (_filter == 'Menunggu') {
            return d.status == DeliveryStatus.waiting;
          } else if (_filter == 'Selesai') {
            return d.status == DeliveryStatus.completed;
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Penugasan Surat Jalan', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Search & Filter header
              Container(
                color: const Color(0xFF0F172A),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Cari No. Surat Jalan / Resi / Tujuan...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Semua', 'Aktif', 'Menunggu', 'Selesai'].map((f) {
                          final isSelected = _filter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(f, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
                              selected: isSelected,
                              selectedColor: const Color(0xFF38BDF8),
                              backgroundColor: Colors.white.withOpacity(0.12),
                              onSelected: (_) {
                                setState(() {
                                  _filter = f;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Deliveries List
              Expanded(
                child: filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Tidak ada Surat Jalan dalam kategori ini', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final isCompleted = order.status == DeliveryStatus.completed;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => DeliveryDetailScreen(deliveryId: order.id),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: order.statusColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            order.statusLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: order.statusColor,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          order.resiNumber,
                                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.blueGrey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      order.suratJalanNumber,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${order.routeType} • ${order.totalExpectedKoli} Koli Total Muatan',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      children: [
                                        const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Tujuan: ${order.destinationWarehouse}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => DeliveryDetailScreen(deliveryId: order.id),
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                              foregroundColor: const Color(0xFF0F172A),
                                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                                            ),
                                            child: const Text('Detail & Checkpoint'),
                                          ),
                                        ),
                                        if (!isCompleted) ...[
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => HandoverScreen(delivery: order),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                visualDensity: VisualDensity.compact,
                                                backgroundColor: const Color(0xFF10B981),
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Bongkar / BAST'),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
