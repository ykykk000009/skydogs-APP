import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/bootstrap.dart';
import 'app/skydogs_app.dart';
import 'state/sleep_app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.initialize();

  runApp(
    ChangeNotifierProvider<SleepAppController>.value(
      value: bootstrap.controller,
      child: const SkyDogsApp(),
    ),
  );
}
