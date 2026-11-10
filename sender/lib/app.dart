import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'discovery/discovery_cubit.dart';
import 'discovery/mdns_service.dart';
import 'session/session_cubit.dart';
import 'session/airshow_channel.dart';
import 'ui/receiver_list_screen.dart';

class AirShowSenderApp extends StatelessWidget {
  const AirShowSenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => DiscoveryCubit(MdnsService())),
        BlocProvider(create: (_) => SessionCubit(AirShowChannel())),
      ],
      child: MaterialApp(
        title: 'ComSSU Cast',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF4F9FD),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1565C0), // Deep blue
            secondary: Color(0xFF29B6F6), // Sky blue
            surface: Colors.white,
            surfaceContainerLowest: Colors.white,
            onPrimary: Colors.white,
            onSurface: Color(0xFF172B45), // Dark navy
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF172B45),
            elevation: 0,
            scrolledUnderElevation: 1,
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
            ),
          ),
        ),
        home: const ReceiverListScreen(),
      ),
    );
  }
}
