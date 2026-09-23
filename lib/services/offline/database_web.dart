import 'package:sembast_web/sembast_web.dart';

Future<Database> abrirBase(String nombre) =>
    databaseFactoryWeb.openDatabase(nombre);
