import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens external apps: the phone dialer for vets, the browser for videos.
///
/// Small and testable on purpose: every caller in the app goes through these
/// two methods, so a change in URL policy only needs one edit.
class ExternalActions {
  const ExternalActions();

  /// Opens the phone dialer with [phone] pre-filled.
  /// Returns true when the dialer actually opened.
  Future<bool> callPhone(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^+\d]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) {
        _showFallback(context, phone);
      }
      return ok;
    } catch (_) {
      if (context.mounted) _showFallback(context, phone);
      return false;
    }
  }

  /// Opens [url] in the external browser / YouTube app.
  /// Returns true when the link was opened.
  Future<bool> openVideo(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.hasScheme)) {
      if (context.mounted) _showFallback(context, url);
      return false;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _showFallback(context, url);
      return ok;
    } catch (_) {
      if (context.mounted) _showFallback(context, url);
      return false;
    }
  }

  void _showFallback(BuildContext context, String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }
}
