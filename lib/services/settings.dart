import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static final ValueNotifier<String> lang = ValueNotifier<String>('en');
  static final ValueNotifier<bool> useBs = ValueNotifier<bool>(false);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    lang.value = prefs.getString('lang') ?? 'en';
    useBs.value = prefs.getBool('useBs') ?? false;
  }

  static Future<void> setLang(String value) async {
    lang.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', value);
  }

  static Future<void> setUseBs(bool value) async {
    useBs.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useBs', value);
  }
}

mixin SettingsListener<T extends StatefulWidget> on State<T> {
  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    Settings.lang.addListener(_onSettingsChanged);
    Settings.useBs.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    Settings.lang.removeListener(_onSettingsChanged);
    Settings.useBs.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
