# Base de datos de Evaluador

Hay **dos scripts alternativos**. Ejecuta solo uno, completo, en
Supabase → SQL Editor → New query → Run.

| Situación | Script |
| --- | --- |
| Ya ejecutaste la base inicial de doce tablas (tu caso) | [`actualizar_base_existente.sql`](actualizar_base_existente.sql) |
| Proyecto Supabase nuevo, sin esas tablas | [`instalacion_completa.sql`](instalacion_completa.sql) |

**No ejecutes ambos.** El primero conserva las tablas y los datos existentes;
agrega perfil de profesor por defecto, lectura del perfil propio, ciudad,
dirección y teléfono del colegio, permisos por rol y colegio, funciones para
guardar registros y un bucket privado para firmas y fotos. El segundo incluye
también la creación de las doce tablas.

Cada script se ejecuta en una transacción: si Supabase muestra un error, los
cambios de ese intento se revierten. El script para la base existente tolera
funciones, políticas y disparadores que ya se hubieran creado antes; puedes
volver a ejecutarlo si un intento anterior falló. Cuando se entregue una versión actualizada de este archivo, vuelve a ejecutarlo
completo para aplicar las adiciones; conserva los registros existentes.

Después de ejecutar el script correspondiente, crea una cuenta de prueba en
Authentication → Users. Verifica que aparece en `perfiles` con rol `profesor`.
Para probar administración y cambio de mínimos (80 % de asistencia y 75 % de
evaluación por período), un administrador debe asignar ese rol mediante una
operación privilegiada; el registro público nunca lo concede.

La app usa `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`. Nunca pongas la clave
secreta ni la contraseña de PostgreSQL en Flutter. El usuario confirmó que
`actualizar_base_existente.sql` terminó con `Success. No rows returned` y se
comprobó que el servicio de Auth responde HTTP 200. Falta validar en el proyecto
remoto un ciclo de guardar, cerrar sesión y volver a entrar. El borrador sin
finalizar de un reporte también se envía a Supabase en la tabla privada
`borradores_reportes`. La app requiere Supabase para la primera conexión. Ahora conserva la sesión,
una copia cifrada por usuario y una cola local para trabajar sin conexión.
La nueva sección de sincronización agrega revisiones, recibos de reintentos y
borrado lógico de borradores. El usuario confirmó el 21 de septiembre de 2026 que esta versión actualizada
terminó con `Success. No rows returned`. La comprobación autenticada de la
función de sincronización sigue pendiente de configurar una cuenta de pruebas.


Pruebas automatizadas: `flutter test` incluye pruebas con HTTP simulado de
recuperación de borradores, contactos, evaluaciones, asistencias, firmas, fotos y
reportes, y de fallos de guardado. No sustituyen las políticas del servidor real.

Prueba real: `python3 scripts/probar_supabase.py`. Lee la configuración local y
la cuenta exclusiva de prueba de `.env.pruebas` (`TEST_EMAIL`, `TEST_PASSWORD`,
archivo ignorado por Git). Sin cuenta solo comprueba conectividad y rechazo del
acceso anónimo. Con cuenta guarda, recupera desde otra sesión y elimina un
borrador temporal; se detiene si esa cuenta ya tiene un borrador.

El cliente comprueba `version_sincronizacion_academica()` antes de aceptar cambios
offline. `sincronizar_academico()` ejecuta cada cambio y su recibo en la misma
transacción, mantiene RLS y rechaza revisiones antiguas con `SYNC_CONFLICT`.
Las ediciones directas de clases y asistencias también incrementan la revisión
de su evaluación. La cola nunca modifica aprobaciones ni configuración.

La prueba autenticada deja un recibo técnico de sincronización en la cuenta de
prueba y elimina su borrador temporal. Los recibos son inmutables para el cliente.
