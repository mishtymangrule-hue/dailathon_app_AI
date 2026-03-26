import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/permissions/permission_manager.dart';
import 'presentation/blocs.dart';
import 'core/service_locator.dart';
import 'router.dart';

class DialerApp extends StatefulWidget {
  const DialerApp({Key? key}) : super(key: key);

  @override
  State<DialerApp> createState() => _DialerAppState();
}

class _DialerAppState extends State<DialerApp> {
  late Future<bool> _permissionsFuture;

  @override
  void initState() {
    super.initState();
    _permissionsFuture = PermissionManager.requestAllPermissions(context);
  }

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
      providers: [
        // Add any repositories here if needed
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LoginBloc>(
            create: (context) => ServiceLocator().loginBloc
              ..add(const SessionRestored(token: '')),
          ),
          BlocProvider<DialerBloc>(
            create: (context) => ServiceLocator().dialerBloc,
          ),
          BlocProvider<InCallBloc>(
            create: (context) => ServiceLocator().inCallBloc,
          ),
          BlocProvider<CallLogBloc>(
            create: (context) => ServiceLocator().callLogBloc,
          ),
          BlocProvider<ContactsBloc>(
            create: (context) => ServiceLocator().contactsBloc,
          ),
          BlocProvider<BlockedNumbersBloc>(
            create: (context) => ServiceLocator().blockedNumbersBloc,
          ),
          BlocProvider<AdmissionCallingBloc>(
            create: (context) => ServiceLocator().admissionCallingBloc,
          ),
          BlocProvider<SettingsBloc>(
            create: (context) => ServiceLocator().settingsBloc,
          ),
          BlocProvider<HomeBloc>(
            create: (context) => ServiceLocator().homeBloc,
          ),
        ],
        child: MaterialApp.router(
          title: 'Dailathon Dialer',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          routerConfig: GoRouter(
            initialLocation: _resolveInitialRoute(context),
            routes: router.routes,
          ),
        ),
      ),
    );

  /// Determine initial route based on login state
  String _resolveInitialRoute(BuildContext context) {
    final loginState = context.read<LoginBloc>().state;
    
    if (loginState is LoginSuccess) {
      return '/home';
    } else {
      return '/login';
    }
  }
}
