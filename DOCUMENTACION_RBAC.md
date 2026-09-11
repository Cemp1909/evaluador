# RBAC: contrato de autorización

## Regla principal

El cliente usa `lib/security/rbac.dart` como matriz única de permisos. Las rutas
están envueltas por `PermissionGate` y las mutaciones de `SesionProvider`
vuelven a validar el permiso. Ocultar una opción del menú **no** se considera
autorización.

| Rol | Alcance |
|---|---|
| Administrador | Todos los permisos: usuarios, roles, configuración, institución, estructura académica, evaluaciones, reportes, IA y auditoría. |
| Coordinador | Solo estructura y operación académica: grados/cursos/materias, asignación docente, evaluaciones, resultados asignados, banco académico y reportes académicos. No administra usuarios ni sistema. |
| Profesor | Solo trabajo propio: crear evaluaciones, resultados asignados, preguntas propias, IA y perfil. |

La creación de profesores exige el permiso real `administrarUsuarios`, que el
coordinador no posee. Administrador: puede crear y aprobar profesores.
Coordinador: puede consultar únicamente los profesores de su zona, pero no puede
crearlos ni registrarlos, incluso mediante la ruta de solicitud pública.
Profesor: no puede crear ni consultar la gestión de profesores.
El autorregistro público existente se conserva para los demás usuarios.

## Backend obligatorio para producción

Esta aplicación aún no contiene backend; por tanto el RBAC Flutter es una capa
de experiencia y defensa local, no una frontera de seguridad. El API debe
validar el token, el rol y el permiso en **cada** endpoint, además de validar
propiedad/asignación de curso para un profesor.

Esquema mínimo (los IDs deben ser UUID o equivalentes):

```sql
CREATE TABLE roles (id UUID PRIMARY KEY, nombre TEXT UNIQUE NOT NULL);
CREATE TABLE permissions (id UUID PRIMARY KEY, nombre_permiso TEXT UNIQUE NOT NULL);
CREATE TABLE role_permissions (
  rol_id UUID REFERENCES roles(id) ON DELETE CASCADE,
  permiso_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (rol_id, permiso_id)
);
CREATE TABLE users (
  id UUID PRIMARY KEY,
  nombre TEXT NOT NULL,
  correo TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  rol_id UUID NOT NULL REFERENCES roles(id),
  estado TEXT NOT NULL CHECK (estado IN ('activo', 'inactivo'))
);
```

Complementar con tablas de asignación (`profesor_curso`), propietarios de
evaluación (`evaluaciones.creado_por`) y auditoría. Nunca almacenar
contraseñas en texto plano: usar Argon2id o bcrypt. El middleware debe devolver
401 sin sesión, 403 sin permiso, y 404/403 si el recurso no pertenece al curso
asignado.

## Middleware de referencia

```text
authenticate() -> valida token, estado activo y carga usuario
authorize('evaluaciones.crear') -> verifica role_permissions
scopeCourse() -> administrador: todo; coordinador: cursos asignados;
                 profesor: solo profesor_curso y creado_por = usuario.id
audit() -> registra usuario, acción, recurso, fecha e IP
```

No se deben empaquetar credenciales administrativas en `.env` como assets en
una distribución de producción; el inicio de sesión debe migrar al backend.
