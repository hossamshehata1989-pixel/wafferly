import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/responsive_metrics.dart';
import 'package:provider/provider.dart';

import '../../controller/settings_controller.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_switch_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    final controller = context.watch<SettingsController>();

    final state = controller.state;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(metrics.spacing(16)),
        children: [
          _buildSection(
            title: 'Account',
            children: const [
              SettingsTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English',
              ),

              SettingsTile(
                icon: Icons.currency_exchange,
                title: 'Currency',
                subtitle: 'EGP',
              ),
            ],
          ),

          _buildSection(
            title: 'App Preferences',
            children: [
              SettingsTile(icon: Icons.palette_outlined, title: 'Theme'),

              SettingsSwitchTile(
                icon: Icons.volume_up_outlined,
                title: 'Sound Effects',
                value: state.soundEffects,
                onChanged: controller.toggleSoundEffects,
              ),

              SettingsSwitchTile(
                icon: Icons.vibration,
                title: 'Haptic Feedback',
                value: state.hapticFeedback,
                onChanged: controller.toggleHapticFeedback,
              ),
            ],
          ),

          _buildSection(
            title: 'Notifications',
            children: [
              SettingsSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Daily Reminder',
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),

          _buildSection(
            title: 'Security',
            children: [
              const SettingsTile(icon: Icons.lock_outline, title: 'PIN Lock'),
              SettingsSwitchTile(
                icon: Icons.fingerprint,
                title: 'Fingerprint',
                value: state.fingerprintEnabled,
                onChanged: controller.toggleFingerprint,
              ),
            ],
          ),

          _buildSection(
            title: 'Data & Backup',
            children: const [
              SettingsTile(icon: Icons.upload_file, title: 'Export Data'),
            ],
          ),

          _buildSection(
            title: 'About',
            children: const [
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
              ),
              SettingsTile(icon: Icons.support_agent, title: 'Contact Support'),
              SettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.0',
                showArrow: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
