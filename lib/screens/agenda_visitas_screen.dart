import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/visita_programada.dart';
import '../providers/sesion_provider.dart';
import '../theme/app_theme.dart';

class AgendaVisitasScreen extends StatefulWidget {
  const AgendaVisitasScreen({super.key});
  static const routeName = '/agenda_visitas';

  @override
  State<AgendaVisitasScreen> createState() => _AgendaVisitasScreenState();
}

class _AgendaVisitasScreenState extends State<AgendaVisitasScreen> {
  DateTime? _diaSeleccionado;
  DateTime _mesVisible = DateTime(DateTime.now().year, DateTime.now().month);
  int _vista = 0;
  String? _tipoFiltro;
  EstadoVisita? _estadoFiltro;
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    final visitas = sesion.visitas;
    final ahora = DateTime.now();
    final recordatorios = sesion.actividadesProximas(
      ahora,
      ventana: const Duration(hours: 2),
    );
    final atrasadas = sesion.actividadesAtrasadas(ahora);
    final visibles = _filtrar(visitas);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de evaluaciones'),
        actions: [
          IconButton(
            tooltip: 'Bloquear fecha',
            onPressed: () => _gestionarFechaBloqueada(context),
            icon: const Icon(Icons.event_busy_outlined),
          ),
          IconButton(
            tooltip: 'Filtros',
            onPressed: () => _mostrarFiltros(context),
            icon: const Icon(Icons.filter_list_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _crear(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Programar visita'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Mes')),
              ButtonSegment(value: 1, label: Text('Semana')),
              ButtonSegment(value: 2, label: Text('Colegio')),
              ButtonSegment(value: 3, label: Text('Profesor')),
            ],
            selected: {_vista},
            onSelectionChanged: (value) => setState(() => _vista = value.first),
          ),
          const SizedBox(height: 16),
          if (recordatorios.isNotEmpty)
            _AvisoAgenda(
              icon: Icons.notifications_active_outlined,
              titulo: 'Recordatorio: actividad en menos de 2 horas',
              detalle: recordatorios
                  .map((visita) => '${visita.colegio} · ${_hora(visita.fecha)}')
                  .join('\n'),
              color: AppColors.pendingContainer,
            ),
          if (atrasadas.isNotEmpty)
            _AvisoAgenda(
              icon: Icons.warning_amber_rounded,
              titulo: '${atrasadas.length} actividades atrasadas',
              detalle: 'Revisa y marca como realizada, cancela o reprograma.',
              color: Theme.of(context).colorScheme.errorContainer,
            ),
          if (_vista <= 1) ...[
            _LeyendaTipos(visitas: visitas),
            const SizedBox(height: 12),
          ],
          if (_vista == 0) ...[
            _CalendarioConPuntos(
              mes: _mesVisible,
              seleccionado: _diaSeleccionado,
              visitas: visitas,
              onMesAnterior: () => setState(
                () => _mesVisible = DateTime(
                  _mesVisible.year,
                  _mesVisible.month - 1,
                ),
              ),
              onMesSiguiente: () => setState(
                () => _mesVisible = DateTime(
                  _mesVisible.year,
                  _mesVisible.month + 1,
                ),
              ),
              onSeleccionar: (fecha) => setState(() {
                _diaSeleccionado = fecha;
                _mesVisible = DateTime(fecha.year, fecha.month);
              }),
            ),
            _IndicadoresCalendario(visitas: visitas),
          ] else if (_vista == 1) ...[
            _EncabezadoSemana(
              fechaBase: _diaSeleccionado ?? DateTime.now(),
              visitas: visitas,
              onAnterior: () => setState(() {
                final base = _diaSeleccionado ?? DateTime.now();
                _diaSeleccionado = base.subtract(const Duration(days: 7));
              }),
              onSiguiente: () => setState(() {
                final base = _diaSeleccionado ?? DateTime.now();
                _diaSeleccionado = base.add(const Duration(days: 7));
              }),
              onSeleccionar: (fecha) =>
                  setState(() => _diaSeleccionado = fecha),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            onChanged: (value) => setState(() => _busqueda = value),
            decoration: const InputDecoration(
              hintText: 'Buscar colegio, profesor o actividad',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          if (_vista >= 2)
            ..._grupos(context, visibles, porProfesor: _vista == 3)
          else if (_vista == 1)
            ..._vistaSemanal(context, visibles)
          else if (visibles.isEmpty)
            const Center(child: Text('No hay actividades para esta selección.'))
          else
            for (final visita in visibles) _tarjetaVisita(context, visita),
        ],
      ),
    );
  }

  List<Widget> _vistaSemanal(
    BuildContext context,
    List<VisitaProgramada> visitas,
  ) {
    final base = _diaSeleccionado ?? DateTime.now();
    final inicio = DateTime(
      base.year,
      base.month,
      base.day,
    ).subtract(Duration(days: base.weekday - 1));
    return [
      for (var offset = 0; offset < 7; offset++) ...[
        Builder(
          builder: (context) {
            final dia = inicio.add(Duration(days: offset));
            final actividades =
                visitas.where((visita) => _mismoDia(visita.fecha, dia)).toList()
                  ..sort((a, b) => a.fecha.compareTo(b.fecha));
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(child: Text('${dia.day}')),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_nombreDia(dia.weekday)} · ${_fecha(dia)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text('${actividades.length} actividades'),
                      ],
                    ),
                    if (actividades.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text('Sin actividades programadas.'),
                      )
                    else
                      for (final visita in actividades) ...[
                        const SizedBox(height: 12),
                        _tarjetaVisita(context, visita, interna: true),
                      ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ];
  }

  List<VisitaProgramada> _filtrar(List<VisitaProgramada> visitas) {
    return visitas
        .where((visita) {
          if (_tipoFiltro != null && visita.tipo != _tipoFiltro) return false;
          if (_estadoFiltro != null && visita.estado != _estadoFiltro) {
            return false;
          }
          final texto = _busqueda.trim().toLowerCase();
          if (texto.isNotEmpty &&
              !visita.colegio.toLowerCase().contains(texto) &&
              !visita.profesorResponsable.toLowerCase().contains(texto) &&
              !visita.tipo.toLowerCase().contains(texto)) {
            return false;
          }
          if (_vista == 0 && _diaSeleccionado != null) {
            return _mismoDia(visita.fecha, _diaSeleccionado!);
          }
          if (_vista == 1) {
            final base = _diaSeleccionado ?? DateTime.now();
            final inicio = DateTime(
              base.year,
              base.month,
              base.day,
            ).subtract(Duration(days: base.weekday - 1));
            final fin = inicio.add(const Duration(days: 7));
            return !visita.fecha.isBefore(inicio) && visita.fecha.isBefore(fin);
          }
          return true;
        })
        .toList(growable: false);
  }

  List<Widget> _grupos(
    BuildContext context,
    List<VisitaProgramada> visitas, {
    required bool porProfesor,
  }) {
    final grupos = <String, List<VisitaProgramada>>{};
    for (final visita in visitas) {
      final clave = porProfesor ? visita.profesorResponsable : visita.colegio;
      grupos.putIfAbsent(clave, () => []).add(visita);
    }
    final claves = grupos.keys.toList()..sort();
    return [
      for (final clave in claves)
        Card(
          child: ExpansionTile(
            title: Text(clave),
            subtitle: Text('${grupos[clave]!.length} actividades'),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              for (final visita in grupos[clave]!)
                _tarjetaVisita(context, visita, interna: true),
            ],
          ),
        ),
    ];
  }

  Widget _tarjetaVisita(
    BuildContext context,
    VisitaProgramada visita, {
    bool interna = false,
  }) {
    final color = _colorTipo(visita.tipo);
    final contenido = Container(
      margin: EdgeInsets.only(bottom: interna ? 10 : 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        children: [
          if (visita.cancelada || visita.estado == EstadoVisita.cancelada)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.medium),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel_rounded,
                    color: Theme.of(context).colorScheme.onError,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVIDAD CANCELADA',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onError,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (visita.motivoCancelacion.isNotEmpty)
                          Text(
                            visita.motivoCancelacion,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onError,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: .15),
              child: Icon(_iconoTipo(visita.tipo), color: color),
            ),
            title: Text(visita.colegio),
            subtitle: Text(
              '${_fecha(visita.fecha)} · ${_hora(visita.fecha)}–${_hora(visita.fecha.add(Duration(minutes: visita.duracionMinutos)))}'
              '\n${visita.tipo} · ${_nombreEstado(visita.estado)}'
              '\nProfesor: ${visita.profesorResponsable}'
              '${visita.profesoresAcompanantes.isEmpty ? '' : '\nAcompañantes: ${visita.profesoresAcompanantes.join(', ')}'}'
              '${visita.ubicacion.isEmpty ? '' : '\nLugar: ${visita.ubicacion}'}'
              '${visita.periodo == null ? '' : '\nPeríodo: ${visita.periodo}'}'
              '${visita.numeroClase == null ? '' : '\nClase: ${visita.numeroClase}'}'
              '${visita.ultimaNovedad.isEmpty ? '' : '\nNovedad: ${visita.ultimaNovedad}'}',
            ),
            trailing: PopupMenuButton<EstadoVisita>(
              tooltip: 'Cambiar estado',
              onSelected: (estado) => context
                  .read<SesionProvider>()
                  .actualizarEstadoVisita(visita.id, estado),
              itemBuilder: (_) => EstadoVisita.values
                  .where((estado) => estado != EstadoVisita.cancelada)
                  .map(
                    (estado) => PopupMenuItem(
                      value: estado,
                      child: Text(_nombreEstado(estado)),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editarActividad(context, visita),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _editarResponsables(context, visita),
                  icon: const Icon(Icons.manage_accounts_outlined),
                  label: const Text('Responsables'),
                ),
                if (visita.ubicacion.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _abrirMapa(visita.ubicacion),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Mapa'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _reprogramar(context, visita),
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('Reprogramar'),
                ),
                if (!visita.cancelada)
                  TextButton.icon(
                    onPressed: () => _cancelar(context, visita),
                    icon: const Icon(Icons.event_busy_outlined),
                    label: const Text('Cancelar'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return interna ? contenido : Card(child: contenido);
  }

  Future<void> _mostrarFiltros(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: _tipoFiltro,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(
                    value: 'Evaluación por colegio',
                    child: Text('Evaluación'),
                  ),
                  DropdownMenuItem(
                    value: 'Capacitación preescolar',
                    child: Text('Preescolar'),
                  ),
                  DropdownMenuItem(
                    value: 'Capacitación primaria',
                    child: Text('Primaria'),
                  ),
                  DropdownMenuItem(
                    value: 'English Day',
                    child: Text('English Day'),
                  ),
                  DropdownMenuItem(
                    value: 'Ensayo de English Day',
                    child: Text('Ensayo English Day'),
                  ),
                ],
                onChanged: (value) => modalSetState(() => _tipoFiltro = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EstadoVisita?>(
                initialValue: _estadoFiltro,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  for (final estado in EstadoVisita.values)
                    DropdownMenuItem(
                      value: estado,
                      child: Text(_nombreEstado(estado)),
                    ),
                ],
                onChanged: (value) =>
                    modalSetState(() => _estadoFiltro = value),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('Aplicar filtros'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _gestionarFechaBloqueada(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Bloquear día no disponible',
    );
    if (fecha == null || !context.mounted) return;
    context.read<SesionProvider>().bloquearFecha(fecha);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_fecha(fecha)} quedó bloqueado.')),
    );
  }

  Future<void> _editarResponsables(
    BuildContext context,
    VisitaProgramada visita,
  ) async {
    final profesor = TextEditingController(text: visita.profesorResponsable);
    final acompanantes = TextEditingController(
      text: visita.profesoresAcompanantes.join(', '),
    );
    final ubicacion = TextEditingController(text: visita.ubicacion);
    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Responsables y ubicación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: profesor,
                decoration: const InputDecoration(
                  labelText: 'Profesor responsable',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: acompanantes,
                decoration: const InputDecoration(
                  labelText: 'Profesores acompañantes',
                  hintText: 'Separados por comas',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ubicacion,
                decoration: const InputDecoration(
                  labelText: 'Sede, dirección o punto de encuentro',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (guardar == true && profesor.text.trim().isNotEmpty && context.mounted) {
      context.read<SesionProvider>().actualizarResponsablesVisita(
        id: visita.id,
        profesor: profesor.text,
        acompanantes: acompanantes.text
            .split(',')
            .map((nombre) => nombre.trim())
            .where((nombre) => nombre.isNotEmpty)
            .toList(),
        ubicacion: ubicacion.text,
      );
    }
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      profesor.dispose();
      acompanantes.dispose();
      ubicacion.dispose();
    });
  }

  Future<void> _editarActividad(
    BuildContext context,
    VisitaProgramada visita,
  ) async {
    final colegio = TextEditingController(text: visita.colegio);
    final profesor = TextEditingController(text: visita.profesorResponsable);
    final observacion = TextEditingController(text: visita.observacion);
    var tipo = visita.tipo;
    var fecha = visita.fecha;
    var duracion = visita.duracionMinutos;
    var periodo = visita.periodo ?? 1;
    var numeroClase = visita.numeroClase ?? 1;
    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar actividad'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: colegio,
                  decoration: const InputDecoration(labelText: 'Colegio'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: profesor,
                  decoration: const InputDecoration(
                    labelText: 'Profesor responsable',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Evaluación por colegio',
                      child: Text('Evaluación por colegio'),
                    ),
                    DropdownMenuItem(
                      value: 'Capacitación preescolar',
                      child: Text('Capacitación preescolar'),
                    ),
                    DropdownMenuItem(
                      value: 'Capacitación primaria',
                      child: Text('Capacitación primaria'),
                    ),
                    DropdownMenuItem(
                      value: 'English Day',
                      child: Text('English Day'),
                    ),
                    DropdownMenuItem(
                      value: 'Ensayo de English Day',
                      child: Text('Ensayo de English Day'),
                    ),
                  ],
                  onChanged: (value) => setState(() => tipo = value ?? tipo),
                ),
                const SizedBox(height: 12),
                if (tipo == 'Evaluación por colegio')
                  DropdownButtonFormField<int>(
                    initialValue: periodo,
                    decoration: const InputDecoration(labelText: 'Período'),
                    items: [
                      for (var value = 1; value <= 4; value++)
                        DropdownMenuItem(
                          value: value,
                          child: Text('Período $value'),
                        ),
                    ],
                    onChanged: (value) => periodo = value ?? periodo,
                  )
                else if (_esCapacitacion(tipo))
                  DropdownButtonFormField<int>(
                    key: ValueKey(tipo),
                    initialValue: numeroClase.clamp(
                      1,
                      tipo == 'Capacitación preescolar' ? 6 : 11,
                    ),
                    decoration: const InputDecoration(labelText: 'Clase'),
                    items: [
                      for (
                        var value = 1;
                        value <= (tipo == 'Capacitación preescolar' ? 6 : 11);
                        value++
                      )
                        DropdownMenuItem(
                          value: value,
                          child: Text('Clase $value'),
                        ),
                    ],
                    onChanged: (value) => numeroClase = value ?? numeroClase,
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Fecha'),
                  subtitle: Text(_fecha(fecha)),
                  onTap: () async {
                    final elegida = await showDatePicker(
                      context: context,
                      initialDate: fecha.isBefore(DateTime.now())
                          ? DateTime.now()
                          : fecha,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (elegida != null) {
                      setState(
                        () => fecha = DateTime(
                          elegida.year,
                          elegida.month,
                          elegida.day,
                          fecha.hour,
                          fecha.minute,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Hora'),
                  subtitle: Text(_hora(fecha)),
                  onTap: () async {
                    final elegida = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(fecha),
                    );
                    if (elegida != null) {
                      setState(
                        () => fecha = DateTime(
                          fecha.year,
                          fecha.month,
                          fecha.day,
                          elegida.hour,
                          elegida.minute,
                        ),
                      );
                    }
                  },
                ),
                DropdownButtonFormField<int>(
                  initialValue: duracion,
                  decoration: const InputDecoration(labelText: 'Duración'),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 minutos')),
                    DropdownMenuItem(value: 60, child: Text('1 hora')),
                    DropdownMenuItem(
                      value: 90,
                      child: Text('1 hora 30 minutos'),
                    ),
                    DropdownMenuItem(value: 120, child: Text('2 horas')),
                    DropdownMenuItem(value: 180, child: Text('3 horas')),
                    DropdownMenuItem(value: 240, child: Text('4 horas')),
                  ],
                  onChanged: (value) => duracion = value ?? duracion,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: observacion,
                  decoration: const InputDecoration(labelText: 'Observación'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
    if (guardar == true && context.mounted) {
      if (colegio.text.trim().isEmpty || profesor.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Colegio y profesor son obligatorios.')),
        );
      } else {
        final actualizada = visita.copyWith(
          colegio: colegio.text.trim(),
          profesorResponsable: profesor.text.trim(),
          tipo: tipo,
          fecha: fecha,
          duracionMinutos: duracion,
          periodo: tipo == 'Evaluación por colegio' ? periodo : null,
          numeroClase: _esCapacitacion(tipo) ? numeroClase : null,
          limpiarPeriodo: tipo != 'Evaluación por colegio',
          limpiarNumeroClase: !_esCapacitacion(tipo),
          observacion: observacion.text.trim(),
          ultimaNovedad: 'Actividad editada',
        );
        final error = context.read<SesionProvider>().actualizarVisita(
          actualizada,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Actividad actualizada correctamente.'),
          ),
        );
      }
    }
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      colegio.dispose();
      profesor.dispose();
      observacion.dispose();
    });
  }

  Future<void> _abrirMapa(String ubicacion) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': ubicacion,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps.')),
      );
    }
  }

  Future<void> _cancelar(BuildContext context, VisitaProgramada visita) async {
    final motivo = TextEditingController();
    final accion = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          visita.serieId == null
              ? 'Cancelar o reprogramar'
              : 'Posponer clase y ajustar serie',
        ),
        content: TextField(
          controller: motivo,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Motivo de la cancelación',
            hintText: 'Ejemplo: el colegio suspendió las clases.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'cancelar'),
            child: Text(
              visita.serieId == null ? 'Solo cancelar' : 'Posponer serie',
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, 'reprogramar'),
            icon: const Icon(Icons.edit_calendar_outlined),
            label: const Text('Cancelar y reprogramar'),
          ),
        ],
      ),
    );
    if (accion != null && context.mounted) {
      if (motivo.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe el motivo de la cancelación.')),
        );
      } else if (accion == 'reprogramar') {
        final fechaConHora = await _seleccionarFechaHora(context, visita.fecha);
        if (fechaConHora != null && context.mounted) {
          final error = context.read<SesionProvider>().reprogramarSerieDesde(
            visita.id,
            fechaConHora,
            motivo: motivo.text,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error ??
                    'Actividad reprogramada para ${_fecha(fechaConHora)} a las ${_hora(fechaConHora)}. Motivo: ${motivo.text.trim()}',
              ),
            ),
          );
        }
      } else {
        if (visita.serieId == null) {
          context.read<SesionProvider>().cancelarVisita(visita.id, motivo.text);
        } else {
          final error = context.read<SesionProvider>().posponerSerieDesde(
            visita.id,
            motivo.text,
          );
          if (error != null && context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
          }
        }
      }
    }
    Future<void>.delayed(const Duration(milliseconds: 400), motivo.dispose);
  }

  Future<void> _reprogramar(
    BuildContext context,
    VisitaProgramada visita,
  ) async {
    final fechaConHora = await _seleccionarFechaHora(context, visita.fecha);
    if (fechaConHora == null || !context.mounted) return;
    final error = context.read<SesionProvider>().reprogramarSerieDesde(
      visita.id,
      fechaConHora,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              'Actividad reprogramada para ${_fecha(fechaConHora)} a las ${_hora(fechaConHora)}.',
        ),
      ),
    );
  }

  Future<DateTime?> _seleccionarFechaHora(
    BuildContext context,
    DateTime inicial,
  ) async {
    final base = inicial.isBefore(DateTime.now()) ? DateTime.now() : inicial;
    final fecha = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Selecciona la nueva fecha',
    );
    if (fecha == null || !context.mounted) return null;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(inicial),
      helpText: 'Selecciona la nueva hora',
    );
    if (hora == null) return null;
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  Future<void> _crear(BuildContext context) async {
    final colegio = TextEditingController();
    final profesor = TextEditingController();
    final acompanantes = TextEditingController();
    final ubicacion = TextEditingController();
    final nota = TextEditingController();
    var tipo = 'Evaluación por colegio';
    var periodo = 1;
    var numeroClase = 1;
    var programarSerie = true;
    var intervaloDias = 7;
    var duracionMinutos = 60;
    final manana = DateTime.now().add(const Duration(days: 1));
    var fecha = DateTime(manana.year, manana.month, manana.day, 8);
    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Programar visita'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: colegio,
                  decoration: const InputDecoration(labelText: 'Colegio'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: profesor,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Profesor responsable',
                    hintText: 'Profesor que dará la clase o evaluación',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: acompanantes,
                  decoration: const InputDecoration(
                    labelText: 'Profesores acompañantes (opcional)',
                    hintText: 'Separados por comas',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ubicacion,
                  decoration: const InputDecoration(
                    labelText: 'Sede o dirección',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Evaluación por colegio',
                      child: Text('Evaluación por colegio'),
                    ),
                    DropdownMenuItem(
                      value: 'Capacitación preescolar',
                      child: Text('Capacitación preescolar'),
                    ),
                    DropdownMenuItem(
                      value: 'Capacitación primaria',
                      child: Text('Capacitación primaria'),
                    ),
                    DropdownMenuItem(
                      value: 'English Day',
                      child: Text('English Day'),
                    ),
                    DropdownMenuItem(
                      value: 'Ensayo de English Day',
                      child: Text('Ensayo de English Day'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    tipo = value ?? tipo;
                    numeroClase = 1;
                  }),
                ),
                const SizedBox(height: 12),
                if (tipo == 'Evaluación por colegio')
                  DropdownButtonFormField<int>(
                    initialValue: periodo,
                    decoration: const InputDecoration(
                      labelText: 'Período evaluado',
                      prefixIcon: Icon(Icons.calendar_view_month_outlined),
                    ),
                    items: [
                      for (var value = 1; value <= 4; value++)
                        DropdownMenuItem(
                          value: value,
                          child: Text('Período $value'),
                        ),
                    ],
                    onChanged: (value) => periodo = value ?? 1,
                  )
                else if (tipo == 'Capacitación preescolar' ||
                    tipo == 'Capacitación primaria')
                  Column(
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: numeroClase,
                        decoration: const InputDecoration(
                          labelText: 'Clase inicial',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                        ),
                        items: [
                          for (
                            var value = 1;
                            value <=
                                (tipo == 'Capacitación preescolar' ? 6 : 11);
                            value++
                          )
                            DropdownMenuItem(
                              value: value,
                              child: Text('Clase $value'),
                            ),
                        ],
                        onChanged: (value) => numeroClase = value ?? 1,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: programarSerie,
                        onChanged: (value) =>
                            setState(() => programarSerie = value),
                        title: const Text('Programar clases automáticamente'),
                        subtitle: Text(
                          'Mismo día y hora cada semana hasta la clase ${tipo == 'Capacitación preescolar' ? 6 : 11}.',
                        ),
                      ),
                      if (programarSerie)
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(
                              value: 7,
                              icon: Icon(Icons.view_week_outlined),
                              label: Text('Cada 8 días'),
                            ),
                            ButtonSegment(
                              value: 14,
                              icon: Icon(Icons.calendar_view_week_outlined),
                              label: Text('Cada 15 días'),
                            ),
                          ],
                          selected: {intervaloDias},
                          onSelectionChanged: (value) =>
                              setState(() => intervaloDias = value.first),
                        ),
                    ],
                  ),
                if (tipo == 'English Day' || tipo == 'Ensayo de English Day')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(
                        tipo == 'English Day'
                            ? 'Máximo 3 fechas de English Day por colegio'
                            : 'Máximo 3 ensayos de English Day por colegio',
                      ),
                      subtitle: const Text(
                        'Cada fecha se programa individualmente.',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha'),
                  subtitle: Text(_fecha(fecha)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final elegida = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                      initialDate: fecha,
                    );
                    if (elegida != null) {
                      setState(
                        () => fecha = DateTime(
                          elegida.year,
                          elegida.month,
                          elegida.day,
                          fecha.hour,
                          fecha.minute,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hora'),
                  subtitle: Text(_hora(fecha)),
                  trailing: const Icon(Icons.schedule_outlined),
                  onTap: () async {
                    final elegida = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(fecha),
                    );
                    if (elegida != null) {
                      setState(
                        () => fecha = DateTime(
                          fecha.year,
                          fecha.month,
                          fecha.day,
                          elegida.hour,
                          elegida.minute,
                        ),
                      );
                    }
                  },
                ),
                DropdownButtonFormField<int>(
                  initialValue: duracionMinutos,
                  decoration: const InputDecoration(
                    labelText: 'Duración',
                    prefixIcon: Icon(Icons.timelapse_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 minutos')),
                    DropdownMenuItem(value: 60, child: Text('1 hora')),
                    DropdownMenuItem(
                      value: 90,
                      child: Text('1 hora 30 minutos'),
                    ),
                    DropdownMenuItem(value: 120, child: Text('2 horas')),
                    DropdownMenuItem(value: 180, child: Text('3 horas')),
                    DropdownMenuItem(value: 240, child: Text('4 horas')),
                  ],
                  onChanged: (value) => duracionMinutos = value ?? 60,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nota,
                  decoration: const InputDecoration(
                    labelText: 'Observación (opcional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (guardar == true &&
        colegio.text.trim().isNotEmpty &&
        profesor.text.trim().isNotEmpty &&
        context.mounted) {
      final esCapacitacion =
          tipo == 'Capacitación preescolar' || tipo == 'Capacitación primaria';
      final visita = VisitaProgramada(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        fecha: fecha,
        colegio: colegio.text.trim(),
        tipo: tipo,
        profesorResponsable: profesor.text.trim(),
        periodo: tipo == 'Evaluación por colegio' ? periodo : null,
        numeroClase: esCapacitacion ? numeroClase : null,
        observacion: nota.text.trim(),
        duracionMinutos: duracionMinutos,
        profesoresAcompanantes: acompanantes.text
            .split(',')
            .map((nombre) => nombre.trim())
            .where((nombre) => nombre.isNotEmpty)
            .toList(),
        ubicacion: ubicacion.text.trim(),
        estado: EstadoVisita.pendienteConfirmacion,
      );
      final sesion = context.read<SesionProvider>();
      final error = esCapacitacion && programarSerie
          ? sesion.programarSerieClases(visita, intervaloDias: intervaloDias)
          : sesion.programarVisita(visita);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      } else if (context.mounted) {
        final total = tipo == 'Capacitación preescolar' ? 6 : 11;
        final cantidad = esCapacitacion && programarSerie
            ? total - numeroClase + 1
            : 1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cantidad == 1
                  ? 'Actividad programada correctamente.'
                  : '$cantidad clases programadas semanalmente.',
            ),
          ),
        );
      }
    }
    // El AlertDialog continúa animando sus campos durante unos milisegundos
    // después de que showDialog retorna. Liberarlos de inmediato provoca que
    // AnimatedState intente escuchar un ChangeNotifier ya destruido.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      colegio.dispose();
      profesor.dispose();
      acompanantes.dispose();
      ubicacion.dispose();
      nota.dispose();
    });
  }

  static String _fecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _hora(DateTime fecha) {
    final hora = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
    return '$hora:${fecha.minute.toString().padLeft(2, '0')} ${fecha.hour >= 12 ? 'p. m.' : 'a. m.'}';
  }
}

String _nombreEstado(EstadoVisita estado) => switch (estado) {
  EstadoVisita.programada => 'Programada',
  EstadoVisita.pendienteConfirmacion => 'Pendiente de confirmación',
  EstadoVisita.confirmada => 'Confirmada',
  EstadoVisita.realizada => 'Realizada',
  EstadoVisita.cancelada => 'Cancelada',
  EstadoVisita.reprogramada => 'Reprogramada',
};

bool _esCapacitacion(String tipo) =>
    tipo == 'Capacitación preescolar' || tipo == 'Capacitación primaria';

String _nombreDia(int dia) => const [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
][dia - 1];

String _nombreMes(int mes) => const [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
][mes - 1];

Color _colorTipo(String tipo) => switch (tipo) {
  'Evaluación por colegio' => AppColors.primary,
  'Capacitación preescolar' => AppColors.accent,
  'Capacitación primaria' => AppColors.success,
  'English Day' => const Color(0xFF7357C8),
  'Ensayo de English Day' => AppColors.warning,
  _ => AppColors.neutral600,
};

IconData _iconoTipo(String tipo) => switch (tipo) {
  'Evaluación por colegio' => Icons.fact_check_outlined,
  'Capacitación preescolar' => Icons.child_care_outlined,
  'Capacitación primaria' => Icons.menu_book_outlined,
  'English Day' => Icons.celebration_outlined,
  'Ensayo de English Day' => Icons.theater_comedy_outlined,
  _ => Icons.event_outlined,
};

class _AvisoAgenda extends StatelessWidget {
  const _AvisoAgenda({
    required this.icon,
    required this.titulo,
    required this.detalle,
    required this.color,
  });
  final IconData icon;
  final String titulo;
  final String detalle;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: ListTile(
      leading: Icon(icon),
      title: Text(titulo),
      subtitle: Text(detalle),
    ),
  );
}

class _LeyendaTipos extends StatelessWidget {
  const _LeyendaTipos({required this.visitas});
  final List<VisitaProgramada> visitas;

  @override
  Widget build(BuildContext context) {
    const tipos = [
      'Evaluación por colegio',
      'Capacitación preescolar',
      'Capacitación primaria',
      'English Day',
      'Ensayo de English Day',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Significado de los colores',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final tipo in tipos)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: _colorTipo(tipo),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$tipo (${visitas.where((visita) => visita.tipo == tipo).length})',
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarioConPuntos extends StatelessWidget {
  const _CalendarioConPuntos({
    required this.mes,
    required this.seleccionado,
    required this.visitas,
    required this.onMesAnterior,
    required this.onMesSiguiente,
    required this.onSeleccionar,
  });

  final DateTime mes;
  final DateTime? seleccionado;
  final List<VisitaProgramada> visitas;
  final VoidCallback onMesAnterior;
  final VoidCallback onMesSiguiente;
  final ValueChanged<DateTime> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    final primerDia = DateTime(mes.year, mes.month, 1);
    final cantidadDias = DateTime(mes.year, mes.month + 1, 0).day;
    final celdasPrevias = primerDia.weekday - 1;
    final totalCeldas = ((celdasPrevias + cantidadDias + 6) ~/ 7) * 7;
    const encabezados = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Mes anterior',
                  onPressed: onMesAnterior,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '${_nombreMes(mes.month)} ${mes.year}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Mes siguiente',
                  onPressed: onMesSiguiente,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.05,
              children: [
                for (final encabezado in encabezados)
                  Center(
                    child: Text(
                      encabezado,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                for (var celda = 0; celda < totalCeldas; celda++)
                  if (celda < celdasPrevias ||
                      celda >= celdasPrevias + cantidadDias)
                    const SizedBox.shrink()
                  else
                    _DiaCalendario(
                      fecha: DateTime(
                        mes.year,
                        mes.month,
                        celda - celdasPrevias + 1,
                      ),
                      seleccionado: seleccionado,
                      visitas: visitas,
                      onTap: onSeleccionar,
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoSemana extends StatelessWidget {
  const _EncabezadoSemana({
    required this.fechaBase,
    required this.visitas,
    required this.onAnterior,
    required this.onSiguiente,
    required this.onSeleccionar,
  });

  final DateTime fechaBase;
  final List<VisitaProgramada> visitas;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;
  final ValueChanged<DateTime> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    final base = DateTime(fechaBase.year, fechaBase.month, fechaBase.day);
    final lunes = base.subtract(Duration(days: base.weekday - 1));
    final domingo = lunes.add(const Duration(days: 6));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Semana anterior',
                  onPressed: onAnterior,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Semana del ${_AgendaVisitasScreenState._fecha(lunes)} al ${_AgendaVisitasScreenState._fecha(domingo)}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${visitas.where((visita) => !visita.fecha.isBefore(lunes) && visita.fecha.isBefore(domingo.add(const Duration(days: 1)))).length} actividades programadas',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Semana siguiente',
                  onPressed: onSiguiente,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var offset = 0; offset < 7; offset++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final dia = lunes.add(Duration(days: offset));
                        final seleccionado =
                            _AgendaVisitasScreenState._mismoDia(dia, fechaBase);
                        final actividades = visitas
                            .where(
                              (visita) => _AgendaVisitasScreenState._mismoDia(
                                visita.fecha,
                                dia,
                              ),
                            )
                            .toList();
                        return InkWell(
                          onTap: () => onSeleccionar(dia),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: seleccionado
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: seleccionado
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _nombreDia(dia.weekday).substring(0, 2),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${dia.day}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 2,
                                  runSpacing: 2,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    for (final visita in actividades.take(3))
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: visita.cancelada
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.error
                                              : _colorTipo(visita.tipo),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaCalendario extends StatelessWidget {
  const _DiaCalendario({
    required this.fecha,
    required this.seleccionado,
    required this.visitas,
    required this.onTap,
  });
  final DateTime fecha;
  final DateTime? seleccionado;
  final List<VisitaProgramada> visitas;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final delDia = visitas
        .where(
          (visita) => _AgendaVisitasScreenState._mismoDia(visita.fecha, fecha),
        )
        .toList();
    final activo =
        seleccionado != null &&
        _AgendaVisitasScreenState._mismoDia(seleccionado!, fecha);
    return InkWell(
      onTap: () => onTap(fecha),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: activo ? Theme.of(context).colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(12),
          border: activo
              ? Border.all(color: Theme.of(context).colorScheme.primary)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${fecha.day}'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 2,
              runSpacing: 2,
              alignment: WrapAlignment.center,
              children: [
                for (final visita in delDia.take(4))
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: visita.cancelada
                          ? Theme.of(context).colorScheme.error
                          : _colorTipo(visita.tipo),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicadoresCalendario extends StatelessWidget {
  const _IndicadoresCalendario({required this.visitas});
  final List<VisitaProgramada> visitas;

  @override
  Widget build(BuildContext context) {
    final dias = <String, List<VisitaProgramada>>{};
    for (final visita in visitas) {
      final clave =
          '${visita.fecha.year}-${visita.fecha.month}-${visita.fecha.day}';
      dias.putIfAbsent(clave, () => []).add(visita);
    }
    final entradas = dias.entries.toList()
      ..sort((a, b) => a.value.first.fecha.compareTo(b.value.first.fecha));
    if (entradas.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Días con actividades',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entrada in entradas.take(12))
                Chip(
                  avatar: CircleAvatar(
                    radius: 5,
                    backgroundColor: _colorTipo(entrada.value.first.tipo),
                  ),
                  label: Text(
                    '${entrada.value.first.fecha.day}/${entrada.value.first.fecha.month} · ${entrada.value.length}',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
