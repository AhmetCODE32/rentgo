import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rentgo/core/auth_service.dart';
import 'package:rentgo/screens/phone_auth_screen.dart';
import 'package:rentgo/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  Future<void> _loginWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun.');
      return;
    }
    await _performAuthAction(() => _authService.signInWithEmailAndPassword(_emailController.text.trim(),_passwordController.text.trim()));
  }

  Future<void> _loginWithGoogle() async {
    await _performAuthAction(() => _authService.signInWithGoogle());
  }

  Future<void> _performAuthAction(Future<User?> Function() authAction) async {
    setState(() => _isLoading = true);
    try {
      final user = await authAction();
      if (mounted && user != null && !user.emailVerified && user.providerData.any((p) => p.providerId == 'password')) {
        _showError('Lütfen e-postanızı doğrulayın.');
        await _authService.signOut();
      }
    } catch (e) {
      _showError('Giriş başarısız oldu. Lütfen tekrar deneyin.');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AbsorbPointer(
              absorbing: _isLoading,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tada(infinite: true, duration: const Duration(seconds: 3), child: const Icon(Icons.directions_car, color: Colors.blueAccent, size: 80)),
                  const SizedBox(height: 24),
                  FadeInUp(delay: const Duration(milliseconds: 200), child: Text("RentGo'ya Hoş Geldiniz", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  FadeInUp(delay: const Duration(milliseconds: 300), child: Text('Devam etmek için giriş yapın', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey))),
                  const SizedBox(height: 40),
                  FadeInUp(delay: const Duration(milliseconds: 400), child: _AuthInput(controller: _emailController, hint: 'E-posta', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress)),
                  const SizedBox(height: 16),
                  FadeInUp(delay: const Duration(milliseconds: 500), child: _AuthInput(controller: _passwordController, hint: 'Şifre', icon: Icons.lock_outline, isPassword: true)),
                  const SizedBox(height: 24),
                  if (_isLoading) const CircularProgressIndicator(),
                  if (!_isLoading)
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(onPressed: _loginWithEmail, child: const Text('Giriş Yap')),
                          const SizedBox(height: 24),
                          const Row(children: [Expanded(child: Divider(color: Colors.white24)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('VEYA', style: TextStyle(color: Colors.grey))), Expanded(child: Divider(color: Colors.white24))]),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(icon: Image.asset('assets/google_logo.png', height: 22), label: const Text('Google ile Giriş Yap'), onPressed: _loginWithGoogle),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(icon: const Icon(Icons.phone_iphone), label: const Text('Telefon Numarası ile Giriş Yap'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneAuthScreen()))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (!_isLoading) FadeInUp(delay: const Duration(milliseconds: 700), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Hesabınız yok mu?', style: TextStyle(color: Colors.grey)), TextButton(onPressed: () => Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const SignupScreen(), transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child))), child: const Text('Kayıt Olun'))])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthInput extends StatelessWidget {
  final TextEditingController controller; final String hint; final IconData icon; final bool isPassword; final TextInputType keyboardType;
  const _AuthInput({super.key, required this.controller, required this.hint, required this.icon, this.isPassword = false, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(controller: controller, keyboardType: keyboardType, obscureText: isPassword, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)));
  }
}
