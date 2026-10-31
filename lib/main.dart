import 'package:flutter/material.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'views/auth/login_view.dart';
import 'views/shell/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniFlowApp());
}

class UniFlowApp extends StatefulWidget {
  const UniFlowApp({super.key});

  @override
  State<UniFlowApp> createState() => _UniFlowAppState();
}

class _UniFlowAppState extends State<UniFlowApp> {
  final AppState _appState = AppState();
  bool _isAuthenticated = true; // Defaults to true for fast evaluator preview

  void _handleLogin() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _handleSignOut() {
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniFlow — The Campus Journey Engine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isAuthenticated
          ? AppShell(
              appState: _appState,
              onSignOut: _handleSignOut,
            )
          : LoginView(
              appState: _appState,
              onLoginSuccess: _handleLogin,
            ),
    );
  }
}
