import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

IconData categoryIconData(String key) {
  switch (key) {
    case 'food':
      return LucideIcons.utensils;
    case 'car':
      return LucideIcons.car;
    case 'cart':
      return LucideIcons.shoppingCart;
    case 'building':
      return LucideIcons.home;
    case 'fun':
      return LucideIcons.gamepad2;
    case 'coffee':
      return LucideIcons.coffee;
    case 'medical':
      return LucideIcons.cross;
    case 'education':
      return LucideIcons.graduationCap;
    case 'phone':
      return LucideIcons.phone;
    case 'mortgage':
      return LucideIcons.home;
    case 'loan':
      return LucideIcons.landmark;
    case 'card':
      return LucideIcons.creditCard;
    case 'salary':
      return LucideIcons.banknote;
    case 'gift':
      return LucideIcons.gift;
    case 'interest':
      return LucideIcons.percent;
    case 'invest':
      return LucideIcons.trendingUp;
    default:
      return LucideIcons.moreHorizontal;
  }
}

Color categoryColor(String key) {
  switch (key) {
    case 'food':
      return const Color(0xFFE5484D);
    case 'car':
      return const Color(0xFF2563EB);
    case 'cart':
      return const Color(0xFF7C3AED);
    case 'building':
      return const Color(0xFFB45309);
    case 'fun':
      return const Color(0xFFDB2777);
    case 'coffee':
      return const Color(0xFFA16207);
    case 'medical':
      return const Color(0xFFDC2626);
    case 'education':
      return const Color(0xFF0EA5E9);
    case 'phone':
      return const Color(0xFF0D9488);
    case 'mortgage':
      return const Color(0xFFEA580C);
    case 'loan':
      return const Color(0xFFEA580C);
    case 'card':
      return const Color(0xFF4F46E5);
    case 'salary':
      return const Color(0xFF16A34A);
    case 'gift':
      return const Color(0xFFC026D3);
    case 'interest':
      return const Color(0xFF059669);
    case 'invest':
      return const Color(0xFFD97706);
    default:
      return const Color(0xFF6B7280);
  }
}
