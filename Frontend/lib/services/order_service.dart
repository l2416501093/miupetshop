import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../main.dart';

class OrderService {
  // Sipariş oluşturma API çağrısı
  static Future<Map<String, dynamic>> createOrder({
    required String deliveryAddress,
    required String billingAddress,
  }) async {
    try {
      print('📦 Sipariş oluşturuluyor...');
      
      // Kullanıcı bilgilerini al
      final userData = await AuthService.getUserData();
      if (userData == null) {
        return {
          'success': false,
          'message': 'Kullanıcı bilgileri bulunamadı!',
        };
      }

      // Sepet boş mu kontrol et
      if (MyApp.cart.isEmpty) {
        return {
          'success': false,
          'message': 'Sepetinizde ürün bulunmuyor!',
        };
      }

      // Sipariş numarası oluştur
      final orderNumber = 'SP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      
      // Fiyat hesaplamaları
      double subtotal = 0;
      List<Map<String, dynamic>> orderItems = [];
      
      for (var item in MyApp.cart) {
        final quantity = (item['quantity'] ?? 1);
        final unitPrice = (item['price'] ?? 0.0).toDouble();
        final totalPrice = unitPrice * quantity;
        subtotal += totalPrice;
        
        orderItems.add({
          'productId': item['id'] ?? '',
          'productName': item['name'] ?? 'Ürün',
          'productImage': item['image'] ?? '',
          'quantity': quantity,
          'unitPrice': unitPrice,
          'totalPrice': totalPrice,
          'category': _getCategoryFromName(item['name'] ?? ''),
        });
      }
      
      final tax = subtotal * 0.18; // %18 KDV
      final shipping = subtotal > 200 ? 0.0 : 25.0; // 200 TL üzeri ücretsiz kargo
      final total = subtotal + tax + shipping;

      // API'ye gönderilecek sipariş verisi
      final orderData = {
        'orderNumber': orderNumber,
        'orderDate': DateTime.now().toIso8601String(),
        'orderStatus': 'pending',
        
        'customer': {
          'userId': userData['Id']?.toString() ?? '',
          'username': userData['Username'] ?? '',
          'email': userData['Email'] ?? '',
          'phone': userData['Phone'] ?? ''
        },
        
        'addresses': {
          'delivery': {
            'fullAddress': deliveryAddress,
            'city': _extractCity(deliveryAddress),
            'district': _extractDistrict(deliveryAddress),
            'postalCode': '',
            'country': 'Turkey'
          },
          'billing': {
            'fullAddress': billingAddress,
            'city': _extractCity(billingAddress),
            'district': _extractDistrict(billingAddress),
            'postalCode': '',
            'country': 'Turkey'
          }
        },
        
        'items': orderItems,
        
        'pricing': {
          'subtotal': subtotal,
          'tax': tax,
          'shipping': shipping,
          'discount': 0.0,
          'total': total,
          'currency': 'TRY'
        },
        
        'payment': {
          'method': 'bank_transfer',
          'status': 'pending',
          'transactionId': null,
          'paidAmount': 0.0,
          'paymentDate': null
        },
        
        'shipping': {
          'method': 'standard',
          'trackingNumber': null,
          'estimatedDelivery': DateTime.now().add(Duration(days: 5)).toIso8601String(),
          'actualDelivery': null,
          'carrier': 'Aras Kargo'
        },
        
        'timeline': [
          {
            'status': 'pending',
            'date': DateTime.now().toIso8601String(),
            'note': 'Order created'
          }
        ],
        
        'notes': {
          'customerNote': '',
          'adminNote': '',
          'deliveryNote': ''
        },
        
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': true,
        'isDeleted': false
      };

      print('📋 Sipariş verisi: ${jsonEncode(orderData)}');

      // API çağrısı
      final response = await http.post(
        Uri.parse(ApiConfig.ordersEndpoint),
        headers: await AuthService.getAuthHeaders(),
        body: jsonEncode(orderData),
      ).timeout(ApiConfig.requestTimeout);

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Başarılı sipariş
        final responseData = jsonDecode(response.body);
        print('📡 RESPONSE DATA::::::: $responseData');
        return {
          'success': true,
          'data': responseData,
          'orderNumber': responseData['orderNumber'],
          'total': total,
          'message': 'Siparişiniz başarıyla oluşturuldu!'
        };
      } else if (response.statusCode == 400) {
        // Bad Request
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Sipariş bilgilerinde hata var!',
            'statusCode': response.statusCode
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Sipariş bilgilerinde hata var!',
            'statusCode': response.statusCode
          };
        }
      } else if (response.statusCode == 401) {
        // Unauthorized
        return {
          'success': false,
          'message': 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın!',
          'statusCode': response.statusCode
        };
      } else {
        // Diğer hatalar
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Sipariş oluşturulurken bir hata oluştu!',
            'statusCode': response.statusCode
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Sunucu hatası! Status Code: ${response.statusCode}',
            'statusCode': response.statusCode
          };
        }
      }
    } catch (e) {
      print('🚨 Sipariş oluşturma hatası: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
        'error': e.toString()
      };
    }
  }

  // Yardımcı fonksiyonlar
  static String _getCategoryFromName(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('köpek') || name.contains('dog')) return 'Köpek';
    if (name.contains('kedi') || name.contains('cat')) return 'Kedi';
    if (name.contains('kuş') || name.contains('bird')) return 'Kuş';
    if (name.contains('balık') || name.contains('fish')) return 'Balık';
    return 'Diğer';
  }

  static String _extractCity(String address) {
    // Basit şehir çıkarma (örnek: "Kadıköy/İstanbul" -> "İstanbul")
    if (address.contains('/')) {
      return address.split('/').last.trim();
    }
    return 'İstanbul'; // Default
  }

  static String _extractDistrict(String address) {
    // Basit ilçe çıkarma (örnek: "Kadıköy/İstanbul" -> "Kadıköy")
    if (address.contains('/')) {
      final parts = address.split('/');
      if (parts.length >= 2) {
        return parts[parts.length - 2].split(',').last.trim();
      }
    }
    return ''; // Default
  }
} 