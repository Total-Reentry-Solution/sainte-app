import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/supabase_config.dart';
import 'ui/modules/authentication/bloc/account_cubit.dart';
import 'core/routes/router.dart';
import 'data/mock_data/mock_data_initializer.dart';

// SAINTE APP - Clean implementation with new data models
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize mock data for testing
  MockDataInitializer.initializeMockData();

  runApp(const SainteApp());
}

class SainteApp extends StatelessWidget {
  const SainteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AccountCubit>(
          create: (context) => AccountCubit(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Sainte',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3AE6BD)),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
          primaryColor: const Color(0xFF3AE6BD),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
            displaySmall: TextStyle(color: Colors.white, fontSize: 12),
            bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
            bodySmall: TextStyle(color: Colors.white, fontSize: 12),
            titleLarge: TextStyle(
              color: Color(0xFF3AE6BD),
              fontSize: 40,
              fontFamily: 'InterBold',
              fontWeight: FontWeight.bold,
            ),
            titleSmall: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'InterBold',
            ),
            titleMedium: TextStyle(color: Colors.white, fontSize: 20),
          ),
          fontFamily: 'Inter',
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}