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
        // Volunteer Authentication (Firebase)
        BlocProvider(
          create: (context) => AuthBloc(),
        ),
        
        // Admin Authentication (Firebase)
        BlocProvider(
          create: (context) => AdminAuthBloc(),
        ),
        
        // Admin Opportunities Management (Firebase CRUD)
        BlocProvider(
          create: (context) => AdminOpportunitiesBloc(),
        ),
        
        // Volunteer Opportunities (Firebase Read)
        BlocProvider(
          create: (context) => OpportunitiesBloc(),
        ),
        
        // Volunteer Activity Tracker (Firebase)
        BlocProvider(
          create: (context) => TrackerBloc(),
        ),
        
        // Community Posts (Firebase CRUD)
        BlocProvider(
          create: (context) => CommunityBloc(),
        ),
        
        // User Profile (Firebase)
        BlocProvider(
          create: (context) => ProfileBloc(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Pamoja - Volunteering Made Easy',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}