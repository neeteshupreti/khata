import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/app_colors.dart';
import '../services/settings.dart';

class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Settings.lang,
      builder: (context, lang, _) {
        return PopupMenuButton<String>(
          tooltip: tr('language'),
          icon: const Icon(Icons.translate, color: AppColors.onSurface),
          onSelected: Settings.setLang,
          itemBuilder: (context) => [
            CheckedPopupMenuItem<String>(
              value: 'en',
              checked: lang == 'en',
              child: const Text('English'),
            ),
            CheckedPopupMenuItem<String>(
              value: 'ne',
              checked: lang == 'ne',
              child: const Text('नेपाली'),
            ),
          ],
        );
      },
    );
  }
}
