// login_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Geliştirme kolaylığı için varsayılan değerler
    _usernameController.text = '';
    _passwordController.text = '';
    
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
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // API login çağrısı
        final result = await AuthService.login(
          username: username,
          password: password,
        );

        if (result['success'] == true) {
          // Başarılı login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(result['message'] ?? 'Giriş başarılı!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );

          // Eğer API'den user verisi gelmediyse, username'i manuel kaydet
          final userData = await AuthService.getUserData();
          if (userData == null || userData['Username'] == null) {
            // Manuel olarak username kaydet
            await AuthService.saveManualUserData({
              'Username': username,
              'Id': DateTime.now().millisecondsSinceEpoch,
            });
          }

          // Başarılı login sonrası local Hive'a da backup kaydedelim
          await _saveToLocalHive(username, password);

          // Ana ekrana yönlendir
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // API login hatası - Local Hive ile deneme yap
          final localResult = await _tryLocalLogin(username, password);
          if (!localResult) {
            setState(() {
              _errorMessage = result['message'] ?? 'Giriş başarısız!';
            });
          }
        }
      } catch (e) {
        // Network hatası - Local Hive ile deneme yap
        final localResult = await _tryLocalLogin(username, password);
        if (!localResult) {
          setState(() {
            _errorMessage = 'Bağlantı hatası. Lütfen tekrar deneyin.';
          });
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Offline kullanım için local Hive login
  Future<bool> _tryLocalLogin(String username, String password) async {
    try {
      final usersBox = Hive.box<UserModel>('users');
      
      final user = usersBox.values.firstWhere(
        (user) => user.fullName == username && user.password == password,
        orElse: () => throw Exception('User not found'),
      );

      // Local login başarılı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.offline_bolt, color: Colors.white),
              SizedBox(width: 8),
              Text('Offline giriş başarılı!'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
      // Offline login'de de username'i kaydet
      await AuthService.saveManualUserData({
        'Username': username,
        'Id': DateTime.now().millisecondsSinceEpoch,
      });
      
      Navigator.pushReplacementNamed(context, '/home');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Başarılı API login sonrası local backup kayıt
  Future<void> _saveToLocalHive(String username, String password) async {
    try {
      final usersBox = Hive.box<UserModel>('users');
      
      // Kullanıcı zaten var mı kontrol et
      final existingUser = usersBox.values.where(
        (user) => user.fullName == username,
      ).firstOrNull;

      if (existingUser == null) {
        // API'den kullanıcı verilerini al
        final userData = await AuthService.getUserData();
        if (userData != null) {
          final newUser = UserModel(
            fullName: userData['Username'] ?? username,
            password: password,
            address: userData['Address'] ?? '',
            email: userData['Email'] ?? '',
            tcNo: userData['Tcno'] ?? '',
          );
          await usersBox.add(newUser);
        }
      }
    } catch (e) {
      print('Local backup kayıt hatası: $e');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
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
        obscureText: isPassword ? _obscurePassword : false,
        enabled: !_isLoading,
        validator: validator,
        style: TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.deepPurple.shade300,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
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
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
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
        onPressed: _isLoading ? null : _login,
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
                    'Giriş yapılıyor...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                'Giriş Yap',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpButton() {
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
          Navigator.pushNamed(context, '/signUp');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Hesabın yok mu? Kayıt Ol',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
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
                              width: 120,
                              height: 120,
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
                            SizedBox(height: 24),
                            Text(
                              'Shoppy',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Evcil dostlarınız için her şey',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 50),
                      
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
                                label: 'Kullanıcı Adı',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Kullanıcı adı boş olamaz';
                                  }
                                  return null;
                                },
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Şifre
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Şifre',
                                icon: Icons.lock,
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Şifre boş olamaz';
                                  }
                                  return null;
                                },
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
                              
                              // Giriş Butonu
                              _buildLoginButton(),
                              
                              SizedBox(height: 16),
                              
                              // Kayıt Ol Butonu
                              _buildSignUpButton(),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 40),
                      
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