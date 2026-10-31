import 'package:flutter/material.dart';
import 'core/auth/auth_service.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'views/auth/login_view.dart';
import 'views/shell/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  final hasSession = await appState.initializeSession();
  runApp(UniFlowApp(
    appState: appState,
    initialAuthenticated: hasSession,
  ));
}

class UniFlowApp extends StatefulWidget {
  final AppState? appState;
  final AuthService? authService;
  final bool? initialAuthenticated;

  const UniFlowApp({
    super.key,
    this.appState,
    this.authService,
    this.initialAuthenticated,
  });

  @override
  State<UniFlowApp> createState() => _UniFlowAppState();
}

class _UniFlowAppState extends State<UniFlowApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = widget.appState ??
        AppState(
          authService: widget.authService,
          initialAuthenticated: widget.initialAuthenticated ?? true,
        );
  }

  void _handleLogin() {
    setState(() {});
  }

  void _handleSignOut() {
    _appState.logout();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'UniFlow — The Campus Journey Engine',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: _appState.isAuthenticated
              ? AppShell(
                  appState: _appState,
                  onSignOut: _handleSignOut,
                )
              : LoginView(
                  appState: _appState,
                  onLoginSuccess: _handleLogin,
                ),
        );
      },
    );
  }
}
