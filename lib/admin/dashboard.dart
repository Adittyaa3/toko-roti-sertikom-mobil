import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrdersWithDetails();
  }

 
  Future<void> _fetchOrdersWithDetails() async {
    
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('orders')
          .select(
            '*, '
            'detail_users(nama_lengkap), ' 
            'order_items(*, products(name))' 
          )
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengambil data pesanan: $error'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }


  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan Pelanggan'),
        backgroundColor: const Color(0xFFD58600),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDetailedOrderList(),
    );
  }



  
  Widget _buildDetailedOrderList() {
    if (_orders.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada pesanan yang masuk.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrdersWithDetails,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          final customerName =
              order['detail_users']?['nama_lengkap'] ?? 'User tidak ditemukan';
          final List<dynamic> orderItems = order['order_items'] ?? [];

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              // ExpansionTile agar bisa di-klik untuk lihat detail item
              title: Text(
                'Pesanan oleh: $customerName',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order['total_amount'])}',
              ),
              trailing: _buildStatusChip(order['status']),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('ID Pesanan:', order['id']),
                      _buildDetailRow('Tanggal:', DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(DateTime.parse(order['created_at']))),
                      _buildDetailRow('Alamat:', order['delivery_address'] ?? '-'),
                      _buildDetailRow('Telepon:', order['receiver_phone'] ?? '-'),
                      const Divider(height: 20),
                      const Text(
                        'Detail Item:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Loop untuk menampilkan setiap item dalam pesanan
                      if (orderItems.isNotEmpty)
                        ...orderItems.map((item) {
                          final productName = item['products']?['name'] ?? 'Produk tidak ditemukan';
                          return ListTile(
                            dense: true,
                            title: Text(productName),
                            subtitle: Text('Jumlah: ${item['quantity']}'),
                            trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item['price_at_purchase'])),
                          );
                        }).toList()
                      else
                        const Text('Detail item tidak tersedia.'),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }



  // untuk baris
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90, // Lebar tetap untuk label
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Helper widget untuk status chip dengan warna yang berbeda
  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText;
    switch (status) {
      case 'pending':
        chipColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'processing':
        chipColor = Colors.blue;
        statusText = 'Diproses';
        break;
      case 'delivered':
        chipColor = Colors.green;
        statusText = 'Terkirim';
        break;
      case 'canceled':
        chipColor = Colors.red;
        statusText = 'Dibatalkan';
        break;
      default:
        chipColor = Colors.grey;
        statusText = status;
    }
    return Chip(
      label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }
}
