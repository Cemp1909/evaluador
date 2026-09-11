import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../theme/app_theme.dart';

class SignatureCaptureDialog extends StatefulWidget {
  const SignatureCaptureDialog({super.key, required this.titulo});

  final String titulo;

  static Future<String?> show(BuildContext context, String titulo) =>
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => SignatureCaptureDialog(titulo: titulo),
      );

  @override
  State<SignatureCaptureDialog> createState() => _SignatureCaptureDialogState();
}

class _SignatureCaptureDialogState extends State<SignatureCaptureDialog> {
  late final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: AppColors.primary,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      title: Text(widget.titulo),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firma dentro del recuadro con el dedo o un lápiz digital.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: scheme.outline, width: 1.2),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Signature(
                  controller: _controller,
                  width: double.infinity,
                  height: 220,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _controller.clear, child: const Text('Limpiar')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar firma')),
      ],
    );
  }

  Future<void> _guardar() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes realizar la firma.')),
      );
      return;
    }
    final bytes = await _controller.toPngBytes();
    if (bytes != null && mounted) Navigator.pop(context, base64Encode(bytes));
  }
}
