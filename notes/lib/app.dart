import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/auth_service.dart'; // Make sure to import your AuthService
import 'home/sample_item_details_view.dart';
import 'home/home_list_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'signin/signin_page.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    // Initialize AuthService
    final authService = AuthService();

    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'app',
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: settingsController.themeMode,

          // Use a StreamBuilder to handle auth state changes
          home: StreamBuilder<User?>(
            stream: authService.user,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                final user = snapshot.data;

                // If user is not logged in, show AuthScreen
                if (user == null) {
                  return const AuthScreen();
                }

                // If user is logged in, show your HomeListView
                return HomeListView();
              }

              // Show loading screen while checking auth state
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),

          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return SettingsView(controller: settingsController);
                  case SampleItemDetailsView.routeName:
                    return const SampleItemDetailsView();
                  case HomeListView.routeName:
                  // This will only be reached if navigating directly to home
                  // The StreamBuilder above handles the default home screen
                    return HomeListView();
                  case AuthScreen.routeName: // Add this if you want named route
                    return const AuthScreen();
                  default:
                  // For any other route, we'll let the StreamBuilder handle it
                    return const AuthScreen();
                }
              },
            );
          },
        );
      },
    );
  }
}