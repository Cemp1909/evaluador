import 'package:evaluador_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tema claro usa texto oscuro en chips y botones deshabilitados', () {
    final tema = AppTheme.light;
    final foreground = tema.filledButtonTheme.style?.foregroundColor;

    expect(tema.chipTheme.labelStyle?.color, AppColors.textPrimary);
    expect(tema.chipTheme.secondaryLabelStyle?.color, AppColors.textPrimary);
    expect(foreground?.resolve({WidgetState.disabled}), AppColors.textPrimary);
    expect(foreground?.resolve({}), Colors.white);
  });
}
