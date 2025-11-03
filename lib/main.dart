import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/opportunities/opportunities_bloc.dart';
import 'presentation/blocs/community/community_bloc.dart';
import 'presentation/blocs/tracker/tracker_bloc.dart';
import 'presentation/blocs/profile/profile_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(PamojaApp(prefs: prefs));
}

class PamojaApp extends StatelessWidget {
  final SharedPreferences prefs;

  const PamojaApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(prefs)),
        BlocProvider(create: (_) => OpportunitiesBloc()),
        BlocProvider(create: (_) => CommunityBloc()),
        BlocProvider(create: (_) => TrackerBloc()),
        BlocProvider(create: (_) => ProfileBloc()),
      ],
      child: MaterialApp.router(
        title: 'Pamoja',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}