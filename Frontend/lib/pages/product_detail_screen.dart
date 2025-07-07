import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../main.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isAdmin = false;
  late Product _currentProduct; // Güncel ürün bilgilerini tutmak için
  bool _wasUpdated = false; // Ürün güncellenip güncellenmediğini takip etmek için

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product; // Başlangıçta widget'tan gelen ürünü kullan
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AuthService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  // Ürün bilgilerini API'den yenile
  Future<void> _refreshProductData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.productsEndpoint}/${_currentProduct.id}'),
        headers: await AuthService.getAuthHeaders(),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final productJson = jsonDecode(response.body);
        setState(() {
          _currentProduct = Product.fromJson(productJson);
          _wasUpdated = true; // Güncelleme başarılı olduğunu işaretle
        });
        print('✅ Ürün bilgileri güncellendi: ${_currentProduct.name}');
      } else {
        print('⚠️ Ürün bilgileri güncellenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('🚨 Ürün bilgileri yenileme hatası: $e');
    }
  }

  // Ürün silme onay dialogu
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Ürünü Sil'),
            ],
          ),
          content: Text(
            'Bu ürünü silmek istiyor musunuz?\n\nBu işlem geri alınamaz.',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'İptal',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Sil'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct();
              },
            ),
          ],
        );
      },
    );
  }

  // Ürün silme fonksiyonu
  Future<void> _deleteProduct() async {
    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Ürün siliniyor...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.productsEndpoint}/${_currentProduct.id}'),
        headers: await AuthService.getAuthHeaders(),
      ).timeout(ApiConfig.requestTimeout);

      // Loading dialog'u kapat
      Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Başarılı silme
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ürün başarıyla silindi!',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );

        // Ana sayfaya yönlendir
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      } else {
        // Hata durumu
        String errorMessage = 'Ürün silinemedi!';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          // JSON parse hatası, varsayılan mesajı kullan
        }

        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      // Loading dialog'u kapat
      Navigator.pop(context);
      
      // Hata mesajı göster
      _showErrorDialog('Ürün silinemedi: ${e.toString()}');
    }
  }

  // Hata dialog'u
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Hata'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context) {
    // Aynı ürün sepette varsa quantity arttır
    final existingProduct = MyApp.cart.firstWhere(
          (item) => item['name'] == _currentProduct.name,
      orElse: () => {},
    );

    if (existingProduct.isNotEmpty) {
      existingProduct['quantity'] += 1;
    } else {
      Map<String, dynamic> newItem = {
        'name': _currentProduct.name,
        'image': _currentProduct.imageUrl,
        'quantity': 1,
        'id': _currentProduct.id, // API'den gelen id'yi de ekleyelim
        'price': _currentProduct.hasDiscount ? _currentProduct.discountedPrice : _currentProduct.price, // İndirimli fiyat varsa onu kullan
        'originalPrice': _currentProduct.price, // Orijinal fiyatı da sakla
        'discount': _currentProduct.discount, // İndirim oranını sakla
      };
      MyApp.cart.add(newItem);
    }

    // Kullanıcıya modern mesaj göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_currentProduct.name} sepete eklendi!',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context, _wasUpdated),
        ),
        title: Text(
          _currentProduct.name,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          // Admin için ürün silme butonu
          if (_isAdmin)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red.shade600),
              onPressed: () => _showDeleteConfirmationDialog(),
              tooltip: 'Ürünü Sil',
            ),
          // Admin için ürün düzenleme butonu
          if (_isAdmin)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.black87),
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context, 
                  '/edit_product',
                  arguments: _currentProduct,
                );
                // Düzenleme sayfasından döndükten sonra ürün bilgilerini yenile
                if (result == true) { // Başarılı güncelleme durumunda
                  await _refreshProductData();
                }
              },
              tooltip: 'Ürünü Düzenle',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ürün Görseli
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 350,
                    width: double.infinity,
                    color: Colors.white,
                    child: Image.network(
                      _currentProduct.imageUrl,
                      height: 350,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 350,
                          width: double.infinity,
                          color: Colors.grey.shade100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, size: 64, color: Colors.grey.shade400),
                              SizedBox(height: 8),
                              Text(
                                'Görsel yüklenemedi',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 350,
                          width: double.infinity,
                          color: Colors.grey.shade100,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.deepPurple,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                                                );
                      },
                    ),
                  ),
                ),
              ),
              
              // Ürün Bilgileri Kartı
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ürün Adı
                    Text(
                      _currentProduct.name,
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Fiyat bölümü
                    if (_currentProduct.hasDiscount) ...[
                      // İndirimli fiyat gösterimi
                      Row(
                        children: [
                          // İndirimli fiyat
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₺${_currentProduct.discountedPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          // İndirim yüzdesi
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '%${_currentProduct.discount.toInt()} İNDİRİM',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Orijinal fiyat (üstü çizili)
                      Text(
                        'Orijinal Fiyat: ₺${_currentProduct.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.grey.shade600,
                        ),
                      ),
                    ] else ...[
                      // Normal fiyat
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₺${_currentProduct.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Açıklama Kartı
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, color: Colors.deepPurple, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Ürün Açıklaması',
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    Text(
                      _currentProduct.description.isNotEmpty 
                          ? _currentProduct.description
                          : 'Bu ürün için henüz detaylı açıklama eklenmemiş.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    
                    // Ürün ID (Debug için)
                    if (_currentProduct.id != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tag, size: 16, color: Colors.grey.shade600),
                            SizedBox(width: 4),
                                                          Text(
                                'ID: ${_currentProduct.id}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Özellikler Kartı
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Ürün Özellikleri',
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    _buildFeatureItem('Kaliteli malzemeler', Icons.star),
                    _buildFeatureItem('Güvenli ve sağlıklı', Icons.health_and_safety),
                    _buildFeatureItem('Pet shop kalitesi', Icons.pets),
                    _buildFeatureItem('Hızlı teslimat', Icons.local_shipping),
                  ],
                ),
              ),
              
              SizedBox(height: 100), // Bottom button için yer
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _addToCart(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Sepete Ekle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.green.shade600,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
