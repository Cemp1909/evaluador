import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final visitas = context.watch<SesionProvider>().visitas;
    final visibles = _diaSeleccionado == null
        ? visitas
        : visitas
              .where((visita) => _mismoDia(visita.fecha, _diaSeleccionado!))
              .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda de evaluaciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _crear(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Programar visita'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: CalendarDatePicker(
              initialDate: _diaSeleccionado ?? DateTime.now(),
              firstDate: DateTime(2025),
              lastDate: DateTime.now().add(const Duration(days: 730)),
              onDateChanged: (fecha) =>
                  setState(() => _diaSeleccionado = fecha),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _diaSeleccionado == null
                      ? 'Todas las actividades'
                      : 'Actividades del ${_fecha(_diaSeleccionado!)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_diaSeleccionado != null)
                TextButton(
                  onPressed: () => setState(() => _diaSeleccionado = null),
                  child: const Text('Ver todas'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (visibles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No hay actividades para esta fecha.')),
            )
          else
            for (final visita in visibles) ...[
              Card(
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: visita.completada,
                      onChanged: visita.cancelada
                          ? null
                          : (_) => context
                                .read<SesionProvider>()
                                .alternarVisita(visita.id),
                      secondary: Icon(
                        visita.cancelada
                            ? Icons.event_busy_outlined
                            : Icons.event_available_outlined,
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(visita.colegio)),
                          if (visita.cancelada)
                            const Chip(label: Text('Cancelada')),
                        ],
                      ),
                      subtitle: Text(
                        '${_fecha(visita.fecha)} · ${_hora(visita.fecha)} · ${visita.tipo}'
                        '\nProfesor responsable: ${visita.profesorResponsable}'
                        '${visita.periodo == null ? '' : '\nPeríodo: ${visita.periodo}'}'
                        '${visita.numeroClase == null ? '' : '\nClase número: ${visita.numeroClase}'}'
                        '${visita.observacion.isEmpty ? '' : '\n${visita.observacion}'}'
                        '${visita.cancelada ? '\nMotivo: ${visita.motivoCancelacion}' : ''}'
                        '${!visita.cancelada && visita.ultimaNovedad.isNotEmpty ? '\nNovedad: ${visita.ultimaNovedad}' : ''}',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _reprogramar(context, visita),
                              icon: const Icon(Icons.edit_calendar_outlined),
                              label: const Text('Reprogramar'),
                            ),
                          ),
                          if (!visita.cancelada) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () => _cancelar(context, visita),
                                icon: const Icon(Icons.event_busy_outlined),
                                label: const Text('Cancelar'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
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
        final nuevaFecha = await showDatePicker(
          context: context,
          initialDate: visita.fecha.isAfter(DateTime.now())
              ? visita.fecha
              : DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 730)),
          helpText: 'Selecciona la nueva fecha',
          cancelText: 'Volver',
          confirmText: 'Reprogramar',
        );
        if (nuevaFecha != null && context.mounted) {
          final fechaConHora = DateTime(
            nuevaFecha.year,
            nuevaFecha.month,
            nuevaFecha.day,
            visita.fecha.hour,
            visita.fecha.minute,
          );
          context.read<SesionProvider>().reprogramarSerieDesde(
            visita.id,
            fechaConHora,
            motivo: motivo.text,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Actividad reprogramada para ${_fecha(fechaConHora)} a las ${_hora(fechaConHora)}. Motivo: ${motivo.text.trim()}',
              ),
            ),
          );
        }
      } else {
        if (visita.serieId == null) {
          context.read<SesionProvider>().cancelarVisita(visita.id, motivo.text);
        } else {
          context.read<SesionProvider>().posponerSerieDesde(
            visita.id,
            motivo.text,
          );
        }
      }
    }
    Future<void>.delayed(const Duration(milliseconds: 400), motivo.dispose);
  }

  Future<void> _reprogramar(
    BuildContext context,
    VisitaProgramada visita,
  ) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: visita.fecha.isBefore(DateTime.now())
          ? DateTime.now()
          : visita.fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Selecciona la nueva fecha',
    );
    if (fecha == null || !context.mounted) return;
    final fechaConHora = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      visita.fecha.hour,
      visita.fecha.minute,
    );
    context.read<SesionProvider>().reprogramarSerieDesde(
      visita.id,
      fechaConHora,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Actividad reprogramada para ${_fecha(fechaConHora)} a las ${_hora(fechaConHora)}.',
        ),
      ),
    );
  }

  Future<void> _crear(BuildContext context) async {
    final colegio = TextEditingController();
    final profesor = TextEditingController();
    final nota = TextEditingController();
    var tipo = 'Evaluación por colegio';
    var periodo = 1;
    var numeroClase = 1;
    var programarSerie = true;
    var intervaloDias = 7;
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
                else
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
      final visita = VisitaProgramada(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        fecha: fecha,
        colegio: colegio.text.trim(),
        tipo: tipo,
        profesorResponsable: profesor.text.trim(),
        periodo: tipo == 'Evaluación por colegio' ? periodo : null,
        numeroClase: tipo == 'Evaluación por colegio' ? null : numeroClase,
        observacion: nota.text.trim(),
      );
      final sesion = context.read<SesionProvider>();
      final error = tipo != 'Evaluación por colegio' && programarSerie
          ? sesion.programarSerieClases(visita, intervaloDias: intervaloDias)
          : sesion.programarVisita(visita);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      } else if (context.mounted) {
        final total = tipo == 'Capacitación preescolar' ? 6 : 11;
        final cantidad = tipo != 'Evaluación por colegio' && programarSerie
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
