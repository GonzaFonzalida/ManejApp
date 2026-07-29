import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/design_system.dart';
import '../widgets/design/app_button.dart';
import '../widgets/design/app_card.dart';
import '../services/api_service.dart';
import '../utils/user_facing_error.dart';
import '../utils/app_feedback.dart';
import '../widgets/skeleton_loader.dart';
import 'instructor_onboarding_hub_screen.dart';

class InstructorRegistrationDocsScreen extends StatefulWidget {
  static const routeName = '/instructor_registration_docs';

  /// Si viene del hub con un documento rechazado, hace scroll a esa fila.
  final String? focusDocKey;

  const InstructorRegistrationDocsScreen({super.key, this.focusDocKey});

  @override
  State<InstructorRegistrationDocsScreen> createState() =>
      _InstructorRegistrationDocsScreenState();
}

class _InstructorRegistrationDocsScreenState
    extends State<InstructorRegistrationDocsScreen> {
  static const Map<String, String> _docLabels = {
    'dobleComandoImg': 'Foto Doble comando',
    'seguroImg': 'Foto Seguro de autoescuela',
    'vtvImg': 'Foto Verificación técnica',
    'reincidenciaImg': 'Certificado de reincidencia',
    'licenciaImg': 'Foto Licencia de conducir vigente',
  };

  final Map<String, bool> _onServer = {
    for (final k in _docLabels.keys) k: false,
  };

  late final Map<String, GlobalKey> _itemKeys = {
    for (final k in _docLabels.keys) k: GlobalKey(),
  };

  bool _bootstrapLoading = true;
  String? _uploadingKey;

  @override
  void initState() {
    super.initState();
    _bootstrap(silent: false);
  }

  Future<void> _bootstrap({bool silent = true}) async {
    if (!silent && mounted) {
      setState(() => _bootstrapLoading = true);
    }
    try {
      final p = await ApiService.getInstructorMeOrNull();
      if (!mounted) return;
      if (p != null) {
        for (final key in _docLabels.keys) {
          final u = p[key]?.toString();
          _onServer[key] = u != null && u.isNotEmpty;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _bootstrapLoading = false);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToFocusIfNeeded());
      }
    }
  }

  void _scrollToFocusIfNeeded() {
    final k = widget.focusDocKey;
    if (k == null || !_docLabels.containsKey(k)) return;
    final ctx = _itemKeys[k]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.12,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _pickAndUpload(String docKey) async {
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null || !mounted) return;

    setState(() => _uploadingKey = docKey);
    try {
      await ApiService.uploadInstructorDocument(docKey, image);
      if (!mounted) return;
      setState(() => _onServer[docKey] = true);
      AppFeedback.showSuccess(
          context, '${_docLabels[docKey]} guardado correctamente');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(e));
    } finally {
      if (mounted) setState(() => _uploadingKey = null);
    }
  }

  void _finish() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context)
          .pushReplacementNamed(InstructorOnboardingHubScreen.routeName);
    }
  }

  bool get _allOnServer => _onServer.values.every((v) => v);

  @override
  Widget build(BuildContext context) {
    final focusKey = widget.focusDocKey;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Documentación',
          style: AppTextStyles.heading.copyWith(fontSize: 20),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: _bootstrapLoading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: CardSkeletonLoader(),
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      focusKey != null
                          ? 'Corregí tu documentación'
                          : 'Subí tus documentos',
                      style: AppTextStyles.displayLarge.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      focusKey != null
                          ? 'Elegí una imagen nueva para reemplazar el archivo. Se envía al instante al servidor.'
                          : 'Cada archivo se guarda en cuanto lo elegís. Un administrador los revisará en breve.',
                      style: AppTextStyles.bodyNormal
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceLight,
                        onRefresh: () => _bootstrap(silent: true),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: _docLabels.keys.map((docKey) {
                            final label = _docLabels[docKey]!;
                            final onServer = _onServer[docKey] == true;
                            final uploading = _uploadingKey == docKey;
                            final isFocus = focusKey == docKey;
                            return Padding(
                              key: _itemKeys[docKey],
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Container(
                                  decoration: isFocus
                                      ? BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.7),
                                            width: 1.5,
                                          ),
                                        )
                                      : null,
                                  padding: isFocus
                                      ? const EdgeInsets.all(8)
                                      : EdgeInsets.zero,
                                  child: Row(
                                    children: [
                                      if (uploading)
                                        const SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      else
                                        Icon(
                                          onServer
                                              ? Icons.check_circle_outline
                                              : Icons.upload_file_outlined,
                                          color: onServer
                                              ? AppColors.success
                                              : AppColors.primary,
                                          size: 32,
                                        ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              label,
                                              style: AppTextStyles.bodyLarge
                                                  .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: onServer
                                                    ? AppColors.textSecondary
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            if (onServer)
                                              Text(
                                                'Recibido',
                                                style: AppTextStyles.bodyNormal
                                                    .copyWith(
                                                  fontSize: 12,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: uploading
                                            ? null
                                            : () => _pickAndUpload(docKey),
                                        child: Text(
                                            onServer ? 'Reemplazar' : 'Subir'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!_allOnServer)
                      Text(
                        'Faltan documentos obligatorios (${_onServer.values.where((v) => v).length}/${_onServer.length}).',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyNormal.copyWith(fontSize: 12),
                      ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: Navigator.of(context).canPop()
                          ? 'Volver al panel de activación'
                          : 'Ir al panel de activación',
                      onPressed: _finish,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
