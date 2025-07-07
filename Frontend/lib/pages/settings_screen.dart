import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = false;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'Türkçe';
  String _selectedCurrency = 'TL (₺)';
  bool _biometricEnabled = false;
  bool _autoLogin = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? false;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _selectedLanguage = prefs.getString('selected_language') ?? 'Türkçe';
      _selectedCurrency = prefs.getString('selected_currency') ?? 'TL (₺)';
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _autoLogin = prefs.getBool('auto_login') ?? true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
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
                        'Ayarlar',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),

              // Settings Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Bildirimler Bölümü
                      _buildSectionCard(
                        title: 'Bildirimler',
                        icon: Icons.notifications,
                        children: [
                          _buildSwitchTile(
                            title: 'Push Bildirimleri',
                            subtitle: 'Yeni ürünler ve kampanyalar için bildirim al',
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                              _saveSetting('notifications_enabled', value);
                            },
                          ),
                          _buildSwitchTile(
                            title: 'E-posta Bildirimleri',
                            subtitle: 'Önemli güncellemeler için e-posta al',
                            value: _emailNotifications,
                            onChanged: (value) {
                              setState(() {
                                _emailNotifications = value;
                              });
                              _saveSetting('email_notifications', value);
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Görünüm Bölümü
                      _buildSectionCard(
                        title: 'Görünüm',
                        icon: Icons.palette,
                        children: [
                          _buildSwitchTile(
                            title: 'Karanlık Mod',
                            subtitle: 'Gece kullanımı için koyu tema',
                            value: _darkModeEnabled,
                            onChanged: (value) {
                              setState(() {
                                _darkModeEnabled = value;
                              });
                              _saveSetting('dark_mode_enabled', value);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Karanlık mod ${value ? 'açıldı' : 'kapandı'}'),
                                  backgroundColor: Colors.deepPurple,
                                ),
                              );
                            },
                          ),
                          _buildDropdownTile(
                            title: 'Dil',
                            subtitle: 'Uygulama dili seçin',
                            value: _selectedLanguage,
                            items: ['Türkçe', 'English', 'Deutsch', 'Français'],
                            onChanged: (value) {
                              setState(() {
                                _selectedLanguage = value!;
                              });
                              _saveSetting('selected_language', value);
                            },
                          ),
                          _buildDropdownTile(
                            title: 'Para Birimi',
                            subtitle: 'Fiyatlar için para birimi',
                            value: _selectedCurrency,
                            items: ['TL (₺)', 'USD (\$)', 'EUR (€)', 'GBP (£)'],
                            onChanged: (value) {
                              setState(() {
                                _selectedCurrency = value!;
                              });
                              _saveSetting('selected_currency', value);
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Güvenlik Bölümü
                      _buildSectionCard(
                        title: 'Güvenlik',
                        icon: Icons.security,
                        children: [
                          _buildSwitchTile(
                            title: 'Biyometrik Giriş',
                            subtitle: 'Parmak izi veya yüz tanıma ile giriş',
                            value: _biometricEnabled,
                            onChanged: (value) {
                              setState(() {
                                _biometricEnabled = value;
                              });
                              _saveSetting('biometric_enabled', value);
                            },
                          ),
                          _buildSwitchTile(
                            title: 'Otomatik Giriş',
                            subtitle: 'Uygulama açılışında otomatik giriş yap',
                            value: _autoLogin,
                            onChanged: (value) {
                              setState(() {
                                _autoLogin = value;
                              });
                              _saveSetting('auto_login', value);
                            },
                          ),
                          _buildActionTile(
                            title: 'Şifre Değiştir',
                            subtitle: 'Hesap şifrenizi güncelleyin',
                            icon: Icons.lock_reset,
                            onTap: () {
                              _showPasswordChangeDialog();
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Uygulama Bölümü
                      _buildSectionCard(
                        title: 'Uygulama',
                        icon: Icons.apps,
                        children: [
                          _buildActionTile(
                            title: 'Yardım Merkezi',
                            subtitle: 'SSS ve destek bilgileri',
                            icon: Icons.help_outline,
                            onTap: () {
                              Navigator.pushNamed(context, '/help');
                            },
                          ),
                          _buildActionTile(
                            title: 'Önbelleği Temizle',
                            subtitle: 'Geçici dosyaları temizle (${_getCacheSize()})',
                            icon: Icons.cleaning_services,
                            onTap: () {
                              _clearCache();
                            },
                          ),
                          _buildActionTile(
                            title: 'Uygulama Hakkında',
                            subtitle: 'Sürüm bilgileri ve lisanslar',
                            icon: Icons.info,
                            onTap: () {
                              _showAboutDialog();
                            },
                          ),
                          _buildActionTile(
                            title: 'Geri Bildirim Gönder',
                            subtitle: 'Önerilerinizi bizimle paylaşın',
                            icon: Icons.feedback,
                            onTap: () {
                              _showFeedbackDialog();
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Hesap Bölümü
                      _buildSectionCard(
                        title: 'Hesap',
                        icon: Icons.account_circle,
                        children: [
                          _buildActionTile(
                            title: 'Profil Bilgilerini Güncelle',
                            subtitle: 'Kişisel bilgilerinizi düzenleyin',
                            icon: Icons.edit,
                            onTap: () {
                              Navigator.pushNamed(context, '/profile');
                            },
                          ),
                          _buildActionTile(
                            title: 'Veri İndir',
                            subtitle: 'Hesap verilerinizi indirin',
                            icon: Icons.download,
                            onTap: () {
                              _exportUserData();
                            },
                          ),
                          _buildActionTile(
                            title: 'Hesabı Sil',
                            subtitle: 'Hesabınızı kalıcı olarak silin',
                            icon: Icons.delete_forever,
                            textColor: Colors.red,
                            onTap: () {
                              _showDeleteAccountDialog();
                            },
                          ),
                        ],
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
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
          // Section Header
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurple,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        underline: SizedBox(),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? Colors.deepPurple,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  String _getCacheSize() {
    // Simulated cache size
    return '12.5 MB';
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Önbelleği Temizle'),
        content: Text('Tüm geçici dosyalar silinecektir. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Önbellek temizlendi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Shoppy',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.shopping_bag,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        Text('Evcil dostlarınız için alışveriş uygulaması'),
        SizedBox(height: 10),
        Text('© 2024 Shoppy. Tüm hakları saklıdır.'),
      ],
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Geri Bildirim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Önerilerinizi bizimle paylaşın:'),
            SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Geri bildiriminizi yazın...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Geri bildiriminiz gönderildi. Teşekkürler!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _showPasswordChangeDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Şifre Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mevcut Şifre',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre Tekrar',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Şifre başarıyla değiştirildi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Şifreler eşleşmiyor'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  void _exportUserData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Veri dışa aktarma işlemi başlatıldı'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hesabı Sil'),
        content: Text(
          'Bu işlem geri alınamaz. Tüm verileriniz kalıcı olarak silinecektir. '
          'Devam etmek istediğinizden emin misiniz?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hesap silme işlemi iptal edildi'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }
} 