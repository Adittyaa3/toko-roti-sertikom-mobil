import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:sertifikasitest/utils/custom_snackbar.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.totalPrice,
  });

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  Position? _currentPosition;


  final _receiverNameController = TextEditingController();
  final _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);







  @override
  void initState() {
    super.initState();
    _initializePage();
  }




  @override
  void dispose() {
    _receiverNameController.dispose();
    super.dispose();
  }






  Future<void> _initializePage() async {
    setState(() => _isLoading = true);
    await _fetchUserDetails();
    await _getCurrentLocation();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }





  Future<void> _fetchUserDetails() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final userDetail = await supabase
          .from('detail_users')
          .select('nama_lengkap') // Hanya butuh nama lengkap
          .eq('user_id', userId)
          .single();

      if (mounted) {
        _receiverNameController.text = userDetail['nama_lengkap'] ?? '';
      }
    } catch (e) {
      print('Error fetching user details: $e');
      if (mounted) {
        CustomSnackBar.show(context, 'Gagal memuat detail pengguna.', type: NotificationType.error);
      }
    }
  }






  Future<void> _getCurrentLocation() async {
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if(mounted) CustomSnackBar.show(context, 'Layanan lokasi tidak aktif.', type: NotificationType.error);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if(mounted) CustomSnackBar.show(context, 'Izin lokasi ditolak untuk pengiriman.', type: NotificationType.info);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if(mounted) CustomSnackBar.show(context, 'Izin lokasi ditolak permanen.', type: NotificationType.error);
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _currentPosition = position);
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        CustomSnackBar.show(context, 'Gagal mendapatkan lokasi. Pastikan GPS aktif.', type: NotificationType.error);
      }
    }
  }








  Future<void> _confirmOrder() async {
    
    if (_receiverNameController.text.isEmpty) {
      CustomSnackBar.show(context, 'Nama Penerima tidak boleh kosong.', type: NotificationType.error);
      return;
    }
    
    if (_currentPosition == null) {
      CustomSnackBar.show(context, 'Lokasi tidak ditemukan. Mohon aktifkan GPS.', type: NotificationType.error);
      return;
    }

    try {
      setState(() => _isLoading = true);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

    
    
      final FinalAddres = '${_currentPosition!.latitude.toStringAsFixed(6)},  ${_currentPosition!.longitude.toStringAsFixed(6)}';


      final orderData = {
        'user_id': userId,
        'total_amount': widget.totalPrice,
        'status': 'pending',
        'receiver_name': _receiverNameController.text,
        'receiver_phone': '-', 
        'delivery_address': FinalAddres, 
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      };




      final orderResponse = await supabase.from('orders').insert(orderData).select('id').single();
      final orderId = orderResponse['id'];

      final orderItems = widget.cartItems.map((item) {
        final productData = item['products'] as Map<String, dynamic>? ?? {};
        final price = productData['price'] ?? item['price_at_add'] ?? 0;
        return {
          'order_id': orderId,
          'product_id': item['product_id'],
          'quantity': item['quantity'] ?? 1,
          'price_at_purchase': price,
        };
      }).toList();
      await supabase.from('order_items').insert(orderItems);
      
      final cartResponse = await supabase.from('carts').select('id').eq('user_id', userId).maybeSingle();
      if (cartResponse != null) {
        await supabase.from('cart_items').delete().eq('cart_id', cartResponse['id']);
      }

      if (mounted) {
        CustomSnackBar.show(context, 'Pesanan berhasil ditempatkan!', type: NotificationType.success);
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      print('Error confirming order: $e');
      if (mounted) {
        CustomSnackBar.show(context, 'Gagal mengkonfirmasi pesanan. Coba lagi.', type: NotificationType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Konfirmasi Pesanan'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A2E35),
        elevation: 1,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD58600)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Ringkasan Pesanan'),
                  _buildOrderSummaryCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Detail Pengiriman'),
                  _buildDeliveryDetailsCard(),
                ],
              ),
            ),
       bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E35))),
    );
  }




  Widget _buildOrderSummaryCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.cartItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = widget.cartItems[index];
          final productData = item['products'] as Map<String, dynamic>? ?? {};
          final productName = productData['name'] ?? 'Produk Telah Dihapus';
          final quantity = item['quantity'] ?? 1; // Fallback jika quantity null
          final price = productData['price'] ?? item['price_at_add'] ?? 0;
          final itemTotal = quantity * price;

          return ListTile(
             title: Text(productName),
             subtitle: Text('x $quantity'),
             trailing: Text(_currencyFormatter.format(itemTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
             tileColor: productData.isEmpty ? Colors.red.withOpacity(0.05) : null,
          );
        },
      ),
    );
  }





  Widget _buildDeliveryDetailsCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HANYA MENAMPILKAN NAMA PENERIMA
            _buildTextField(_receiverNameController, 'Nama Penerima', Icons.person_outline),
            const SizedBox(height: 16),
            // Menampilkan status deteksi GPS
            Row(
              children: [
                Icon(Icons.gps_fixed, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lokasi GPS: ${_currentPosition != null ? "Terdeteksi" : "Mencari..."}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }






   Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFD58600), width: 2),
        ),
      ),
    );
  }





  Widget _buildBottomBar() {
    // ... (Fungsi ini tidak perlu diubah)
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 0, blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(
                _currencyFormatter.format(widget.totalPrice),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD58600)),
              ),
            ],
          ),



          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _confirmOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD58600),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Konfirmasi & Bayar'),
            ),
          ),
        ],
      ),
    );
  }
}