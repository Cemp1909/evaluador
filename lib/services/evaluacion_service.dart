import '../models/evaluacion.dart';
import '../models/evaluacion_bloque.dart';
import '../models/evaluacion_clase.dart';
import '../models/evaluador_tipo.dart';
import '../models/firma_docente.dart';

/// Estado local temporal. La persistencia offline y Supabase se conectarán aquí.
class EvaluacionService {
  Evaluacion crearDesdePlantilla(EvaluadorTipo tipo) => Evaluacion(
    evaluadorTipo: tipo.codigo,
    colegio: '',
    fechaCreacion: DateTime.now(),
    clases: tipo.clases.map((clase) {
      final bloques = clase.bloques
          .map(
            (bloque) => EvaluacionBloque(
              bloqueNombre: bloque.nombre,
              itemsMarcados: {
                for (final item in bloque.items) item.texto: false,
              },
            ),
          )
          .toList();
      return EvaluacionClase(claseNumero: clase.numero, bloques: bloques);
    }).toList(),
  );

  Evaluacion actualizarBloque({
    required Evaluacion evaluacion,
    required int claseNumero,
    required String bloqueNombre,
    required bool marcado,
  }) {
    final clases = evaluacion.clases.map((clase) {
      if (clase.claseNumero != claseNumero) return clase;

      final bloques = clase.bloques.map((bloque) {
        if (bloque.bloqueNombre != bloqueNombre) return bloque;
        return bloque.copyWith(
          marcado: marcado,
          itemsMarcados: {
            for (final item in bloque.itemsMarcados.keys) item: marcado,
          },
        );
      }).toList();
      return clase.copyWith(bloques: bloques);
    }).toList();

    return _actualizarEstado(evaluacion, clases);
  }

  Evaluacion actualizarItem({
    required Evaluacion evaluacion,
    required int claseNumero,
    required String bloqueNombre,
    required String itemTexto,
    required bool marcado,
  }) {
    final clases = evaluacion.clases.map((clase) {
      if (clase.claseNumero != claseNumero) return clase;

      final bloques = clase.bloques.map((bloque) {
        if (bloque.bloqueNombre != bloqueNombre) return bloque;

        final itemsMarcados = Map<String, bool>.from(bloque.itemsMarcados)
          ..[itemTexto] = marcado;
        return bloque.copyWith(
          itemsMarcados: itemsMarcados,
          marcado:
              itemsMarcados.isNotEmpty &&
              itemsMarcados.values.every((valor) => valor),
        );
      }).toList();
      return clase.copyWith(bloques: bloques);
    }).toList();

    return _actualizarEstado(evaluacion, clases);
  }

  Evaluacion seleccionarBloqueCanciones({
    required Evaluacion evaluacion,
    required int claseNumero,
    required String bloqueNombre,
  }) {
    final clases = evaluacion.clases.map((clase) {
      if (clase.claseNumero != claseNumero) return clase;
      final existe = clase.bloques.any(
        (bloque) =>
            bloque.bloqueNombre == bloqueNombre &&
            EvaluacionClase.esOpcionCanciones(bloque.bloqueNombre),
      );
      if (!existe) return clase;

      final bloques = clase.bloques.map((bloque) {
        if (!EvaluacionClase.esOpcionCanciones(bloque.bloqueNombre) ||
            bloque.bloqueNombre == bloqueNombre) {
          return bloque;
        }
        return bloque.copyWith(
          marcado: false,
          itemsMarcados: {
            for (final item in bloque.itemsMarcados.keys) item: false,
          },
        );
      }).toList();
      return clase.copyWith(
        bloqueCancionesSeleccionado: bloqueNombre,
        bloques: bloques,
      );
    }).toList();
    return _actualizarEstado(evaluacion, clases);
  }

  Evaluacion actualizarObservaciones({
    required Evaluacion evaluacion,
    required int claseNumero,
    required String observaciones,
  }) {
    final clases = evaluacion.clases
        .map(
          (clase) => clase.claseNumero == claseNumero
              ? clase.copyWith(observaciones: observaciones)
              : clase,
        )
        .toList();
    return evaluacion.copyWith(clases: clases);
  }

  Evaluacion actualizarFirmaRepresentante({
    required Evaluacion evaluacion,
    required int claseNumero,
    required String firmaBase64,
  }) => _actualizarClase(
    evaluacion,
    claseNumero,
    (clase) => clase.copyWith(firmaDocenteUrl: firmaBase64),
  );

  Evaluacion agregarFirmaAsistente({
    required Evaluacion evaluacion,
    required int claseNumero,
    required FirmaDocente firma,
  }) => _actualizarClase(
    evaluacion,
    claseNumero,
    (clase) =>
        clase.copyWith(firmasAsistentes: [...clase.firmasAsistentes, firma]),
  );

  Evaluacion eliminarFirmaAsistente({
    required Evaluacion evaluacion,
    required int claseNumero,
    required int index,
  }) => _actualizarClase(
    evaluacion,
    claseNumero,
    (clase) => clase.copyWith(
      firmasAsistentes: [
        for (var i = 0; i < clase.firmasAsistentes.length; i++)
          if (i != index) clase.firmasAsistentes[i],
      ],
    ),
  );

  Evaluacion agregarFoto(Evaluacion evaluacion, String fotoBase64) {
    if (evaluacion.fotosUrls.length >= 2) return evaluacion;
    return evaluacion.copyWith(
      fotosUrls: [...evaluacion.fotosUrls, fotoBase64],
    );
  }

  Evaluacion eliminarFoto(Evaluacion evaluacion, int index) =>
      evaluacion.copyWith(
        fotosUrls: [
          for (var i = 0; i < evaluacion.fotosUrls.length; i++)
            if (i != index) evaluacion.fotosUrls[i],
        ],
      );

  Evaluacion _actualizarClase(
    Evaluacion evaluacion,
    int claseNumero,
    EvaluacionClase Function(EvaluacionClase clase) actualizar,
  ) => evaluacion.copyWith(
    clases: evaluacion.clases
        .map(
          (clase) =>
              clase.claseNumero == claseNumero ? actualizar(clase) : clase,
        )
        .toList(),
  );

  Evaluacion _actualizarEstado(
    Evaluacion evaluacion,
    List<EvaluacionClase> clases,
  ) {
    final hayAvance = clases.any(
      (clase) => clase.bloques.any(
        (bloque) =>
            bloque.marcado || bloque.itemsMarcados.values.any((valor) => valor),
      ),
    );
    final clasesConContenido = clases.where(
      (clase) => clase.bloques.isNotEmpty,
    );
    final todasCompletas =
        clasesConContenido.isNotEmpty &&
        clasesConContenido.every((clase) => clase.estaCompleta);

    return evaluacion.copyWith(
      clases: clases,
      estado: todasCompletas
          ? EstadoEvaluacion.completada
          : hayAvance
          ? EstadoEvaluacion.enProgreso
          : EstadoEvaluacion.borrador,
    );
  }

  String crearObservacionAutomatica(EvaluacionClase clase) =>
      _crearObservacionAutomatica(clase.bloquesEvaluables);

  static String _crearObservacionAutomatica(List<EvaluacionBloque> bloques) {
    final pendientes = <String>[];

    for (final bloque in bloques) {
      final noEnsenados = bloque.itemsMarcados.entries
          .where((item) => !item.value)
          .map((item) => item.key)
          .toList();
      if (noEnsenados.isNotEmpty) {
        pendientes.add('• ${bloque.bloqueNombre}: ${noEnsenados.join(', ')}.');
      } else if (bloque.itemsMarcados.isEmpty && !bloque.marcado) {
        pendientes.add('• ${bloque.bloqueNombre}: no se enseñó.');
      }
    }

    if (pendientes.isEmpty) {
      return 'Se enseñó todo el contenido programado.';
    }
    return 'No se enseñaron los siguientes contenidos:\n${pendientes.join('\n')}';
  }
}
