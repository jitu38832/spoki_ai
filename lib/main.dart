import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/splashscreen.dart';
import 'package:spokiai/view/screens/story_quiz_screen.dart';
import 'package:spokiai/view/utils/firebase_options.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/cubit/appcubit.dart';
import 'package:spokiai/viewmodel/repository/app_repository.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PreferenceManager.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);

  runApp(const InitApp());
}

class InitApp extends StatelessWidget {
  const InitApp({super.key});

  Future<bool> isLoggedIn() async {
    final token = PreferenceManager.getStringValue( key: 'token')??"";
    return token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final repository = AppRepository();

        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => AppCubit(repository)),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.light(),
            title: 'Spoki AI',
            home:   Splashscreen()
            // home: snapshot.data! ? const HistoryScreen() : const LoginScreen(),
          ),
        );
      },
    );
  }
}

