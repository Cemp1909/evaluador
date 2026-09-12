import '../models/usuario_sesion.dart';

/// Acciones de negocio. Las pantallas deben consultar estos permisos, no roles
/// directamente, salvo para mostrar información de perfil.
enum Permiso {
  administrarUsuarios,
  administrarRoles,
  configurarSistema,
  gestionarInstitucion,
  gestionarEstructuraAcademica,
  asignarProfesores,
  crearEvaluaciones,
  editarTodasLasEvaluaciones,
  publicarEvaluaciones,
  verTodosLosResultados,
  verResultadosAsignados,
  generarReportesGenerales,
  generarReportesAcademicos,
  administrarBancoPreguntas,
  administrarPreguntasPropias,
  usarIa,
  verAuditoria,
  gestionarAgenda,
  actualizarPerfil,
}

/// Única matriz RBAC del cliente. El servidor debe replicar esta misma matriz.
class Rbac {
  const Rbac._();

  static final Map<RolUsuario, Set<Permiso>> matriz = {
    RolUsuario.administrador: Set<Permiso>.unmodifiable(Permiso.values),
    RolUsuario.coordinador: {
      Permiso.gestionarEstructuraAcademica,
      Permiso.asignarProfesores,
      Permiso.crearEvaluaciones,
      Permiso.editarTodasLasEvaluaciones,
      Permiso.publicarEvaluaciones,
      Permiso.verResultadosAsignados,
      Permiso.generarReportesAcademicos,
      Permiso.administrarBancoPreguntas,
      Permiso.gestionarAgenda,
      Permiso.actualizarPerfil,
    },
    RolUsuario.profesor: {
      Permiso.crearEvaluaciones,
      Permiso.verResultadosAsignados,
      Permiso.administrarPreguntasPropias,
      Permiso.usarIa,
      Permiso.gestionarAgenda,
      Permiso.actualizarPerfil,
    },
  };

  // Crear profesores usa administrarUsuarios, exclusivo del administrador.
  // La solicitud pública se conserva, pero nunca habilita al coordinador.
  static bool puedeCrearProfesores(UsuarioSesion? usuario) =>
      tiene(usuario, Permiso.administrarUsuarios);

  static bool puedeRegistrarSolicitudProfesor(UsuarioSesion? usuario) =>
      usuario?.rol != RolUsuario.coordinador;

  static bool puedeConsultarProfesores(UsuarioSesion? usuario) =>
      usuario?.rol == RolUsuario.administrador ||
      usuario?.rol == RolUsuario.coordinador;

  static bool tiene(UsuarioSesion? usuario, Permiso permiso) =>
      usuario != null && (matriz[usuario.rol] ?? const {}).contains(permiso);
}
