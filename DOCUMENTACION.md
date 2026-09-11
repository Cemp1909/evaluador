# Documentación de `evaluador_app`

## 1. Descripción general

`evaluador_app` es una aplicación multiplataforma de **Course Child** para apoyar la evaluación académica y la gestión operativa de capacitaciones, docentes, colegios y visitas.

Permite evaluar capacitaciones de docentes de preescolar y primaria, evaluar conocimientos por grado y período, registrar docentes, programar visitas, consolidar indicadores por colegio y generar informes PDF con firmas y evidencias fotográficas.

> Estado actual: es una aplicación funcional con información guardada en memoria durante la sesión. Aún no tiene una base de datos ni un backend conectado.

## 2. Tecnologías

| Tecnología | Uso dentro del proyecto |
|---|---|
| Flutter | Desarrollo de la interfaz y la aplicación multiplataforma |
| Dart | Lenguaje principal |
| Material Design | Componentes visuales y navegación |
| Provider | Estado global reactivo (`SesionProvider`) |
| flutter_dotenv | Carga de credenciales y configuración desde archivos `.env` |
| signature | Captura de firmas manuscritas |
| image_picker | Cámara y galería para evidencias fotográficas |
| pdf | Construcción de documentos PDF |
| printing | Vista previa, impresión y compartición de PDFs |
| google_fonts | Tipografía de la interfaz |
| url_launcher | Apertura de ubicaciones en Google Maps |
| flutter_test | Pruebas unitarias y de widgets |
| flutter_lints | Análisis estático y reglas de estilo |

El proyecto declara Dart `^3.11.4` y versión de aplicación `1.0.0+1`.

## 3. Plataformas soportadas

El repositorio incluye configuración para Android, iOS, Web, macOS, Windows y Linux.

## 4. Arquitectura

```text
Pantallas y widgets
  lib/screens + lib/widgets
          |
          v
Estado global en memoria
  lib/providers/sesion_provider.dart
          |
          v
Lógica de negocio y exportación
  lib/services
          |
          v
Modelos, plantillas y configuración
  lib/models + lib/config
```

### Estructura de carpetas

```text
evaluador_app/
├── assets/                 Logo y fuentes locales
├── lib/
│   ├── config/             Credenciales, evaluadores y planes de estudio
│   ├── models/             Entidades del dominio
│   ├── providers/          Estado compartido de la sesión
│   ├── screens/            Pantallas y flujos de usuario
│   ├── services/           Lógica de evaluaciones y PDFs
│   ├── theme/              Colores, espaciado y tipografía
│   ├── widgets/            Componentes reutilizables
│   └── main.dart           Punto de entrada
├── test/                   Pruebas automatizadas
├── android/, ios/, web/    Configuración por plataforma
├── macos/, windows/, linux/
└── pubspec.yaml            Dependencias y recursos
```

## 5. Inicio de la aplicación y sesión

El punto de entrada es `lib/main.dart`. Al iniciar:

1. Carga el archivo de entorno indicado por `ENV_FILE`; por defecto, `.env`.
2. Construye `AuthConfig` con las credenciales configuradas.
3. Registra `SesionProvider` mediante `ChangeNotifierProvider`.
4. Muestra la pantalla de inicio de sesión.

La aplicación oculta su contenido cuando queda en segundo plano. Si permanece fuera durante cinco minutos o más, cierra la sesión por seguridad.

## 6. Roles y permisos

| Funcionalidad | Administrador | Coordinador | Profesor |
|---|:---:|:---:|:---:|
| Realizar capacitaciones | Sí | Sí | Sí |
| Evaluar conocimientos | Sí | Sí | Sí |
| Consultar historial y comparaciones | Sí | Sí | No desde su menú principal |
| Crear profesores | Sí | No | No |
| Ver profesores | Todos | Solo su zona | No |
| Aprobar profesores | Sí | No | No |
| Aprobar reportes | No | Sí | No |
| Configurar escala de notas | Sí | No | No |
| Gestionar agenda | Sí | Sí | Sí |
| Consultar panel de colegios | Sí | Sí | No desde su menú principal |

Los profesores registrados mediante solicitud pública deben ser aprobados por un administrador antes de poder ingresar.

## 7. Autenticación y configuración

Las credenciales se cargan desde `.env`, `.env.public-demo` o un archivo definido en tiempo de compilación.

Variables reconocidas:

```dotenv
ADMIN_USERNAME=
ADMIN_PASSWORD=
COORDINADOR_USERNAME=
COORDINADOR_PASSWORD=
COORDINADOR_ZONA=
DEMO_PROFESOR_USERNAME=
DEMO_PROFESOR_PASSWORD=
DEMO_PROFESOR_NOMBRE=
DEMO_PROFESOR_ZONA=
```

Archivos relacionados:

- `lib/config/auth_config.dart`: modelo de configuración.
- `.env.example`: plantilla para crear una configuración local.
- `.env.public-demo`: configuración destinada a demostraciones.

### Consideraciones de seguridad

- La autenticación es local; no usa servidor, tokens ni recuperación de contraseña.
- Las contraseñas de profesores se mantienen en memoria y no se cifran.
- Los secretos no deberían incluirse como recursos en una distribución de producción.
- Para producción se recomienda autenticación remota, contraseñas con hash y reglas de autorización en backend.

## 8. Módulos funcionales

### 8.1 Inicio de sesión

Pantalla: `lib/screens/login_screen.dart`.

- Valida usuario y contraseña.
- Identifica los roles administrador, coordinador y profesor.
- Permite solicitar acceso como profesor.
- Dirige al panel correspondiente según el rol.

### 8.2 Gestión de profesores

Pantallas: `crear_profesor_screen.dart` y `profesores_screen.dart`.

Funciones:

- Crear profesores con nombre, usuario, contraseña y zona.
- Solicitar acceso público como profesor.
- Validar campos obligatorios y contraseña mínima de seis caracteres.
- Evitar usuarios duplicados o reservados.
- Aprobar profesores pendientes desde la cuenta administradora.
- Filtrar profesores aprobados y pendientes.
- El coordinador puede consultar únicamente los profesores de su zona, pero no puede crearlos ni registrarlos.
- El profesor no puede crear ni consultar la gestión de profesores.

### 8.3 Evaluación de capacitaciones

Pantallas principales:

- `evaluador_selection_screen.dart`
- `clases_screen.dart`
- `clase_detail_screen.dart`
- `clase_pdf_preview_screen.dart`

Existen dos plantillas de capacitación:

| Evaluador | Número de clases |
|---|---:|
| Capacitación preescolar | 6 |
| Capacitación primaria | 11 |

Cada clase contiene bloques configurables como Songs, Dialogues, Commands, Vocabulary, Grammar, Questions, Teaching Strategy y ABC.

Flujo:

1. Seleccionar el nivel de capacitación.
2. Abrir una clase del plan.
3. Marcar bloques o contenidos enseñados.
4. Escoger el bloque válido cuando hay opciones `Songs 1` y `Songs 2`.
5. Registrar observaciones.
6. Capturar firma del representante y de docentes asistentes.
7. Adjuntar hasta dos fotografías.
8. Revisar y generar el PDF de la clase.

Estados de una evaluación: `borrador`, `enProgreso` y `completada`.

La aplicación genera observaciones automáticas para mostrar contenidos no enseñados. Las plantillas están en `lib/config/evaluadores_config.dart`.

### 8.4 Evaluación de conocimientos

Pantalla: `lib/screens/student_knowledge_report_screen.dart`.

Permite evaluar conocimientos por colegio, docente, grado, período y contenido.

Grados configurados:

- Párvulos
- Prejardín
- Jardín
- Transición

Cada grado tiene cuatro períodos y categorías académicas como Commands, Songs, Dialogue y Vocabulary.

Cada contenido puede quedar como:

- Logrado
- Por reforzar
- No logrado
- No evaluado

Funciones adicionales:

- Modo de evaluación rápida.
- Calificación masiva por categoría.
- Comentarios por contenido.
- Compromiso de mejoramiento.
- Sugerencias pedagógicas automáticas.
- Tres firmas: colegio, docente del colegio y docente de Course Child.
- Hasta dos fotos de evidencia, asociables a contenidos.
- Borrador durante la sesión.
- Confirmación final antes de guardar.
- PDF resumido o detallado.

Planes de estudio:

- `lib/config/plan_estudio_parvulos.dart`
- `lib/config/planes_estudio_adicionales.dart`

### 8.5 Cálculo de calificaciones

Configuración predeterminada:

| Resultado | Puntaje |
|---|---:|
| Logrado | 5.0 |
| Por reforzar | 3.0 |
| No logrado | 1.0 |

La nota final es el promedio de los contenidos evaluados; los no evaluados no cuentan en el cálculo.

| Rango de nota | Desempeño |
|---|---|
| 4.6 a 5.0 | Superior |
| 4.0 a 4.5 | Alto |
| 3.0 a 3.9 | Básico |
| Menor de 3.0 | Bajo |

El administrador puede cambiar puntajes, límites de desempeño y cobertura mínima desde `configuracion_notas_screen.dart`. Esos cambios solo viven durante la sesión actual.

### 8.6 Historial, comparación y panel de colegios

Pantallas:

- `historial_estudiantes_screen.dart`
- `comparacion_periodos_screen.dart`
- `panel_colegios_screen.dart`

Permiten:

- Filtrar reportes por colegio, grado y período.
- Consultar evaluaciones anteriores.
- Comparar resultados entre períodos.
- Revisar nota, cobertura y contenidos pendientes.
- Abrir el PDF de un reporte.
- Aprobar y firmar un reporte desde el rol coordinador.
- Consolidar evaluaciones, promedio y contenidos críticos por institución.

### 8.7 Agenda de visitas

Pantalla: `lib/screens/agenda_visitas_screen.dart`.

La agenda se puede consultar por mes, semana, colegio o profesor.

Tipos de actividad:

- Evaluación por colegio.
- Capacitación preescolar.
- Capacitación primaria.
- English Day.
- Ensayo de English Day.

Estados de una visita:

- Programada.
- Pendiente de confirmación.
- Confirmada.
- Realizada.
- Cancelada.
- Reprogramada.

Funciones:

- Crear, editar, completar, cancelar y reprogramar actividades.
- Registrar motivo de cancelación.
- Asignar responsable, acompañantes, duración, ubicación y observaciones.
- Abrir ubicaciones en Google Maps.
- Bloquear fechas de agenda.
- Crear automáticamente series de clases, semanales o quincenales.
- Reprogramar una serie desde una clase determinada.
- Detectar conflictos de horario por profesor.
- Evitar duplicados de clase o período por colegio.
- Mostrar recordatorios, próximas actividades y actividades atrasadas.

Reglas específicas:

- Capacitación preescolar: hasta 6 clases.
- Capacitación primaria: hasta 11 clases.
- Máximo de 3 fechas de English Day por colegio.
- Máximo de 3 ensayos de English Day por colegio.

### 8.8 PDFs, firmas y evidencia

Servicio: `lib/services/pdf_export_service.dart`.

Se generan PDFs para:

- Clase individual de capacitación.
- Evaluación completa de capacitación.
- Reporte de conocimientos.

Los informes pueden incluir logo, datos de la evaluación, calificaciones, contenidos, observaciones, compromisos, firmas, aprobación de coordinación y fotografías.

Las firmas se capturan con `SignatureCaptureDialog`; las fotos provienen de la cámara o de la galería. Los PDFs se pueden previsualizar, imprimir y compartir.

## 9. Estado global y persistencia

`SesionProvider` es el estado central de la aplicación. Conserva:

- Usuario autenticado.
- Profesores registrados.
- Reportes de conocimiento.
- Borradores de capacitación.
- Borrador de conocimiento.
- Configuración de notas.
- Visitas programadas.
- Fechas bloqueadas.

Todo lo anterior se mantiene únicamente durante la ejecución actual. Al cerrar o reiniciar la aplicación se pierden profesores, aprobaciones, reportes, agenda, borradores, firmas, fotos y configuración.

Algunos modelos incluyen `toJson` y `fromJson`, pero no hay una capa que persista la información. `EvaluacionService` indica explícitamente que la persistencia offline y una eventual integración con Supabase se conectarían allí.

## 10. Modelos de dominio

| Modelo | Responsabilidad |
|---|---|
| `UsuarioSesion` | Usuario autenticado, rol y zona |
| `Profesor` | Profesor registrado y aprobación |
| `EvaluadorTipo` | Plantilla de capacitación |
| `Clase` | Clase de un plan de capacitación |
| `Bloque` | Grupo de contenidos |
| `ItemReferencia` | Contenido individual |
| `Evaluacion` | Evaluación completa de capacitación |
| `EvaluacionClase` | Resultado de una clase |
| `EvaluacionBloque` | Estado de bloque y sus ítems |
| `FirmaDocente` | Nombre y firma digital |
| `StudentKnowledgeDraft` | Borrador de una evaluación de conocimientos |
| `StudentKnowledgeReport` | Reporte final de conocimientos |
| `ConfiguracionNotas` | Puntajes, rangos y cobertura |
| `VisitaProgramada` | Actividad de agenda |

Los modelos se encuentran en `lib/models/`.

## 11. Instalación y ejecución

### Requisitos

- Flutter compatible con Dart `3.11.4`.
- Herramientas de la plataforma destino: Android Studio, Xcode, Chrome, etc.

### Preparación

```bash
flutter doctor
flutter pub get
cp .env.example .env
```

Completa las variables necesarias en `.env` antes de ejecutar.

### Ejecución

```bash
flutter run
```

Para Web:

```bash
flutter run -d chrome
```

Para usar la configuración pública de demostración:

```bash
flutter run --dart-define=ENV_FILE=.env.public-demo
```

### Compilación

```bash
flutter build apk
flutter build appbundle
flutter build ios
flutter build web
flutter build macos
flutter build windows
flutter build linux
```

La disponibilidad de cada destino depende del sistema operativo y de las herramientas instaladas.

## 12. Pruebas

El directorio `test/` cubre, entre otros aspectos:

- Inicio de sesión y roles.
- Creación, aprobación y visibilidad de profesores.
- Cálculo de notas y rangos de desempeño.
- Borradores y configuración local.
- Evaluaciones de capacitación y bloques de canciones.
- Firmas y límite de evidencia fotográfica.
- Planes de estudio.
- Agenda, conflictos y reprogramaciones.
- Generación de PDF.
- Widgets principales.

Comandos recomendados:

```bash
flutter analyze
flutter test
```

## 13. Pendientes para producción

1. Integrar backend y base de datos.
2. Persistir usuarios, evaluaciones, agenda, firmas y fotos.
3. Implementar autenticación segura en servidor.
4. Guardar contraseñas con hash, nunca en texto plano.
5. Aplicar autorización por rol también desde el backend.
6. Almacenar evidencias en un repositorio privado.
7. Agregar sincronización offline y manejo de conflictos.
8. Gestionar colegios, zonas y usuarios como entidades persistentes.
9. Añadir pruebas de integración en dispositivos reales.
10. Revisar permisos de cámara, galería y mapas por plataforma.

## 14. Archivos relevantes

| Archivo | Propósito |
|---|---|
| `lib/main.dart` | Arranque, rutas y protección de sesión |
| `lib/providers/sesion_provider.dart` | Estado global, usuarios, agenda y reportes |
| `lib/services/evaluacion_service.dart` | Lógica de evaluación de capacitaciones |
| `lib/services/pdf_export_service.dart` | Construcción y compartición de PDFs |
| `lib/config/evaluadores_config.dart` | Planes de capacitación preescolar y primaria |
| `lib/config/plan_estudio_parvulos.dart` | Plan académico de Párvulos |
| `lib/config/planes_estudio_adicionales.dart` | Planes de Prejardín, Jardín y Transición |
| `lib/config/auth_config.dart` | Lectura de credenciales desde el entorno |
| `pubspec.yaml` | Dependencias, versión y recursos |

