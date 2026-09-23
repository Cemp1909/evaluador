{{flutter_js}}
{{flutter_build_config}}

// Los binarios del motor se sirven desde el mismo sitio para abrir sin red.
_flutter.loader.load({config: {canvasKitBaseUrl: 'canvaskit/'}});
if ('serviceWorker' in navigator && window.isSecureContext) {
  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('offline_service_worker.js', {updateViaCache: 'none'})
      .then((registration) => registration.update())
      .catch((error) => {
        console.warn('No se pudo preparar la apertura sin conexión.', error);
      });
  });
}
