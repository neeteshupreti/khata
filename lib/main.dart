import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'db/local_database.dart';
import 'l10n/app_strings.dart';
import 'screens/home_screen.dart';
import 'services/app_colors.dart';
import 'services/app_status_colors.dart';
import 'services/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.load();
  await LocalDatabase.instance.database;
  runApp(const KhataApp());
}

class KhataApp extends StatelessWidget {
  const KhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Settings.lang,
      builder: (context, lang, _) {
        return MaterialApp(
          title: tr('appName'),
          debugShowCheckedModeBanner: false,
          locale: Locale(lang),
          supportedLocales: const [Locale('en'), Locale('ne')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: _appTheme,
          home: const HomeScreen(),
        );
      },
    );
  }
}

final ThemeData _appTheme = _buildTheme();

ThemeData _buildTheme() {
  final cs = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    error: AppColors.unpaid,
    onError: Colors.white,
  ).copyWith(
    surfaceTint: AppColors.primaryContainer,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: AppColors.background,

    extensions: <ThemeExtension<AppStatusColors>>[AppStatusColors.light],
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      fillColor: AppColors.surface,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        foregroundColor: AppColors.onSurface,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateColor.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AppColors.onPrimary;
          return AppColors.onSurfaceVariant;
        }),
        backgroundColor: WidgetStateColor.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.surface;
        }),
        textStyle: WidgetStateTextStyle.resolveWith(
          (s) => const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
      foregroundColor: AppColors.onPrimary,
    ),
    dividerTheme: const DividerThemeData(
      thickness: 1,
      color: AppColors.outline,
    ),
  );
}
