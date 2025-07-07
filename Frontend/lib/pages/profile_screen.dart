import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await AuthService.getUserDataWithDetails();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Profil bilgileri yüklenemedi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    // Logout onay dialogu
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkış Yap'),
        content: Text('Hesabınızdan çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Logout işlemi
      await AuthService.logout();
      
      // Login sayfasına yönlendir ve tüm geçmiş sayfaları temizle
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade400,
              Colors.deepPurple.shade100,
              Colors.white,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'Profil',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // AppBar balance için
                  ],
                ),
              ),

              // Profile Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.deepPurple),
                            SizedBox(height: 16),
                            Text(
                              'Profil bilgileri yükleniyor...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadUserProfile,
                                  child: Text('Tekrar Dene'),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Profile Avatar
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.deepPurple,
                                  ),
                                ),

                                SizedBox(height: 20),

                                // Username
                                Text(
                                  _userData?['Username'] ?? 'Kullanıcı',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),

                                SizedBox(height: 8),

                                // Admin Badge
                                if (_userData?['IsAdmin'] == true)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Admin',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                SizedBox(height: 30),

                                // Profile Info Cards
                                _buildInfoCard(
                                  icon: Icons.email,
                                  title: 'E-posta',
                                  value: _userData?['Email'] ?? 'Belirtilmemiş',
                                ),

                                _buildInfoCard(
                                  icon: Icons.location_on,
                                  title: 'Adres',
                                  value: _userData?['Address'] ?? 'Belirtilmemiş',
                                ),

                                _buildInfoCard(
                                  icon: Icons.credit_card,
                                  title: 'TC Kimlik No',
                                  value: _userData?['Tcno'] ?? 'Belirtilmemiş',
                                ),

                                _buildInfoCard(
                                  icon: Icons.badge,
                                  title: 'Kullanıcı ID',
                                  value: _userData?['Id']?.toString() ?? 'Belirtilmemiş',
                                ),

                                SizedBox(height: 40),

                                // Logout Button
                                Container(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _logout,
                                    icon: Icon(Icons.logout),
                                    label: Text(
                                      'Çıkış Yap',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 5,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 20),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple,
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
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 