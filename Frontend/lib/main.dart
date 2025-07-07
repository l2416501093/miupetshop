import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shoppy/pages/add_product_screen.dart';
import 'package:shoppy/models/product_model.dart';
import 'package:shoppy/pages/cart_screen.dart';
import 'package:shoppy/pages/home_screen.dart';
import 'package:shoppy/pages/login_screen.dart';
import 'package:shoppy/pages/sign_up_screen.dart';
import 'package:shoppy/pages/splash_screen.dart';
import 'package:shoppy/pages/profile_screen.dart';
import 'package:shoppy/pages/settings_screen.dart';
import 'package:shoppy/pages/help_screen.dart';

import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter sistemini hazırlar

  // Hive'i Flutter'a özgü olarak başlat
  await Hive.initFlutter();

  // UserModel adapter'ını kaydet
  Hive.registerAdapter(UserModelAdapter());

  // 'users' kutusunu aç
  await Hive.openBox<UserModel>('users');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static List<Map<String, dynamic>> cart = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shoppy',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signUp': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
        '/cart': (context) => CartScreen(),
        '/add_product': (context) => AddProductScreen(),
        '/profile': (context) => ProfileScreen(),
        '/settings': (context) => SettingsScreen(),
        '/help': (context) => HelpScreen(),
      },
      onGenerateRoute: (settings) {
        // Ürün düzenleme route'u için
        if (settings.name == '/edit_product') {
          final product = settings.arguments as Product;
          return MaterialPageRoute(
            builder: (context) => AddProductScreen(productToEdit: product),
          );
        }
        return null;
      },
    );
  }
}