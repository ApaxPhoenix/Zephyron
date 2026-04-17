import 'package:flutter/material.dart';
import 'artifact.dart' as model;
import 'package:zephyron/theme.dart';

class Style extends ThemeExtension<Style> {
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? trailingStyle;
  final Color? onlineIndicatorColor;
  final Color? badgeBackgroundColor;
  final Color? statusIconColor;

  const Style({
    this.titleStyle,
    this.subtitleStyle,
    this.trailingStyle,
    this.onlineIndicatorColor,
    this.badgeBackgroundColor,
    this.statusIconColor,
  });

  @override
  Style copyWith({
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    TextStyle? trailingStyle,
    Color? onlineIndicatorColor,
    Color? badgeBackgroundColor,
    Color? statusIconColor,
  }) {
    return Style(
      titleStyle: titleStyle ?? this.titleStyle,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      trailingStyle: trailingStyle ?? this.trailingStyle,
      onlineIndicatorColor: onlineIndicatorColor ?? this.onlineIndicatorColor,
      badgeBackgroundColor: badgeBackgroundColor ?? this.badgeBackgroundColor,
      statusIconColor: statusIconColor ?? this.statusIconColor,
    );
  }

  @override
  Style lerp(ThemeExtension<Style>? other, double t) {
    if (other is! Style) return this;
    return Style(
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t),
      subtitleStyle: TextStyle.lerp(subtitleStyle, other.subtitleStyle, t),
      trailingStyle: TextStyle.lerp(trailingStyle, other.trailingStyle, t),
      onlineIndicatorColor: Color.lerp(
        onlineIndicatorColor,
        other.onlineIndicatorColor,
        t,
      ),
      badgeBackgroundColor: Color.lerp(
        badgeBackgroundColor,
        other.badgeBackgroundColor,
        t,
      ),
      statusIconColor: Color.lerp(statusIconColor, other.statusIconColor, t),
    );
  }

  static Style light() {
    return Style(
      titleStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: AppTheme.neutral900,
      ),
      subtitleStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
        color: AppTheme.neutral700,
      ),
      trailingStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 12,
        color: AppTheme.neutral700,
      ),
      onlineIndicatorColor: AppTheme.success500,
      badgeBackgroundColor: AppTheme.neutral000,
      statusIconColor: AppTheme.neutral700,
    );
  }

  static Style dark() {
    return Style(
      titleStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: AppTheme.neutral000,
      ),
      subtitleStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
        color: AppTheme.neutral500,
      ),
      trailingStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 12,
        color: AppTheme.neutral500,
      ),
      onlineIndicatorColor: AppTheme.success500,
      badgeBackgroundColor: AppTheme.neutral900,
      statusIconColor: AppTheme.neutral500,
    );
  }
}

class Artifact extends StatelessWidget {
  final model.Artifact skeleton;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  const Artifact({
    super.key,
    required this.skeleton,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
  });

  static Style of(BuildContext context) {
    return Theme.of(context).extension<Style>()!;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
      ),
    );
  }
}
