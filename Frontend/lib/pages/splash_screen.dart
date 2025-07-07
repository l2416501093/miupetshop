import 'package:flutter/material.dart';
import 'package:shoppy/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _startSplashSequence();
  }

  void _startSplashSequence() async {
    // Animasyonu başlat
    _animationController.forward();
    
    // 2.5 saniye bekle
    await Future.delayed(Duration(milliseconds: 2500));
    
    // Kullanıcı giriş durumunu kontrol et
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      bool isLoggedIn = await AuthService.isLoggedIn();
      
      if (mounted) {
        if (isLoggedIn) {
          // Kullanıcı zaten giriş yapmış, ana sayfaya yönlendir
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Kullanıcı giriş yapmamış, login sayfasına yönlendir
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      // Hata durumunda login sayfasına yönlendir
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              Colors.deepPurple.shade300,
              Colors.deepPurple.shade600,
              Colors.purple.shade800,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animasyonu
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.shopping_bag,
                                size: 60,
                                color: Colors.deepPurple,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: 30),
              
              // Uygulama adı
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Shoppy',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Alışverişin Yeni Adresi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              SizedBox(height: 60),
              
              // Loading indicator
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 