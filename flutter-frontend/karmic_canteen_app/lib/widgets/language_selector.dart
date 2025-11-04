// lib/widgets/language_selector.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Language'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLanguageTile(
              context,
              'English',
              '🇬🇧',
              const Locale('en'),
            ),
            _buildLanguageTile(
              context,
              'हिंदी',
              '🇮🇳',
              const Locale('hi'),
            ),
            _buildLanguageTile(
              context,
              'ಕನ್ನಡ',
              '🇮🇳',
              const Locale('kn'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String language,
    String flag,
    Locale locale,
  ) {
    final isSelected = context.locale == locale;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 32)),
      title: Text(language),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF21808D))
          : null,
      selected: isSelected,
      selectedTileColor: Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () async {
        await context.setLocale(locale);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language changed to $language'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}
