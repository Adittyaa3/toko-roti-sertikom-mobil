import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sertifikasitest/utils/custom_snackbar.dart';
import 'package:sertifikasitest/page/cart.dart'; // Pastikan path ini benar
import 'package:sertifikasitest/page/history.dart'; // Pastikan path ini benar

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  int _selectedIndex = 0;

  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  String? _userRole;
  bool get _isAdmin =>
      _userRole == 'admin'; // menu tambahakann kalo yang login adalah admin

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshData() async {
    if (mounted) setState(() => isLoading = true);
    await Future.wait([fetchProducts(), _fetchUserRole()]);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> fetchProducts() async {
    try {
      final response = await supabase
          .from('products')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      if (mounted)
        setState(() => products = List<Map<String, dynamic>>.from(response));
    } catch (error) {
      print('Error fetching products: $error');
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Gagal memuat produk.',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final response =
            await supabase
                .from('detail_users')
                .select('role')
                .eq('user_id', userId)
                .single();
        if (mounted) setState(() => _userRole = response['role']);
      }
    } catch (error) {
      if (mounted) {
        print('Error fetching user role: $error');
        CustomSnackBar.show(
          context,
          'Gagal memuat data pengguna.',
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildProductPage(),
      const HistoryPage(),
      const CartPage(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_getAppBarTitle(_selectedIndex)),
        backgroundColor: const Color(0xFFD58600),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFD58600),
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        elevation: 10,
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Toko Roti';
      case 1:
        return 'Riwayat Pesanan';
      case 2:
        return 'Keranjang Belanja';
      case 3:
        return 'Profil Saya';
      default:
        return 'Toko Roti';
    }
  }

  Widget _buildProductPage() {
    if (isLoading && products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD58600)),
      );
    }
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada produk yang tersedia',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return buildProductCard(product);
        },
      ),
    );
  }

  Widget buildProductCard(Map<String, dynamic> product) {
    return Card(
      color: Colors.white,
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                product['image_url'] ??
                    'https://via.placeholder.com/400x400.png?text=No+Image',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD58600)),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${(product['price'] ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD58600),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _addToCart(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD58600),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                        ),
                        child: const Text('Tambah ke Keranjang',
                        style: TextStyle(fontSize: 13),),
                      ),
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

  Widget _buildProfilePage() {
    final user = supabase.auth.currentUser;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.person_pin_circle_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            user?.email ?? 'Tidak ada email',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Role: ${_userRole ?? 'customer'}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const Spacer(),

          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin');
                },
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Admin Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2E35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          ElevatedButton.icon(
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // fetch ke cart
  Future<void> _addToCart(Map<String, dynamic> product) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted)
          CustomSnackBar.show(
            context,
            'Silakan login terlebih dahulu.',
            type: NotificationType.error,
          );
        return;
      }
      final cartResponse =
          await supabase
              .from('carts')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();
      String cartId;
      if (cartResponse == null) {
        final newCart =
            await supabase
                .from('carts')
                .insert({'user_id': userId})
                .select('id')
                .single();
        cartId = newCart['id'];
      } else {
        cartId = cartResponse['id'];
      }
      final existingCartItem =
          await supabase
              .from('cart_items')
              .select('id, quantity')
              .eq('cart_id', cartId)
              .eq('product_id', product['id'])
              .maybeSingle();
      if (existingCartItem != null) {
        await supabase
            .from('cart_items')
            .update({'quantity': existingCartItem['quantity'] + 1})
            .eq('id', existingCartItem['id']);
      } else {
        await supabase.from('cart_items').insert({
          'cart_id': cartId,
          'product_id': product['id'],
          'quantity': 1,
          'price_at_add': product['price'],
        });
      }
      if (mounted)
        CustomSnackBar.show(
          context,
          'Berhasil menambahkan ${product['name']}',
          type: NotificationType.success,
        );
    } catch (error) {
      print('Error adding to cart: $error');
      if (mounted)
        CustomSnackBar.show(
          context,
          'Gagal menambahkan ke keranjang.',
          type: NotificationType.error,
        );
    }
  }
}
