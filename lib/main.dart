import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sertifikasitest/ui/auth/register.dart';
import 'package:sertifikasitest/page/home.dart';
import 'package:sertifikasitest/page/cart.dart';
import 'package:sertifikasitest/page/checkout.dart';
import 'package:sertifikasitest/page/history.dart';
import 'package:sertifikasitest/ui/auth/login.dart';
import 'package:sertifikasitest/admin/dashboard.dart'; // Pastikan path ini benar
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rrwtggobdufbfxggcskw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJyd3RnZ29iZHVmYmZ4Z2djc2t3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU1NjMzMTcsImV4cCI6MjA2MTEzOTMxN30.uiKZbElg0uiEj_ID3oL2DOzzgJqwYFYJifkjNGpbuK8',
  );

  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.black,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
      ),
      // HAPUS properti 'home: AuthWrapper()' yang lama
      
      // GANTIKAN DENGAN STREAMBUILDER INI
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // Selama koneksi pertama atau saat memproses, tampilkan loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Jika pengguna sudah login (memiliki session yang valid)
          if (snapshot.hasData && snapshot.data?.session != null) {
            return const HomePage();
          }

          // Jika pengguna belum login atau sudah logout, arahkan ke halaman Login
          return const LoginScreen();
        },
      ),
      // Rute lain tetap sama
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomePage(),
        '/cart': (context) => const CartPage(),
        // PERINGATAN: Rute checkout ini masih berpotensi error karena datanya statis.
        // Sebaiknya gunakan `onGenerateRoute` atau `Navigator.push` seperti yang didiskusikan sebelumnya.
        '/checkout': (context) => const CheckoutPage(cartItems: [], totalPrice: 0.0),
        '/history': (context) => const HistoryPage(),
        '/admin': (context) => const AdminDashboardPage(),
      },
    );
  }
}

// HAPUS SELURUH CLASS AuthWrapper DI BAWAH INI KARENA SUDAH TIDAK DIPERLUKAN
/*
  class AuthWrapper extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        // Cek apakah pengguna sudah login
        final user = Supabase.instance.client.auth.currentUser;
        // Jika pengguna sudah login, arahkan ke HomeScreen
        if (user != null) {
          return const HomePage();
        }
        return const RegisterScreen();
      }
    }
*/