import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import 'order_confirmation_screen.dart';

class AddressSelectionScreen extends StatefulWidget {
  @override
  _AddressSelectionScreenState createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedDeliveryAddress;
  String? _selectedBillingAddress;
  String _userRegisteredAddress = '';
  bool _isLoadingAddress = true;
  bool _isAddingNewAddress = false;
  bool _sameAsDelivery = true; // Fatura adresi teslimat adresi ile aynı mı?

  // Yeni adres form controllers
  final _newAddressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    _loadUserAddress();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _newAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAddress() async {
    try {
      print('🔍 Adres yükleniyor...');
      
      // Önce basit AuthService'den dene (login'de kaydedilen veri)
      final simpleUserData = await AuthService.getUserData();
      print('📱 Simple AuthService userData: $simpleUserData');
      print('📍 Simple Address: ${simpleUserData?['Address']}');
      
      if (simpleUserData != null && simpleUserData['Address'] != null && simpleUserData['Address'].toString().isNotEmpty) {
        print('✅ Simple AuthService\'den adres bulundu: ${simpleUserData['Address']}');
        setState(() {
          _userRegisteredAddress = simpleUserData['Address'];
          _selectedDeliveryAddress = _userRegisteredAddress;
          _selectedBillingAddress = _userRegisteredAddress;
          _isLoadingAddress = false;
        });
        return;
      }

      // Eğer basit veri yoksa, detaylı API çağrısı dene
      final userData = await AuthService.getUserDataWithDetails();
      print('📱 Detailed AuthService userData: $userData');
      print('📍 Detailed Address: ${userData?['Address']}');
      
      if (userData != null && userData['Address'] != null && userData['Address'].toString().isNotEmpty) {
        print('✅ Detailed AuthService\'den adres bulundu: ${userData['Address']}');
        setState(() {
          _userRegisteredAddress = userData['Address'];
          _selectedDeliveryAddress = _userRegisteredAddress;
          _selectedBillingAddress = _userRegisteredAddress;
          _isLoadingAddress = false;
        });
        return;
      }

      // AuthService'de yoksa Hive'dan dene
      final usersBox = Hive.box<UserModel>('users');
      print('📦 Hive box boş mu: ${usersBox.isEmpty}');
      
      if (usersBox.isNotEmpty) {
        final lastUser = usersBox.values.last;
        print('👤 Hive\'dan kullanıcı: ${lastUser.fullName}, Adres: "${lastUser.address}"');
        
        if (lastUser.address.isNotEmpty) {
          print('✅ Hive\'dan adres bulundu: ${lastUser.address}');
          setState(() {
            _userRegisteredAddress = lastUser.address;
            _selectedDeliveryAddress = _userRegisteredAddress;
            _selectedBillingAddress = _userRegisteredAddress;
            _isLoadingAddress = false;
          });
          return;
        }
      }

      // Hiçbir yerde adres yoksa
      print('❌ Hiçbir yerde adres bulunamadı');
      setState(() {
        _userRegisteredAddress = '';
        _isLoadingAddress = false;
      });
    } catch (e) {
      print('🚨 Adres yükleme hatası: $e');
      setState(() {
        _userRegisteredAddress = '';
        _isLoadingAddress = false;
      });
    }
  }

  void _addNewAddress() {
    if (_formKey.currentState?.validate() ?? false) {
      final newAddress = _newAddressController.text.trim();
      
      setState(() {
        _selectedDeliveryAddress = newAddress;
        if (_sameAsDelivery) {
          _selectedBillingAddress = newAddress;
        }
        _isAddingNewAddress = false;
        _newAddressController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Yeni adres eklendi'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showBillingAddressDialog() {
    final billingAddressController = TextEditingController();
    final billingFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Fatura Adresi Ekle'),
          ],
        ),
        content: Form(
          key: billingFormKey,
          child: TextFormField(
            controller: billingAddressController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Fatura adresinizi detaylı olarak yazın...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
              ),
              contentPadding: EdgeInsets.all(16),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Fatura adresi boş olamaz';
              }
              if (value.trim().length < 10) {
                return 'Adres en az 10 karakter olmalı';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              if (billingFormKey.currentState?.validate() ?? false) {
                setState(() {
                  _selectedBillingAddress = billingAddressController.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Fatura adresi eklendi'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: Text('Ekle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _proceedToOrder() async {
    if (_selectedDeliveryAddress == null || _selectedDeliveryAddress!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Lütfen teslimat adresi seçin'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_selectedBillingAddress == null || _selectedBillingAddress!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Lütfen fatura adresi seçin'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Loading göster
    _showLoadingDialog();

    try {
      // Sipariş API çağrısı
      final result = await OrderService.createOrder(
        deliveryAddress: _selectedDeliveryAddress!,
        billingAddress: _selectedBillingAddress!,
      );

      // Loading'i kapat
      Navigator.pop(context);

      if (result['success'] == true) {
        // Başarılı - Sipariş onay sayfasına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              deliveryAddress: _selectedDeliveryAddress!,
              billingAddress: _selectedBillingAddress!,
              orderNumber: result['orderNumber'] ?? '',
              totalAmount: result['total'] ?? 0.0,
            ),
          ),
        );
      } else {
        // Hata - Error dialog göster
        _showErrorDialog(result['message'] ?? 'Sipariş oluşturulurken bir hata oluştu!');
      }
    } catch (e) {
      // Loading'i kapat
      Navigator.pop(context);
      
      // Beklenmeyen hata
      _showErrorDialog('Beklenmeyen bir hata oluştu: ${e.toString()}');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text(
              'Siparişiniz oluşturuluyor...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Sipariş Hatası'),
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple, Colors.deepPurple.shade300],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: Colors.white),
            ),
            Expanded(
              child: Text(
                'Adres Seçimi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '2/3',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required String title,
    required String address,
    required bool isSelected,
    required VoidCallback onTap,
    IconData icon = Icons.home,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? Colors.deepPurple.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: isSelected ? 15 : 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.deepPurple.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.deepPurple : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewAddressForm() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_location, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Yeni Adres Ekle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _newAddressController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Adresinizi detaylı olarak yazın...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                contentPadding: EdgeInsets.all(16),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Adres boş olamaz';
                }
                if (value.trim().length < 10) {
                  return 'Adres en az 10 karakter olmalı';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isAddingNewAddress = false;
                        _newAddressController.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'İptal',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addNewAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Ekle',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSameAddressCheckbox() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _sameAsDelivery,
            onChanged: (value) {
              setState(() {
                _sameAsDelivery = value ?? true;
                if (_sameAsDelivery) {
                  _selectedBillingAddress = _selectedDeliveryAddress;
                }
              });
            },
            activeColor: Colors.deepPurple,
          ),
          Expanded(
            child: Text(
              'Fatura adresi teslimat adresi ile aynı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.deepPurple.shade300],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _proceedToOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Siparişi Onayla',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade600,
              Colors.deepPurple.shade400,
              Colors.purple.shade300,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        
                        // Teslimat Adresi Başlığı
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Teslimat Adresi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Loading veya Kayıtlı Adres
                        if (_isLoadingAddress)
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(color: Colors.deepPurple),
                            ),
                          )
                        else if (_userRegisteredAddress.isNotEmpty)
                          _buildAddressCard(
                            title: 'Kayıtlı Adresiniz',
                            address: _userRegisteredAddress,
                            isSelected: _selectedDeliveryAddress == _userRegisteredAddress,
                            onTap: () {
                              setState(() {
                                _selectedDeliveryAddress = _userRegisteredAddress;
                                if (_sameAsDelivery) {
                                  _selectedBillingAddress = _userRegisteredAddress;
                                }
                              });
                            },
                            icon: Icons.home,
                          ),
                        
                        // Yeni Adres Eklenen Varsa Göster
                        if (_selectedDeliveryAddress != null && 
                            _selectedDeliveryAddress!.isNotEmpty && 
                            _selectedDeliveryAddress != _userRegisteredAddress)
                          _buildAddressCard(
                            title: 'Yeni Adres',
                            address: _selectedDeliveryAddress!,
                            isSelected: true,
                            onTap: () {},
                            icon: Icons.add_location,
                          ),
                        
                        // Yeni Adres Ekleme Formu
                        if (_isAddingNewAddress)
                          _buildNewAddressForm()
                        else
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isAddingNewAddress = true;
                                });
                              },
                              icon: Icon(Icons.add, color: Colors.white),
                              label: Text(
                                'Yeni Adres Ekle',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withOpacity(0.7)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              ),
                            ),
                          ),
                        
                        SizedBox(height: 24),
                        
                        // Aynı Adres Checkbox
                        _buildSameAddressCheckbox(),
                        
                        // Fatura Adresi (Eğer farklıysa)
                        if (!_sameAsDelivery) ...[
                          SizedBox(height: 24),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Fatura Adresi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          
                          // Kayıtlı Adres (Fatura için)
                          if (_userRegisteredAddress.isNotEmpty)
                            _buildAddressCard(
                              title: 'Kayıtlı Adresiniz',
                              address: _userRegisteredAddress,
                              isSelected: _selectedBillingAddress == _userRegisteredAddress,
                              onTap: () {
                                setState(() {
                                  _selectedBillingAddress = _userRegisteredAddress;
                                });
                              },
                              icon: Icons.receipt_long,
                            ),
                          
                          // Eğer teslimat adresi olarak yeni adres seçildiyse onu da fatura için göster
                          if (_selectedDeliveryAddress != null && 
                              _selectedDeliveryAddress!.isNotEmpty && 
                              _selectedDeliveryAddress != _userRegisteredAddress)
                            _buildAddressCard(
                              title: 'Teslimat Adresi ile Aynı',
                              address: _selectedDeliveryAddress!,
                              isSelected: _selectedBillingAddress == _selectedDeliveryAddress,
                              onTap: () {
                                setState(() {
                                  _selectedBillingAddress = _selectedDeliveryAddress;
                                });
                              },
                              icon: Icons.content_copy,
                            ),
                          
                          // Fatura için ayrı yeni adres ekleme butonu
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Fatura adresi için yeni adres ekleme modalı
                                _showBillingAddressDialog();
                              },
                              icon: Icon(Icons.add, color: Colors.white),
                              label: Text(
                                'Fatura İçin Farklı Adres Ekle',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withOpacity(0.7)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              ),
                            ),
                          ),
                        ],
                        
                        SizedBox(height: 100), // Bottom button için yer
                      ],
                    ),
                  ),
                ),
              ),
              
              // Continue Button
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }
}