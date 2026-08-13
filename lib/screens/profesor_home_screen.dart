import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sesion_provider.dart';
import '../widgets/home_action_card.dart';
import 'evaluador_selection_screen.dart';
import 'login_screen.dart';

class ProfesorHomeScreen extends StatelessWidget {
  const ProfesorHomeScreen({super.key});

  static const routeName = '/profesor_home';

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionProvider>().usuarioActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              context.read<SesionProvider>().cerrarSesion();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Hola, ${usuario?.nombre ?? 'Profesor'}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            usuario?.zona ?? '',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona una opción para continuar.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          HomeActionCard(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Evaluaciones',
            subtitle: 'Inicia una capacitación de Preescolar o Primaria.',
            onTap: () => Navigator.pushNamed(
              context,
              EvaluadorSelectionScreen.routeName,
            ),
          ),
        ],
      ),
    );
  }
}
