import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/admin_auth/admin_auth_bloc.dart';
import 'presentation/blocs/opportunities/opportunities_bloc.dart';
import 'presentation/blocs/profile/profile_bloc.dart';
import 'presentation/blocs/tracker/tracker_bloc.dart';
import 'presentation/blocs/community/community_bloc.dart';
import 'presentation/blocs/admin_opportunities/admin_opportunities_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/blocs/notifications/notifications_bloc.dart';
import 'core/services/notification_service.dart'; // ADDED



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(CheckAuthStatus())),
        BlocProvider(create: (_) => AdminAuthBloc()),
        BlocProvider(create: (_) => OpportunitiesBloc()),
        BlocProvider(create: (_) => ProfileBloc()),
        BlocProvider(create: (_) => TrackerBloc(
          notificationService: NotificationService(), // ADDED
        )),
        BlocProvider(create: (_) => CommunityBloc()),
        BlocProvider(create: (_) => AdminOpportunitiesBloc(
          notificationService: NotificationService(), // ADDED
        )),
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => NotificationsBloc()),
      ],
      child: BlocBuilder<ThemeCubit, bool>(
        builder: (context, isDarkMode) {
          return MaterialApp.router(
            title: 'Pamoja',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}