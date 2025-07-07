import 'package:flutter/material.dart';
import '../main.dart';
import '../pages/add_product_screen.dart'; // cart verisi için erişim

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  int getTotalQuantity() {
    int total = 0;
    for (var item in MyApp.cart) {
      total += item['quantity'] as int;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    int totalQuantity = getTotalQuantity();

    return AppBar(
      title: Text(title),
        actions: [
          // Artı butonu
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddProductScreen()),
              );
            },
          ),

          // Sepet ikonu
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              ),
              if (MyApp.cart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${MyApp.cart.length}',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
    );
  }
}
