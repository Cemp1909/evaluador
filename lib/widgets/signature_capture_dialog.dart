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
    penColor: AppColors.primaryDark,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.titulo),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firma dentro del recuadro usando el dedo o un lápiz digital.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.outline),
                  borderRadius: BorderRadius.circular(16),
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
        const SnackBar(content: Text('Primero realiza la firma.')),
      );
      return;
    }
    final bytes = await _controller.toPngBytes();
    if (bytes != null && mounted) Navigator.pop(context, base64Encode(bytes));
  }
}
