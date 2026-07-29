import 'package:flutter/material.dart';

/// Navigator raíz de la app. Se usa para navegar desde widgets que viven
/// fuera del árbol normal de rutas (como LockScreen, que se dibuja como
/// overlay encima del Navigator, no dentro de él) — Navigator.of(context)
/// no funciona ahí porque ese context no tiene un Navigator como ancestro.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
