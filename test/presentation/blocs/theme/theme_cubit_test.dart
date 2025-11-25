// test/presentation/blocs/theme/theme_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pamoja_app/presentation/blocs/theme/theme_cubit.dart';

void main() {
  // Initialize binding for SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeCubit', () {
    late ThemeCubit themeCubit;

    setUp(() {
      // Clear any previous mock values
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      themeCubit.close();
    });

    test('initial state is false', () async {
      SharedPreferences.setMockInitialValues({});
      themeCubit = ThemeCubit();
      
      // The initial state should be false
      expect(themeCubit.state, false);
    });

    test('loads dark mode from SharedPreferences when true', () async {
      SharedPreferences.setMockInitialValues({'darkMode': true});
      
      themeCubit = ThemeCubit();
      
      // Wait for the cubit to initialize and load the theme
      await Future.delayed(const Duration(milliseconds: 50));
      
      // The state should be true (dark mode)
      expect(themeCubit.state, true);
    });

    test('loads light mode from SharedPreferences when false', () async {
      SharedPreferences.setMockInitialValues({'darkMode': false});
      
      themeCubit = ThemeCubit();
      
      // Wait for the cubit to initialize and load the theme
      await Future.delayed(const Duration(milliseconds: 50));
      
      // The state should be false (light mode)
      expect(themeCubit.state, false);
    });

    test('toggles theme from light to dark', () async {
      SharedPreferences.setMockInitialValues({'darkMode': false});
      
      themeCubit = ThemeCubit();
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Initial state should be false
      expect(themeCubit.state, false);
      
      // Toggle to dark mode
      await themeCubit.toggleTheme();
      
      // State should now be true
      expect(themeCubit.state, true);
    });

    test('toggles theme from dark to light', () async {
      SharedPreferences.setMockInitialValues({'darkMode': true});
      
      themeCubit = ThemeCubit();
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Initial state should be true
      expect(themeCubit.state, true);
      
      // Toggle to light mode
      await themeCubit.toggleTheme();
      
      // State should now be false
      expect(themeCubit.state, false);
    });

    test('persists theme preference when toggled', () async {
      SharedPreferences.setMockInitialValues({'darkMode': false});
      
      themeCubit = ThemeCubit();
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Toggle theme
      await themeCubit.toggleTheme();
      
      // Check that preference was saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('darkMode'), true);
    });

    test('uses default false when no preference exists', () async {
      SharedPreferences.setMockInitialValues({});
      
      themeCubit = ThemeCubit();
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Should default to false
      expect(themeCubit.state, false);
    });
  });
}