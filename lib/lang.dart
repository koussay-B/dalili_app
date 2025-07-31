import 'package:flutter/material.dart';

class AppLanguage {
  final String name;       // الاسم المعروض للمستخدم
  final String code;       // رمز اللغة: 'en', 'fr', 'ar'
  final Locale locale;     // Locale('en'), etc.
  final String flag;       // إيموجي أو صورة علم

  AppLanguage({
    required this.name,
    required this.code,
    required this.locale,
    required this.flag,
  });
}

class LanguageConfig {
  static List<AppLanguage> supportedLanguages = [
    AppLanguage(
      name: 'English',
      code: 'en',
      locale: const Locale('en'),
      flag: '🇬🇧',
    ),
    AppLanguage(
      name: 'Français',
      code: 'fr',
      locale: const Locale('fr'),
      flag: '🇫🇷',
    ),
    AppLanguage(
      name: 'العربية',
      code: 'ar',
      locale: const Locale('ar'),
      flag: '🇸🇦',
    ),
  ];

  static Locale defaultLocale = const Locale('en');
}
