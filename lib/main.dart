import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokiai/view/screens/splashscreen.dart';
import 'package:spokiai/view/utils/app_theme.dart';
import 'package:spokiai/view/utils/firebase_options.dart';
import 'package:spokiai/payment/SubscriptionService.dart';
import 'package:spokiai/payment/subscription_store_launcher.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/view/utils/theme_controller.dart';
import 'package:spokiai/data/local/inworld_tts_preferences.dart';
import 'package:spokiai/data/repositories/inworld_tts_repository_impl.dart';
import 'package:spokiai/data/sources/inworld_tts_remote_data_source.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_cubit.dart';
import 'package:spokiai/core/config/inworld_tts_config.dart';
import 'package:spokiai/viewmodel/cubit/appcubit.dart';
import 'package:spokiai/viewmodel/repository/app_repository.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );
  await InworldTtsConfig.loadSecrets();
  await PreferenceManager.init();
  SubscriptionStoreLauncher.configureAndroidPackageName('com.spokiai');
  await SubscriptionService.instance.ensureInitialized();
  ThemeController.loadFromPreferences();

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

        final inworldRepository = InworldTtsRepositoryImpl(
          remoteDataSource: InworldTtsRemoteDataSourceImpl(),
          preferences: InworldTtsPreferencesImpl(),
        );

        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => AppCubit(repository)),
            BlocProvider(
              create: (context) => InworldTtsCubit(inworldRepository)
                ..loadPreferences(),
            ),
          ],
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.themeModeNotifier,
            builder: (context, mode, _) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: mode,
                title: 'Spoki AI',
                home: const Splashscreen(),
                // home: const SubscriptionScreen(),
              );
            },
          ),
        );
      },
    );
  }
}

