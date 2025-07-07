import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class AddProductScreen extends StatefulWidget {
  final Product? productToEdit; // null ise yeni ürün, değilse düzenleme

  const AddProductScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    // Düzenleme modunda ise mevcut ürün bilgilerini yükle
    if (widget.productToEdit != null) {
      _isEditMode = true;
      _loadProductData();
    }

    _animationController.forward();
  }

  void _loadProductData() {
    final product = widget.productToEdit!;
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _imageUrlController.text = product.imageUrl;
    _priceController.text = product.price.toString();
    _discountController.text = product.discount.toString();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Admin yetkisi kontrolü
    final hasPermission = await AuthService.checkAdminPermission();
    if (!hasPermission) {
      _showErrorDialog('Yetki Hatası', 'Bu işlem için admin yetkisi gereklidir.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image': _imageUrlController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'discount': double.parse(_discountController.text.trim().isEmpty ? '0' : _discountController.text.trim()),
        'discountPercentage': double.parse(_discountController.text.trim().isEmpty ? '0' : _discountController.text.trim()), // API farklı field kullanıyor olabilir
      };

      http.Response response;
      
      if (_isEditMode) {
        // Ürün güncelleme
        response = await http.put(
          Uri.parse('${ApiConfig.productsEndpoint}/${widget.productToEdit!.id}'),
          headers: {
            'Content-Type': 'application/json',
            ...await AuthService.getAuthHeaders(),
          },
          body: jsonEncode(productData),
        ).timeout(ApiConfig.requestTimeout);
      } else {
        // Yeni ürün ekleme
        response = await http.post(
          Uri.parse(ApiConfig.productsEndpoint),
          headers: {
            'Content-Type': 'application/json',
            ...await AuthService.getAuthHeaders(),
          },
          body: jsonEncode(productData),
        ).timeout(ApiConfig.requestTimeout);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        final errorMsg = _getErrorMessage(response.statusCode);
        _showErrorDialog('İşlem Başarısız', errorMsg);
      }
    } catch (e) {
      _showErrorDialog('Bağlantı Hatası', 'Sunucuya bağlanılamadı: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Geçersiz ürün bilgileri. Lütfen tüm alanları doğru şekilde doldurun.';
      case 401:
        return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
      case 403:
        return 'Bu işlem için yetkiniz bulunmuyor.';
      case 404:
        return 'Ürün bulunamadı.';
      case 409:
        return 'Bu isimde bir ürün zaten mevcut.';
      case 500:
        return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
      default:
        return 'Beklenmeyen bir hata oluştu (Kod: $statusCode)';
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text(_isEditMode ? 'Güncelleme Başarılı' : 'Ekleme Başarılı'),
          ],
        ),
        content: Text(
          _isEditMode 
            ? 'Ürün bilgileri başarıyla güncellendi.'
            : 'Yeni ürün başarıyla eklendi.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialog'u kapat
              Navigator.of(context).pop(true); // Bu sayfayı kapat ve başarı durumunu döndür
            },
            child: Text('Tamam', style: TextStyle(color: Colors.purple.shade600)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
                 actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: Text('Tamam', style: TextStyle(color: Colors.purple.shade600)),
           ),
         ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required String? Function(String?) validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
               boxShadow: [
         BoxShadow(
           color: Colors.purple.withOpacity(0.06),
           blurRadius: 12,
           offset: Offset(0, 4),
         ),
       ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.purple.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(color: Colors.purple.shade600),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          _isEditMode ? 'Ürün Düzenle' : 'Yeni Ürün Ekle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple.shade700, Colors.purple.shade400],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade50,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                         // Başlık ve açıklama
                     Container(
                       padding: EdgeInsets.all(20),
                       decoration: BoxDecoration(
                         gradient: LinearGradient(
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                           colors: [Colors.white, Colors.purple.shade50],
                         ),
                         borderRadius: BorderRadius.circular(16),
                         boxShadow: [
                           BoxShadow(
                             color: Colors.purple.withOpacity(0.08),
                             blurRadius: 15,
                             offset: Offset(0, 5),
                           ),
                         ],
                       ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isEditMode ? Icons.edit : Icons.add_shopping_cart,
                                color: Colors.purple.shade600,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                _isEditMode ? 'Ürün Bilgilerini Güncelle' : 'Yeni Ürün Bilgileri',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            _isEditMode 
                              ? 'Mevcut ürün bilgilerini düzenleyebilirsiniz.'
                              : 'Tüm alanları eksiksiz doldurun.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),

                    // Form alanları
                    _buildTextField(
                      controller: _nameController,
                      label: 'Ürün Adı *',
                      hint: 'Örn: Royal Canin Köpek Maması',
                      icon: Icons.pets,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ürün adı gereklidir';
                        }
                        if (value.trim().length < 3) {
                          return 'Ürün adı en az 3 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),

                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Açıklama *',
                      hint: 'Ürün hakkında detaylı bilgi...',
                      icon: Icons.description,
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Açıklama gereklidir';
                        }
                        if (value.trim().length < 10) {
                          return 'Açıklama en az 10 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),

                    _buildTextField(
                      controller: _priceController,
                      label: 'Fiyat (₺) *',
                      hint: 'Örn: 150.50',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Fiyat gereklidir';
                        }
                        final price = double.tryParse(value.trim());
                        if (price == null) {
                          return 'Geçerli bir fiyat girin';
                        }
                        if (price <= 0) {
                          return 'Fiyat 0\'dan büyük olmalıdır';
                        }
                        return null;
                      },
                    ),

                    _buildTextField(
                      controller: _discountController,
                      label: 'İndirim Oranı (%)',
                      hint: 'Örn: 20 (İsteğe bağlı)',
                      icon: Icons.local_offer,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final discount = double.tryParse(value.trim());
                          if (discount == null) {
                            return 'Geçerli bir indirim oranı girin';
                          }
                          if (discount < 0 || discount > 100) {
                            return 'İndirim oranı 0-100 arasında olmalıdır';
                          }
                        }
                        return null;
                      },
                    ),

                    _buildTextField(
                      controller: _imageUrlController,
                      label: 'Görsel URL *',
                      hint: 'https://example.com/image.jpg',
                      icon: Icons.image,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Görsel URL gereklidir';
                        }
                        final uri = Uri.tryParse(value.trim());
                        if (uri == null || !uri.hasAbsolutePath) {
                          return 'Geçerli bir URL girin';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 32),

                    // Kaydet butonu
                    Container(
                      width: double.infinity,
                      height: 56,
                                             decoration: BoxDecoration(
                         gradient: LinearGradient(
                           colors: [Colors.purple.shade500, Colors.purple.shade700],
                         ),
                         borderRadius: BorderRadius.circular(16),
                         boxShadow: [
                           BoxShadow(
                             color: Colors.purple.withOpacity(0.3),
                             blurRadius: 8,
                             offset: Offset(0, 4),
                           ),
                         ],
                       ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    _isEditMode ? 'Güncelleniyor...' : 'Ekleniyor...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isEditMode ? Icons.update : Icons.add,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _isEditMode ? 'Güncelle' : 'Ürün Ekle',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
