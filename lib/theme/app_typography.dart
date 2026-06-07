import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // ── Display ──────────────────────────────────────────────────
  static TextStyle displayLg(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 48 / 40,
        letterSpacing: -0.02 * 40,
        color: AppColors.onSurface,
      );

  static TextStyle displayLgMobile(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 42 / 34,
        color: AppColors.onSurface,
      );

  // ── Headline ─────────────────────────────────────────────────
  static TextStyle headlineLg(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.01 * 32,
        color: AppColors.onSurface,
      );

  static TextStyle headlineLgMobile(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        color: AppColors.onSurface,
      );

  static TextStyle headlineMd(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        color: AppColors.onSurface,
      );

  static TextStyle headlineSm(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: AppColors.onSurface,
      );

  // ── Body ─────────────────────────────────────────────────────
  static TextStyle bodyLg(BuildContext context) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        height: 30 / 20,
        color: AppColors.onSurface,
      );

  static TextStyle bodyMd(BuildContext context) => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 24 / 17,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle bodySm(BuildContext context) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 22 / 14,
        color: AppColors.onSurfaceVariant,
      );

  // ── Label ────────────────────────────────────────────────────
  static TextStyle labelLg(BuildContext context) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 20 / 15,
        color: AppColors.onSurface,
      );

  static TextStyle labelMd(BuildContext context) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 18 / 13,
        color: AppColors.onSurface,
      );

  static TextStyle labelSm(BuildContext context) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 16 / 11,
        color: AppColors.onSurfaceVariant,
      );

  // ── Utility ──────────────────────────────────────────────────
  static TextStyle caption(BuildContext context) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: AppColors.onSurfaceVariant,
      );
}
