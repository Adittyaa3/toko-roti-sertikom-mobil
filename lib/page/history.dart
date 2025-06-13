import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );





  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }






  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan login untuk melihat riwayat pesanan Anda')),
          );
          Navigator.pushReplacementNamed(context, '/register');
        }
        return;
      }

      final response = await supabase
          .from('orders')
          .select(
            'id, total_amount, receiver_name, receiver_phone, delivery_address, created_at, order_items(quantity, price_at_purchase, products(name, image_url))',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat riwayat pesanan: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }









  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD58600)),
            )
          : _orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Belum Ada Pesanan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Setelah Anda melakukan pembelian, riwayat pesanan akan muncul di sini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'Poppins',
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final orderId = order['id'];
                    final totalAmount = (order['total_amount'] as num).toDouble();
                    final receiverName = order['receiver_name'] ?? 'N/A';
                    final deliveryAddress = order['delivery_address'] ?? 'N/A';
                    final createdAt = DateTime.parse(order['created_at']);
                    final orderItems = List<Map<String, dynamic>>.from(order['order_items'] ?? []);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order ID: #$orderId',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy, HH:mm').format(createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16, thickness: 0.5),
                            Text(
                              'Total Pembayaran: ${_currencyFormatter.format(totalAmount)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                color: Color(0xFFD58600),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Penerima: $receiverName',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Color(0xFF555555),
                              ),
                            ),
                            Text(
                              'Alamat: $deliveryAddress',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Color(0xFF555555),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Detail Barang:',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: Color(0xFF1A2E35),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: orderItems.map((item) {
                                final productName = item['products']['name'] ?? 'Unknown Product';
                                final quantity = item['quantity'];
                                final price = (item['price_at_purchase'] as num).toDouble();
                                final itemTotal = quantity * price;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$productName x $quantity',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Poppins',
                                            color: Colors.grey[700],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        _currencyFormatter.format(itemTotal),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Poppins',
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}