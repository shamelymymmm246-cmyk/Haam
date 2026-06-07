import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // ── Page ──────────────────────────────────────────────────────
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(24, 20, 24, 120);
  static const EdgeInsets pagePaddingBottom = EdgeInsets.only(bottom: 120);

  // ── Card ──────────────────────────────────────────────────────
  static const EdgeInsets cardPadding = EdgeInsets.all(20);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(24);
  static const EdgeInsets cardPaddingSm = EdgeInsets.all(16);

  // ── Inline ────────────────────────────────────────────────────
  static const double gutter = 14;
  static const double gutterSm = 10;
  static const double gutterLg = 18;

  // ── Border Radius ─────────────────────────────────────────────
  static const double radiusCard = 24;
  static const double radiusCardMd = 20;
  static const double radiusCardSm = 16;
  static const double radiusButton = 14;
  static const double radiusPill = 999;

  // ── Icon Container ────────────────────────────────────────────
  static const double iconContainerLg = 56;
  static const double iconContainerMd = 40;
  static const double iconContainerSm = 32;

  // ── Height / Width ────────────────────────────────────────────
  static const double buttonHeight = 52;
  static const double toggleWidth = 48;
  static const double toggleHeight = 28;
  static const double thumbSize = 24;

  // ── Section ───────────────────────────────────────────────────
  static const double sectionGap = 28;
  static const double sectionGapSm = 18;
  static const double sectionGapLg = 32;
}
