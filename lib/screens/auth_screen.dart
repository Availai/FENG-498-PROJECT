import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_providers.dart';
import '../services/haptic_service.dart';
import '../widgets/particle_background.dart';

/// Email / password authentication screen.
/// Fulfills: "Registration and Authentication via email/password"
/// (Proposal Section 6.1.2.1).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late TabController _tabCtrl;
  bool _loading = false;
  bool _obscurePass = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Auth Actions ──────────────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    HapticService.instance.light();
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      HapticService.instance.success();
    } on FirebaseAuthException catch (e) {
      HapticService.instance.heavy();
      setState(() => _error = _mapError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    HapticService.instance.light();
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).registerWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        displayName: _nameCtrl.text,
      );
      HapticService.instance.success();
    } on FirebaseAuthException catch (e) {
      HapticService.instance.heavy();
      setState(() => _error = _mapError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'E-posta veya şifre hatalı. Lütfen tekrar deneyin.';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kayıtlı. Giriş yapmayı deneyin.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen birkaç dakika bekleyin.';
      case 'network-request-failed':
        return 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
      case 'operation-not-allowed':
        return 'Bu giriş yöntemi etkin değil. Yöneticiyle iletişime geçin.';
      default:
        return 'Bir hata oluştu ($code). Lütfen tekrar deneyin.';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D3B15), Color(0xFF1B5E20), Color(0xFF2E7D32)],
              ),
            ),
          ),
          // Hafif hareketli yeşil partiküller (atmosferik derinlik)
          const ParticleBackground(particleCount: 32),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  // Logo / header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco_rounded, size: 52, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tarlam',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Color(0x55000000),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toprağınla akıllı bağ kur',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tabs
                        Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TabBar(
                            controller: _tabCtrl,
                            indicator: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey.shade600,
                            labelStyle: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Giriş Yap'),
                              Tab(text: 'Kayıt Ol'),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          child: Form(
                            key: _formKey,
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Name field (register only)
                                  if (_tabCtrl.index == 1) ...[
                                    _field(
                                      controller: _nameCtrl,
                                      label: 'Ad Soyad',
                                      icon: Icons.person_outline_rounded,
                                      validator: (v) => (v == null || v.trim().isEmpty)
                                          ? 'Ad soyad gerekli' : null,
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  // Email
                                  _field(
                                    controller: _emailCtrl,
                                    label: 'E-posta',
                                    icon: Icons.email_outlined,
                                    type: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'E-posta gerekli';
                                      if (!v.contains('@')) return 'Geçerli bir e-posta girin';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  // Password
                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: _obscurePass,
                                    decoration: InputDecoration(
                                      labelText: 'Şifre',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                                          color: Color(0xFF2E7D32)),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePass
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                            color: Colors.grey),
                                        onPressed: () =>
                                            setState(() => _obscurePass = !_obscurePass),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF2E7D32), width: 1.5),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Şifre gerekli';
                                      if (v.length < 6) return 'En az 6 karakter';
                                      return null;
                                    },
                                  ),

                                  // Error message
                                  if (_error != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline,
                                              size: 18, color: Colors.red.shade700),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(_error!,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.red.shade700)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  // Primary action button
                                  SizedBox(
                                    height: 52,
                                    child: FilledButton(
                                      onPressed: _loading
                                          ? null
                                          : (_tabCtrl.index == 0 ? _login : _register),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF2E7D32),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              _tabCtrl.index == 0
                                                  ? 'Giriş Yap'
                                                  : 'Hesap Oluştur',
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
