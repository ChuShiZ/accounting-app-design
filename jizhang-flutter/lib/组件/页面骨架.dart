import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../主题/令牌.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.space4,
              tokens.space3,
              tokens.space4,
              tokens.space4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtitle != null) ...[
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                        ),
                        SizedBox(height: tokens.space1),
                      ],
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                ?action,
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                tokens.space4,
                0,
                tokens.space4,
                tokens.space6,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderCard extends StatelessWidget {
  const PlaceholderCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = LucideIcons.construction,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.all(tokens.space4),
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.primaryLight,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: Icon(icon, size: 20, color: tokens.primary),
          ),
          SizedBox(width: tokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                SizedBox(height: tokens.space1),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
