import 'package:flutter/material.dart';
import 'package:manejapp/config/app_environment.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openSupportEmail(BuildContext context) async {
  final uri = Uri(
    scheme: 'mailto',
    path: AppEnvironment.supportEmail,
    queryParameters: const {
      'subject': 'Ayuda con ManejApp',
    },
  );
  if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  if (context.mounted) {
    AppFeedback.showInfo(
      context,
      'Escribinos a ${AppEnvironment.supportEmail}',
    );
  }
}

Future<void> openExternalUrl(
  BuildContext context,
  String rawUrl, {
  String failureMessage = 'No pudimos abrir el enlace.',
}) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri != null &&
      await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    return;
  }
  if (context.mounted) AppFeedback.showError(context, failureMessage);
}
