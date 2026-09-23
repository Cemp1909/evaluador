class OfflineStoreBusy implements Exception {
  const OfflineStoreBusy();
  @override
  String toString() =>
      'Esta cuenta ya está abierta en otra pestaña. Ciérrala y vuelve a entrar aquí.';
}
