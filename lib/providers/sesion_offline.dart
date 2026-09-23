part of 'sesion_provider.dart';

extension SesionOffline on SesionProvider {
  bool get offlineHabilitado => offlineFactory != null;
  bool get sinConexion => _sync?.sinConexion ?? false;
  bool get sincronizando => _sync?.sincronizando ?? false;
  int get cambiosPendientes => _sync?.operaciones.length ?? 0;
  List<Map<String, dynamic>> get conflictos => List.unmodifiable(
    _sync?.operaciones.where((op) => op['error'] != null) ?? [],
  );
  String get estadoGuardado =>
      _sync?.ultimoError ??
      (sinConexion
          ? cambiosPendientes > 0
                ? 'Sin conexión · $cambiosPendientes cambios pendientes guardados en este dispositivo.'
                : 'Sin conexión · Mostrando la última copia guardada.'
          : sincronizando
          ? 'Sincronizando con Supabase…'
          : cambiosPendientes > 0
          ? '$cambiosPendientes cambios guardados en este dispositivo, pendientes de Supabase.'
          : 'Cambios sincronizados con Supabase');

  Future<void> sincronizarCambios({bool reintentar = false}) async {
    if (reintentar) await _offline?.reintentar();
    await _sync?.sincronizar();
  }

  Future<String?> usarVersionServidor(Map<String, dynamic> operacion) async {
    if (_restaurando || _saliendo || _offline == null) {
      return 'Espera a que termine la sincronización.';
    }
    _restaurando = true;
    await _sync?.cerrar();
    _sync = null;
    try {
      final snapshot = _snapshot();
      final recurso = operacion['recurso'] as String;
      switch (operacion['tipo']) {
        case 'evaluacion':
          final remotas = await _repositorio!.cargarEvaluaciones().timeout(
            const Duration(seconds: 45),
          );
          final local =
              (snapshot['evaluaciones'] as List).cast<Map<String, dynamic>>()
                ..removeWhere((e) => e['id'] == recurso);
          local.addAll(
            remotas
                .where((e) => e.identificador == recurso)
                .map(OfflineCodec.evaluacion),
          );
        case 'reporte':
          final remotos = await _repositorio!.cargarReportes().timeout(
            const Duration(seconds: 45),
          );
          final local =
              (snapshot['reportes'] as List).cast<Map<String, dynamic>>()
                ..removeWhere((e) => e['id'] == recurso);
          local.addAll(
            remotos.where((r) => r.id == recurso).map(OfflineCodec.reporte),
          );
        case 'borrador':
          snapshot['borrador'] = (await _repositorio!.cargarBorrador().timeout(
            const Duration(seconds: 30),
          ))?.toJson();
      }
      snapshot['revisiones'] = _repositorio!.revisiones;
      await _offline!.descartar(
        operacion['entidad'] as String,
        snapshot: snapshot,
      );
      await _restaurarOffline(desconectado: false);
      return null;
    } catch (_) {
      if (_sync == null) await _iniciarSync();
      return 'No se pudo descargar la versión de Supabase. Tus cambios siguen guardados.';
    } finally {
      _restaurando = false;
      _notificarOffline();
    }
  }

  Future<void> _abrirOffline(String uid) async {
    if (offlineFactory == null) return;
    if (_offline != null && _offlineUid == uid) return;
    await _sync?.cerrar();
    _sync = null;
    await _offline?.cerrar();
    _offline = null;
    _offline = await offlineFactory!(uid);
    _offlineUid = uid;
  }

  Future<void> _iniciarSync({bool desconectado = false}) async {
    final uid = _offlineUid!;
    _sync = SyncEngine(
      _offline!,
      comprobarSesion: () async {
        final client = _supabaseClient!;
        if (client.auth.currentUser?.id != uid || _saliendo) {
          throw const AuthException('La sesión cambió');
        }
        if (client.auth.currentSession?.isExpired ?? true) {
          await client.auth.refreshSession().timeout(
            const Duration(seconds: 20),
          );
        }
        final perfil = await client
            .from('perfiles')
            .select('activo, rol')
            .eq('id', uid)
            .single()
            .timeout(const Duration(seconds: 20));
        if (perfil['activo'] != true ||
            perfil['rol'] != _usuarioActual?.rol.name) {
          throw const AuthException(
            'El perfil cambió. Inicia sesión de nuevo.',
          );
        }
      },
      enviar: (op) => _repositorio!.enviarOperacion(op),
    );
    _sync!.sinConexion = desconectado;
    _sync!.addListener(_notificarOffline);
    await _sync!.iniciar();
    if (!desconectado) unawaited(_sync!.sincronizar());
  }

  Future<void> _encolar(
    String tipo,
    String recurso,
    Map<String, dynamic> data,
  ) async {
    if (_saliendo ||
        _restaurando ||
        (_sync?.ultimoError != null && !sinConexion) ||
        _offlineUid != _supabaseClient?.auth.currentUser?.id) {
      throw StateError('La sesión cambió');
    }
    if (_validadoEn == null ||
        DateTime.now().difference(_validadoEn!) > const Duration(days: 7)) {
      throw StateError('Conéctate para validar la sesión antes de continuar.');
    }
    await _offline!.encolar(
      tipo,
      recurso,
      data,
      _repositorio!.revisiones['$tipo:$recurso'] ?? 0,
    );
    await _sync!.actualizar();
    unawaited(_sync!.sincronizar());
  }

  Future<void> _guardarEvaluacionRemotaOLocal(Evaluacion e) async {
    if (_offline == null) {
      await _repositorio!.guardarEvaluacion(e);
      return;
    }
    await _encolar('evaluacion', e.identificador, OfflineCodec.evaluacion(e));
  }

  Map<String, dynamic> _snapshot() => {
    'uid': _offlineUid,
    'validado': _validadoEn!.toIso8601String(),
    'rol': _usuarioActual!.rol.name,
    'nombre': _usuarioActual!.nombre,
    'zona': _usuarioActual!.zona,
    'configuracion': OfflineCodec.configuracion(_configuracionNotas),
    'profesores': [
      for (final p in _profesoresRemotos)
        {
          'nombre': p.nombre,
          'usuario': p.usuario,
          'zona': p.zona,
          'aprobado': p.aprobado,
        },
    ],
    'colegios': _nombresColegios,
    'docentes': _docentesColegios.map(
      (k, v) => MapEntry(k, v.map((d) => d.toJson()).toList()),
    ),
    'contactos': _contactosColegios.map(
      (k, v) => MapEntry(k, {
        'ciudad': v.ciudad,
        'direccion': v.direccion,
        'telefono': v.telefono,
      }),
    ),
    'visitas': _visitas.map(OfflineCodec.visita).toList(),
    'fechas': _fechasBloqueadas.map((d) => d.toIso8601String()).toList(),
    'evaluaciones': _borradoresEvaluacion.values
        .map(OfflineCodec.evaluacion)
        .toList(),
    'reportes': _reportesConocimiento.map(OfflineCodec.reporte).toList(),
    'borrador': _borradorConocimiento?.toJson(),
    'revisiones': _repositorio!.revisiones,
  };

  Future<bool> _restaurarOffline({bool desconectado = true}) async {
    final d = await _offline?.leer('sesion');
    if (d == null || d['uid'] != _supabaseClient?.auth.currentUser?.id) {
      return false;
    }
    if (_usuarioActual != null &&
        (_usuarioActual!.rol.name != d['rol'] ||
            _usuarioActual!.zona != d['zona'])) {
      return false;
    }
    final fecha = DateTime.parse(d['validado'] as String);
    if (DateTime.now().difference(fecha) > const Duration(days: 7)) {
      return false;
    }
    _validadoEn = fecha;
    _usuarioActual = UsuarioSesion(
      rol: RolUsuario.values.byName(d['rol'] as String),
      nombre: d['nombre'] as String,
      zona: d['zona'] as String?,
    );
    _configuracionNotas = ConfiguracionNotas.fromDatabase(
      Map<String, dynamic>.from(d['configuracion'] as Map),
    );
    _profesoresRemotos = [
      for (final p in d['profesores'] as List? ?? [])
        Profesor(
          nombre: p['nombre'] as String,
          usuario: p['usuario'] as String,
          password: '',
          zona: p['zona'] as String,
          aprobado: p['aprobado'] as bool,
        ),
    ];
    _nombresColegios
      ..clear()
      ..addAll(Map<String, String>.from(d['colegios'] as Map));
    _docentesColegios
      ..clear()
      ..addAll(
        (d['docentes'] as Map).map(
          (k, v) => MapEntry(k as String, [
            for (final item in v as List)
              DocenteColegio.fromJson(Map<String, dynamic>.from(item as Map)),
          ]),
        ),
      );
    _contactosColegios
      ..clear()
      ..addAll(
        (d['contactos'] as Map).map(
          (k, v) => MapEntry(
            k as String,
            ContactoColegio(
              ciudad: v['ciudad'] as String,
              direccion: v['direccion'] as String,
              telefono: v['telefono'] as String,
            ),
          ),
        ),
      );
    _visitas
      ..clear()
      ..addAll([
        for (final v in d['visitas'] as List)
          OfflineCodec.leerVisita(Map<String, dynamic>.from(v as Map)),
      ]);
    _fechasBloqueadas
      ..clear()
      ..addAll([
        for (final v in d['fechas'] as List) DateTime.parse(v as String),
      ]);
    _borradoresEvaluacion.clear();
    for (final v in d['evaluaciones'] as List) {
      final e = OfflineCodec.leerEvaluacion(
        Map<String, dynamic>.from(v as Map),
      );
      _borradoresEvaluacion[e.identificador] = e;
    }
    _reportesConocimiento
      ..clear()
      ..addAll([
        for (final v in d['reportes'] as List)
          OfflineCodec.leerReporte(Map<String, dynamic>.from(v as Map)),
      ]);
    _borradorConocimiento = d['borrador'] == null
        ? null
        : StudentKnowledgeDraft.fromJson(
            Map<String, dynamic>.from(d['borrador'] as Map),
          );
    _repositorio!.revisiones
      ..clear()
      ..addAll(Map<String, int>.from(d['revisiones'] as Map));
    await _aplicarPendientes();
    await _iniciarSync(desconectado: desconectado);
    return true;
  }

  Future<void> _aplicarPendientes() async {
    for (final item in await _offline!.entidades()) {
      final data = Map<String, dynamic>.from(item['datos'] as Map);
      switch (item['tipo']) {
        case 'evaluacion':
          final e = OfflineCodec.leerEvaluacion(data);
          _borradoresEvaluacion[e.identificador] = e;
        case 'reporte':
          final r = OfflineCodec.leerReporte(data);
          _reportesConocimiento.removeWhere((v) => v.id == r.id);
          _reportesConocimiento.add(r);
        case 'borrador':
          _borradorConocimiento = data['eliminado'] == true
              ? null
              : StudentKnowledgeDraft.fromJson(
                  Map<String, dynamic>.from(data['datos'] as Map),
                );
      }
    }
  }
}
