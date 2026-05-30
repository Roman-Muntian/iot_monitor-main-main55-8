import 'package:flutter/material.dart';

import 'app_state.dart';
import 'dashboard_screen.dart';
import 'theme/neo_brutalist_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: NB.isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: NB.paper,
            textTheme: TextTheme(
              bodyMedium: NB.body(14),
              bodyLarge: NB.body(16),
              titleLarge: NB.display(20),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: NB.paper,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: NB.ink),
            ),
            colorScheme: NB.isDark
                ? ColorScheme.dark(
                    primary: NB.electricBlue,
                    secondary: NB.mintGreen,
                    surface: NB.white,
                  )
                : ColorScheme.light(
                    primary: NB.electricBlue,
                    secondary: NB.mintGreen,
                    surface: NB.white,
                  ),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ),
          home: const Dashboard(),
        );
      },
    );
  }
}