import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sertifikasitest/page/checkout.dart';
import 'package:intl/intl.dart';
import 'package:sertifikasitest/utils/custom_snackbar.dart'; // Import helper notifikasi

class CartPage extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  const CartPage({super.key, this.onNavigateToHome});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          CustomSnackBar.show(
            context,
            'Silakan login untuk melihat keranjang Anda',
            type: NotificationType.info,
          );
        }
        return;
      }

      final cartResponse =
          await Supabase.instance.client
              .from('carts')
              .select('id')
              .eq('user_id', user.id)
              .maybeSingle();

      if (cartResponse == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _cartItems = [];
          });
        }
        return;
      }

      final cartId = cartResponse['id'];

      // Query ini mengambil semua data dari cart_items DAN semua data dari products yang berelasi
      final response = await Supabase.instance.client
          .from('cart_items')
          .select('*, products(*)')
          .eq('cart_id', cartId)
          .order('id', ascending: true);

      if (mounted) {
        setState(() {
          // Gunakan hasil dari Supabase secara langsung, jangan diubah strukturnya
          _cartItems = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackBar.show(
          context,
          'Gagal memuat keranjang: ${e.toString()}',
          type: NotificationType.error,
        );
        print('Error fetching cart items: $e');
      }
    }
  }

  Future<void> _removeCartItem(String cartItemId) async {
    try {
      await Supabase.instance.client
          .from('cart_items')
          .delete()
          .eq('id', cartItemId);
      // Panggil ulang untuk refresh data
      await _fetchCartItems();
      if (mounted)
        CustomSnackBar.show(
          context,
          'Item berhasil dihapus',
          type: NotificationType.success,
        );
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Gagal menghapus item: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  double _calculateTotalPrice() {
    if (_cartItems.isEmpty) return 0.0;
    return _cartItems.fold(0.0, (total, item) {
      // Ambil harga dari nested object 'products' jika ada, jika tidak, gunakan harga saat ditambahkan
      final productData = item['products'] as Map<String, dynamic>?;
      final price =
          (productData?['price'] as num?)?.toDouble() ??
          (item['price_at_add'] as num?)?.toDouble() ??
          0.0;
      final quantity = (item['quantity'] as int?) ?? 0;
      return total + (price * quantity);
    });
  }

  Future<void> _updateQuantity(
    String cartItemId,
    int newQuantity,
    int stock,
  ) async {
    if (newQuantity <= 0) {
      await _removeCartItem(cartItemId);
      return;
    }
    if (newQuantity > stock) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Kuantitas melebihi stok yang tersedia (Stok: $stock)',
          type: NotificationType.info,
        );
      }
      return;
    }

    try {
      await Supabase.instance.client
          .from('cart_items')
          .update({'quantity': newQuantity})
          .eq('id', cartItemId);
      await _fetchCartItems(); // Refresh list
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Gagal memperbarui kuantitas: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFD58600)),
              )
              : _cartItems.isEmpty
              ? _buildEmptyCartMessage()
              : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        // --- CARA MENGAKSES DATA DIPERBAIKI DI SINI ---
                        final product =
                            item['products'] as Map<String, dynamic>? ?? {};

                        return ProductCard(
                          name: product['name'] ?? 'Produk Dihapus',
                          imageUrl: product['image_url'] as String?,
                          quantity: item['quantity'] as int,
                          price:
                              (product['price'] as num?)?.toDouble() ??
                              (item['price_at_add'] as num?)?.toDouble() ??
                              0.0,
                          description: product['description'] as String?,
                          stock: product['stock'] ?? 0,
                          cartItemId: item['id'] as String,
                          onDelete: () => _removeCartItem(item['id'] as String),
                          onQuantityChanged: (newQuantity) {
                            _updateQuantity(
                              item['id'] as String,
                              newQuantity,
                              product['stock'] ?? 0,
                            );
                          },
                          currencyFormatter: _currencyFormatter,
                        );
                      },
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 12),
                    ),
                  ),
                  _buildSummaryAndCheckout(),
                ],
              ),
    );
  }

  Widget _buildEmptyCartMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'Keranjang Anda Masih Kosong',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Ayo tambahkan produk favoritmu!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD58600),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed:
                () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            label: const Text('Kembali Belanja'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndCheckout() {
    final totalPrice = _calculateTotalPrice();
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pesanan:',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
              Text(
                _currencyFormatter.format(totalPrice),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD58600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD58600),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed:
                  _cartItems.isEmpty
                      ? null
                      : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => CheckoutPage(
                                  cartItems: _cartItems,
                                  totalPrice: totalPrice,
                                ),
                          ),
                        );
                      },
              child: const Text('Lanjut ke Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final int quantity;
  final double price;
  final String? description;
  final int stock;
  final String cartItemId;
  final VoidCallback onDelete;
  final Function(int) onQuantityChanged;
  final NumberFormat currencyFormatter;

  const ProductCard({
    super.key,
    required this.name,
    this.imageUrl,
    required this.quantity,
    required this.price,
    this.description,
    required this.stock,
    required this.cartItemId,
    required this.onDelete,
    required this.onQuantityChanged,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(cartItemId),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDelete(),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                imageUrl ?? 'https://via.placeholder.com/150',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported, size: 80),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(price),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => onQuantityChanged(quantity - 1),
                ),
                Text(
                  quantity.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                  onPressed: () => onQuantityChanged(quantity + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
