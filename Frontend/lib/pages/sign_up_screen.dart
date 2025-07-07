import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shoppy/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _tcController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Email validation regex
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _tcController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // API'ye gönderilecek kullanıcı verisi (createuser endpoint'ine uygun)
        final userData = {
          'Username': _usernameController.text.trim(),
          'Email': _emailController.text.trim(),
          'Password': _passwordController.text,
          'Tcno': _tcController.text.trim(),
          'Address': _addressController.text.trim(),
        };

        // API çağrısı
        final response = await http.post(
          Uri.parse(ApiConfig.registerEndpoint),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(userData),
        ).timeout(ApiConfig.requestTimeout);

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Başarılı kayıt
          final responseData = jsonDecode(response.body);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(responseData['message'] ?? 'Kayıt başarılı!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );

          // Başarılı kayıt sonrası local Hive'a da kaydedelim (offline kullanım için)
          await _saveToLocalHive();

          Navigator.pushReplacementNamed(context, '/login');
        } else if (response.statusCode == 400) {
          // Bad Request - Validation hatası
          final errorData = jsonDecode(response.body);
          setState(() {
            _errorMessage = errorData['message'] ?? 'Girilen bilgilerde hata var!';
          });
        } else if (response.statusCode == 409) {
          // Conflict - Kullanıcı zaten var
          setState(() {
            _errorMessage = 'Bu kullanıcı adı veya T.C. numarası zaten kayıtlı!';
          });
        } else {
          // Diğer API hataları
          try {
            final errorData = jsonDecode(response.body);
            setState(() {
              _errorMessage = errorData['message'] ?? 'Kayıt sırasında bir hata oluştu';
            });
          } catch (e) {
            setState(() {
              _errorMessage = 'Sunucu hatası! Status Code: ${response.statusCode}';
            });
          }
        }
      } catch (e) {
        // Network hatası
        setState(() {
          _errorMessage = 'Bağlantı hatası: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Offline kullanım için local Hive'a kaydetme (backup)
  Future<void> _saveToLocalHive() async {
    try {
      final usersBox = Hive.box<UserModel>('users');
      
      // Duplicate kontrolü
      final isDuplicate = usersBox.values.any((user) => 
        user.tcNo == _tcController.text.trim() || 
        user.fullName == _usernameController.text.trim()
      );
      
      if (!isDuplicate) {
        final newUser = UserModel(
          fullName: _usernameController.text.trim(),
          password: _passwordController.text,
          address: _addressController.text.trim(),
          email: _emailController.text.trim(),
          tcNo: _tcController.text.trim(),
        );
        await usersBox.add(newUser);
      }
    } catch (e) {
      print('Local kayıt hatası: $e');
    }
  }

  // Modern TextField builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isMultiline = false,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
    String? hintText,
    VoidCallback? onVisibilityToggle,
    bool? isPasswordVisible,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? !(isPasswordVisible ?? false) : false,
        enabled: !_isLoading,
        validator: validator,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: isMultiline ? 3 : 1,
        style: TextStyle(fontSize: 16, color: Colors.black87),
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (isPasswordVisible ?? false) ? Icons.visibility : Icons.visibility_off,
                    color: Colors.deepPurple.shade300,
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.deepPurple, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          counterText: maxLength != null ? '${controller.text.length}/$maxLength' : null,
          counterStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
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
        onPressed: _isLoading ? null : _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
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
                    'Kayıt yapılıyor...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                'Kayıt Ol',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.deepPurple.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () {
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Zaten hesabın var mı? Giriş Yap',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  // Validation methods
  String? _validateTC(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'T.C. Kimlik No gerekli';
    }
    
    value = value.trim();
    
    if (value.length != 11) {
      return 'T.C. Kimlik No 11 haneli olmalı';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'T.C. Kimlik No sadece rakam içermeli';
    }
    
    if (value[0] == '0') {
      return 'T.C. Kimlik No 0 ile başlayamaz';
    }
    
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi gerekli';
    }
    
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi girin';
    }
    
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }
    
    if (value.length > 50) {
      return 'Şifre en fazla 50 karakter olabilir';
    }
    
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı gerekli';
    }
    
    if (value != _passwordController.text) {
      return 'Şifreler eşleşmiyor';
    }
    
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kullanıcı adı gerekli';
    }
    
    if (value.trim().length < 3) {
      return 'Kullanıcı adı en az 3 karakter olmalı';
    }
    
    if (value.trim().length > 50) {
      return 'Kullanıcı adı en fazla 50 karakter olabilir';
    }
    
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Adres gerekli';
    }
    
    if (value.trim().length < 10) {
      return 'Adres en az 10 karakter olmalı';
    }
    
    if (value.trim().length > 200) {
      return 'Adres en fazla 200 karakter olabilir';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        
                        // Logo ve Başlık
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Hesap Oluştur',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Shoppy ailesine katılın',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 40),
                        
                        // Form Container
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Kullanıcı Adı
                                _buildTextField(
                                  controller: _usernameController,
                                  label: 'Kullanıcı Adı *',
                                  icon: Icons.person,
                                  maxLength: 50,
                                  validator: _validateUsername,
                                ),
                                
                                // E-posta
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'E-posta *',
                                  icon: Icons.email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                  hintText: 'ornek@email.com',
                                ),
                                
                                // Şifre
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Şifre *',
                                  icon: Icons.lock,
                                  isPassword: true,
                                  maxLength: 50,
                                  validator: _validatePassword,
                                  isPasswordVisible: _passwordVisible,
                                  onVisibilityToggle: () {
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                ),
                                
                                // Şifre Tekrar
                                _buildTextField(
                                  controller: _confirmPasswordController,
                                  label: 'Şifre Tekrar *',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  validator: _validateConfirmPassword,
                                  isPasswordVisible: _confirmPasswordVisible,
                                  onVisibilityToggle: () {
                                    setState(() {
                                      _confirmPasswordVisible = !_confirmPasswordVisible;
                                    });
                                  },
                                ),
                                
                                // T.C. Kimlik No
                                _buildTextField(
                                  controller: _tcController,
                                  label: 'T.C. Kimlik No *',
                                  icon: Icons.credit_card,
                                  keyboardType: TextInputType.number,
                                  maxLength: 11,
                                  validator: _validateTC,
                                ),
                                
                                // Adres
                                _buildTextField(
                                  controller: _addressController,
                                  label: 'Adres *',
                                  icon: Icons.home,
                                  isMultiline: true,
                                  maxLength: 200,
                                  validator: _validateAddress,
                                ),
                                
                                SizedBox(height: 8),
                                
                                // Hata Mesajı
                                if (_errorMessage != null)
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                SizedBox(height: 24),
                                
                                // Kayıt Ol Butonu
                                _buildSignUpButton(),
                                
                                SizedBox(height: 16),
                                
                                // Giriş Yap Butonu
                                _buildLoginButton(),
                                
                                SizedBox(height: 16),
                                
                                // Zorunlu alan bilgisi
                                Text(
                                  '* işaretli alanlar zorunludur',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 30),
                        
                        // Alt bilgi
                        Text(
                          '© 2024 Shoppy - Tüm hakları saklıdır',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
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
        ),
      ),
    );
  }
}
