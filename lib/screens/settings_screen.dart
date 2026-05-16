import 'package:flutter/material.dart';

import '../services/user_prefs.dart';
import '../theme/app_theme.dart';

/// Kullanıcı tercihleri ekranı.
/// Şu an: bitki eklerken "yön sorma" sheet'inin açılıp açılmayacağı.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _askFacing;

  @override
  void initState() {
    super.initState();
    _askFacing = UserPrefs.instance.askFacingDirection;
  }

  Future<void> _toggleFacing(bool value) async {
    setState(() => _askFacing = value);
    await UserPrefs.instance.setAskFacingDirection(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SectionTitle('Ekim'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile.adaptive(
              value: _askFacing,
              onChanged: _toggleFacing,
              activeThumbColor: AppColors.emerald,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                'Bitki eklerken yön sor',
                style: AppText.bodyMd(context),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Açıkken her bitki ekleme akışında "hangi yöne baksın?" '
                  'penceresi gösterilir. Kapalıyken yön sorulmaz.',
                  style: AppText.sm(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(text, style: AppText.label(context)),
    );
  }
}
