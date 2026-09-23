# Evaluador académico

Aplicación Flutter con Supabase para cuentas, colegios, docentes, clases,
asistencias, evaluaciones, reportes y archivos privados.

## Trabajo sin conexión

La app conserva una copia cifrada por usuario y proyecto, además de una cola
persistente para evaluaciones de capacitación (incluidas asistencias, fotos y
firmas), reportes por período y borradores. Solo indica «sincronizado» después de
la confirmación de Supabase. Los cambios nunca enviados se compactan; los envíos
inciertos conservan su identificador para poder reintentarlos sin duplicar.

Primero se debe iniciar sesión con internet y completar la descarga. Esa sesión
permite trabajar sin conexión durante siete días desde la última carga completa.
Cerrar y abrir la app conserva los pendientes. Cerrar sesión también los conserva,
pero exige volver a autenticarse con internet para recuperarlos. Otra cuenta no
puede leer ni enviar esos pendientes.

La sincronización se intenta al guardar, al volver a la app, manualmente y mediante
reintentos periódicos con espera creciente (hasta cinco minutos). La app debe estar
abierta: no se garantiza enviar datos con el navegador o la aplicación cerrados.

Cambios de usuarios, permisos, colegios, agenda, aprobaciones y porcentajes mínimos
requieren internet. Supabase vuelve a validar permisos al recibir cada cambio.
Si el mismo registro cambió en otro dispositivo, se conserva el pendiente y se
muestra un conflicto. «Revisar» permite exportar la copia o descartar explícitamente
los cambios de ese registro y descargar la versión de Supabase. No se combinan
versiones ni se sobrescriben conflictos automáticamente.

En web se usa HTTPS (o localhost para pruebas), IndexedDB y Web Crypto. Solo se
permite una pestaña editora por cuenta en el mismo navegador. La primera apertura
descarga los archivos públicos necesarios para volver a abrir sin red. Borrar los
datos del sitio, desinstalar la app o perder el dispositivo puede eliminar cambios
aún no enviados; la copia local no reemplaza el respaldo de Supabase.

## Configuración y compilación

1. Aplicar el script indicado en [supabase/README.md](supabase/README.md).
2. Configurar `.env` con `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`.
3. Ejecutar `flutter pub get` y `flutter run`.

Para web:

```sh
flutter build web --release
python3 scripts/preparar_web_offline.py
```

El build de Vercel ejecuta ambos pasos. La preparación offline es obligatoria para
probar la reapertura sin internet; `flutter build web` por sí solo no la habilita.
Solo se almacenan en la caché del service worker los archivos públicos de la app,
nunca las respuestas de Auth, REST ni Storage. La fuente Inter y el motor gráfico
se sirven desde el mismo sitio, sin depender de una CDN al abrir sin red.

## Verificación

- `flutter analyze`
- `flutter test`: incluye reinicio del almacén cifrado, aislamiento, compactación,
  reintentos, pérdida de respuesta, conflictos y recuperación de la sesión.
- `python3 scripts/probar_supabase.py`: conectividad y rechazo anónimo. Con una
  cuenta exclusiva en `.env.pruebas` comprueba escritura, idempotencia, conflicto y
  recuperación real del borrador. No usar una cuenta de trabajo.
- `scripts/probar_sql_offline.mjs`: instala la base en PostgreSQL embebido (PGlite),
  repite la actualización y prueba las funciones y políticas con distintos roles.
- `scripts/probar_web_offline.mjs`: prueba en Chrome del inicio, recarga sin red
  y recuperación de sesión (Auth/REST simulados). Requiere Playwright y un navegador compatible.

Para las herramientas JavaScript se pueden instalar `@electric-sql/pglite@0.3.14`
y `playwright@1.58.2` en una carpeta temporal y definir `PGLITE_MODULE` y
`PLAYWRIGHT_MODULE` con la ruta absoluta de sus módulos. `TEST_APP_URL` permite
cambiar el sitio local (por defecto `http://localhost:8765`) y `CHROME_PATH` el
navegador. Las pruebas simuladas y embebidas no certifican el proyecto Supabase real.

## Antes de publicar

La migración actualizada fue aplicada según la confirmación del usuario. Falta
ejecutar las pruebas autenticadas en Supabase y
probar el ciclo en los dispositivos destino: entrar con red, registrar asistencia,
poner modo avión, editar una evaluación con firma/foto, cerrar y abrir, reconectar
y comprobar los mismos datos desde otro dispositivo. Probar también dos dispositivos
editando el mismo registro y la pérdida de permisos de una cuenta.

La clave secreta compartida previamente debe revocarse en Supabase antes de publicar;
no está incluida en Flutter. Solo la clave publicable pertenece a la app. Los
cambios de rol y de mínimos (80 % y 75 % por defecto) siguen protegidos en el servidor.

Verificación realizada el 21 de septiembre de 2026: 82 pruebas Flutter aprobadas,
analizador sin incidencias, scripts SQL ejecutados en PGlite y apertura/recuperación
offline comprobada en Chrome. En el proyecto real se verificaron disponibilidad de
Auth y bloqueo del acceso anónimo. La prueba autenticada sigue pendiente porque
no hay cuenta de pruebas configurada en `.env.pruebas`; no se ha publicado esta versión.
