import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/admin_auth/admin_auth_bloc.dart';
import 'presentation/blocs/admin_opportunities/admin_opportunities_bloc.dart';
import 'presentation/blocs/opportunities/opportunities_bloc.dart';
import 'presentation/blocs/tracker/tracker_bloc.dart';
import 'presentation/blocs/community/community_bloc.dart';
import 'presentation/blocs/profile/profile_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const PamojaApp());
}

class PamojaApp extends StatelessWidget {
  const PamojaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(create: (context) => AdminAuthBloc()),
        BlocProvider(create: (context) => AdminOpportunitiesBloc()),
        BlocProvider(create: (context) => OpportunitiesBloc()),
        BlocProvider(create: (context) => TrackerBloc()),
        BlocProvider(create: (context) => CommunityBloc()),
        BlocProvider(create: (context) => ProfileBloc()),
      ],
      child: BlocBuilder<ThemeCubit, bool>(
        builder: (context, isDarkMode) {
          return MaterialApp.router(
            title: 'Pamoja - Volunteering Made Easy',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}