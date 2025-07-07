import 'package:flutter/material.dart';
import '../main.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatelessWidget {
  CheckoutScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cardController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ödeme')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Ad Soyad'),
              ),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Adres'),
              ),
              TextFormField(
                controller: cardController,
                decoration: InputDecoration(labelText: 'Kart Numarası'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Sepeti temizle
                  MyApp.cart.clear();

                  if (_formKey.currentState!.validate()) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderConfirmationScreen(
                          deliveryAddress: addressController.text,
                          billingAddress: addressController.text,
                        ),
                      ),
                    );
                  }
                },
                child: Text('Ödemeyi Tamamla',style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
