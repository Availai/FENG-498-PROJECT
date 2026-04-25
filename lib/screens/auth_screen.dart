import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_providers.dart';
import '../services/haptic_service.dart';

/// Email / password authentication screen.
/// Tam ekran arka plan + cam efektli kart + nazik animasyonlar.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late TabController _tabCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _cardSlide;

  bool _loading = false;
  bool _obscurePass = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _error = null));

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
    _cardSlide = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _entryCtrl.dispose();
    _glowCtrl.dispose();
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
          // 1) Tüm ekranı kaplayan arka plan görseli
          Image.asset(
            'assets/dashboard_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D3B15), Color(0xFF1B5E20), Color(0xFF2E7D32)],
                ),
              ),
            ),
          ),
          // 2) Üstten alta okunabilirlik gradyanı
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC0A2912),
                  Color(0x801B5E20),
                  Color(0xCC0A2912),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          // 3) Yumuşak yeşil glow (animasyonlu, atmosferik)
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => Positioned(
              top: -120 + (_glowCtrl.value * 20),
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF66BB6A).withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => Positioned(
              bottom: -140 - (_glowCtrl.value * 20),
              left: -120,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2E7D32).withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4) İçerik
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 36),
                  // Logo — pulse efektli halo
                  ScaleTransition(
                    scale: _logoScale,
                    child: AnimatedBuilder(
                      animation: _glowCtrl,
                      builder: (_, child) => Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF66BB6A), Color(0xFF1B5E20)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF66BB6A).withValues(
                                alpha: 0.4 + (_glowCtrl.value * 0.25),
                              ),
                              blurRadius: 30 + (_glowCtrl.value * 15),
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: child,
                      ),
                      child: const Icon(Icons.eco_rounded,
                          size: 54, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _logoScale,
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                      ).createShader(rect),
                      child: const Text(
                        'Tarlam',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.4,
                          shadows: [
                            Shadow(
                              color: Color(0x88000000),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeTransition(
                    opacity: _cardSlide,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 1,
                          color: Colors.white38,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'TOPRAĞINLA AKILLI BAĞ KUR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 2.6,
                            ),
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 1,
                          color: Colors.white38,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Card
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.18),
                      end: Offset.zero,
                    ).animate(_cardSlide),
                    child: FadeTransition(
                      opacity: _cardSlide,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.97),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                            BoxShadow(
                              color: const Color(0xFF1B5E20).withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
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
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.grey.shade600,
                                labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14),
                                dividerColor: Colors.transparent,
                                splashFactory: NoSplash.splashFactory,
                                tabs: const [
                                  Tab(text: 'Giriş Yap'),
                                  Tab(text: 'Kayıt Ol'),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                              child: Form(
                                key: _formKey,
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (_tabCtrl.index == 1) ...[
                                        _field(
                                          controller: _nameCtrl,
                                          label: 'Ad Soyad',
                                          icon: Icons.person_outline_rounded,
                                          validator: (v) => (v == null || v.trim().isEmpty)
                                              ? 'Ad soyad gerekli' : null,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
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
                                      const SizedBox(height: 12),
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
                                                color: Colors.grey.shade600),
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

                                      const SizedBox(height: 18),

                                      // Primary action — gradient & glow
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        height: 54,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: _loading
                                              ? []
                                              : [
                                                  BoxShadow(
                                                    color: const Color(0xFF1B5E20).withValues(alpha: 0.4),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(14),
                                            onTap: _loading
                                                ? null
                                                : (_tabCtrl.index == 0 ? _login : _register),
                                            child: Center(
                                              child: _loading
                                                  ? const SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                      child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5,
                                                      ),
                                                    )
                                                  : Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          _tabCtrl.index == 0
                                                              ? 'Giriş Yap'
                                                              : 'Hesap Oluştur',
                                                          style: const TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w700,
                                                            color: Colors.white,
                                                            letterSpacing: 0.4,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        const Icon(
                                                          Icons.arrow_forward_rounded,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                      ],
                                                    ),
                                            ),
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
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer ipucu
                  FadeTransition(
                    opacity: _cardSlide,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 14, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(
                          'Verileriniz güvende, çevrimdışı çalışır',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
