import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

IconData categoryIconData(String key) {
  switch (key) {
    case 'food':
      return LucideIcons.utensils;
    case 'breakfast':
      return LucideIcons.sandwich;
    case 'lunch':
      return LucideIcons.beef;
    case 'dinner':
      return LucideIcons.utensilsCrossed;
    case 'takeout':
      return LucideIcons.utensils;
    case 'drink':
      return LucideIcons.coffee;
    case 'snack':
      return LucideIcons.cake;
    case 'fruit':
      return LucideIcons.apple;
    case 'groceries':
      return LucideIcons.shoppingCart;
    case 'car':
      return LucideIcons.car;
    case 'bus':
      return LucideIcons.bus;
    case 'bike':
      return LucideIcons.bike;
    case 'fuel':
      return LucideIcons.fuel;
    case 'parking':
      return LucideIcons.parkingCircle;
    case 'train':
      return LucideIcons.train;
    case 'plane':
      return LucideIcons.plane;
    case 'hotel':
      return LucideIcons.hotel;
    case 'ticket':
      return LucideIcons.ticket;
    case 'travel':
      return LucideIcons.luggage;
    case 'cart':
      return LucideIcons.shoppingCart;
    case 'clothes':
      return LucideIcons.shirt;
    case 'digital':
      return LucideIcons.laptop;
    case 'appliance':
      return LucideIcons.tv;
    case 'beauty':
      return LucideIcons.sparkles;
    case 'baby':
      return LucideIcons.baby;
    case 'pet':
      return LucideIcons.dog;
    case 'package':
      return LucideIcons.package;
    case 'building':
      return LucideIcons.home;
    case 'utility':
      return LucideIcons.zap;
    case 'water':
      return LucideIcons.droplet;
    case 'wifi':
      return LucideIcons.wifi;
    case 'repair':
      return LucideIcons.wrench;
    case 'furniture':
      return LucideIcons.sofa;
    case 'rent':
      return LucideIcons.key;
    case 'fun':
      return LucideIcons.gamepad2;
    case 'movie':
      return LucideIcons.film;
    case 'music':
      return LucideIcons.music;
    case 'game':
      return LucideIcons.gamepad2;
    case 'sports':
      return LucideIcons.dumbbell;
    case 'subscription':
      return LucideIcons.repeat;
    case 'medical':
      return LucideIcons.cross;
    case 'medicine':
      return LucideIcons.pill;
    case 'hospital':
      return LucideIcons.stethoscope;
    case 'dental':
      return LucideIcons.smile;
    case 'health':
      return LucideIcons.heartPulse;
    case 'education':
      return LucideIcons.graduationCap;
    case 'book':
      return LucideIcons.bookOpen;
    case 'stationery':
      return LucideIcons.pencil;
    case 'phone':
      return LucideIcons.phone;
    case 'salary':
      return LucideIcons.banknote;
    case 'bonus':
      return LucideIcons.award;
    case 'commission':
      return LucideIcons.badgePercent;
    case 'business':
      return LucideIcons.store;
    case 'sidejob':
      return LucideIcons.briefcase;
    case 'gift':
      return LucideIcons.gift;
    case 'redpacket':
      return LucideIcons.gift;
    case 'charity':
      return LucideIcons.heartHandshake;
    case 'insurance':
      return LucideIcons.shield;
    case 'fee':
      return LucideIcons.receipt;
    case 'interest':
      return LucideIcons.percent;
    case 'invest':
      return LucideIcons.trendingUp;
    case 'dividend':
      return LucideIcons.coins;
    case 'stock':
      return LucideIcons.trendingUp;
    case 'fund':
      return LucideIcons.trendingUp;
    case 'refund':
      return LucideIcons.rotateCcw;
    case 'reimburse':
      return LucideIcons.receipt;
    case 'cash':
      return LucideIcons.wallet;
    case 'bank':
      return LucideIcons.landmark;
    case 'mortgage':
      return LucideIcons.home;
    case 'loan':
      return LucideIcons.landmark;
    case 'card':
      return LucideIcons.creditCard;
    default:
      return LucideIcons.moreHorizontal;
  }
}

Color categoryColor(String key) {
  switch (key) {
    case 'food':
      return const Color(0xFFE5484D);
    case 'breakfast':
      return const Color(0xFFEA580C);
    case 'lunch':
      return const Color(0xFFB45309);
    case 'dinner':
      return const Color(0xFFDC2626);
    case 'takeout':
      return const Color(0xFFF97316);
    case 'drink':
      return const Color(0xFFA16207);
    case 'snack':
      return const Color(0xFFDB2777);
    case 'fruit':
      return const Color(0xFF16A34A);
    case 'groceries':
      return const Color(0xFF059669);
    case 'car':
      return const Color(0xFF2563EB);
    case 'bus':
      return const Color(0xFF1D4ED8);
    case 'bike':
      return const Color(0xFF0D9488);
    case 'fuel':
      return const Color(0xFFEA580C);
    case 'parking':
      return const Color(0xFF4F46E5);
    case 'train':
      return const Color(0xFF0EA5E9);
    case 'plane':
      return const Color(0xFF0891B2);
    case 'hotel':
      return const Color(0xFF7C3AED);
    case 'ticket':
      return const Color(0xFFD97706);
    case 'travel':
      return const Color(0xFF9333EA);
    case 'cart':
      return const Color(0xFF7C3AED);
    case 'clothes':
      return const Color(0xFFDB2777);
    case 'digital':
      return const Color(0xFF2563EB);
    case 'appliance':
      return const Color(0xFF475569);
    case 'beauty':
      return const Color(0xFFC026D3);
    case 'baby':
      return const Color(0xFFEC4899);
    case 'pet':
      return const Color(0xFFF59E0B);
    case 'package':
      return const Color(0xFFD97706);
    case 'building':
      return const Color(0xFFB45309);
    case 'utility':
      return const Color(0xFFD97706);
    case 'water':
      return const Color(0xFF0284C7);
    case 'wifi':
      return const Color(0xFF0D9488);
    case 'repair':
      return const Color(0xFF475569);
    case 'furniture':
      return const Color(0xFF92400E);
    case 'rent':
      return const Color(0xFFEA580C);
    case 'fun':
      return const Color(0xFFDB2777);
    case 'movie':
      return const Color(0xFF7C3AED);
    case 'music':
      return const Color(0xFFC026D3);
    case 'game':
      return const Color(0xFFDB2777);
    case 'sports':
      return const Color(0xFF0D9488);
    case 'subscription':
      return const Color(0xFF4F46E5);
    case 'medical':
      return const Color(0xFFDC2626);
    case 'medicine':
      return const Color(0xFFE11D48);
    case 'hospital':
      return const Color(0xFFDC2626);
    case 'dental':
      return const Color(0xFF0EA5E9);
    case 'health':
      return const Color(0xFFE11D48);
    case 'education':
      return const Color(0xFF0EA5E9);
    case 'book':
      return const Color(0xFF2563EB);
    case 'stationery':
      return const Color(0xFFD97706);
    case 'phone':
      return const Color(0xFF0D9488);
    case 'salary':
      return const Color(0xFF16A34A);
    case 'bonus':
      return const Color(0xFFD97706);
    case 'commission':
      return const Color(0xFF059669);
    case 'business':
      return const Color(0xFFEA580C);
    case 'sidejob':
      return const Color(0xFF2563EB);
    case 'gift':
      return const Color(0xFFC026D3);
    case 'redpacket':
      return const Color(0xFFE5484D);
    case 'charity':
      return const Color(0xFFE11D48);
    case 'insurance':
      return const Color(0xFF2563EB);
    case 'fee':
      return const Color(0xFF475569);
    case 'interest':
      return const Color(0xFF059669);
    case 'invest':
      return const Color(0xFFD97706);
    case 'dividend':
      return const Color(0xFF16A34A);
    case 'stock':
      return const Color(0xFFDC2626);
    case 'fund':
      return const Color(0xFF059669);
    case 'refund':
      return const Color(0xFF0D9488);
    case 'reimburse':
      return const Color(0xFF475569);
    case 'cash':
      return const Color(0xFF16A34A);
    case 'bank':
      return const Color(0xFF2563EB);
    case 'mortgage':
      return const Color(0xFFEA580C);
    case 'loan':
      return const Color(0xFFEA580C);
    case 'card':
      return const Color(0xFF4F46E5);
    default:
      return const Color(0xFF6B7280);
  }
}
