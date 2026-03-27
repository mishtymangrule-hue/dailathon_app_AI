import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs.dart';
import 'core/service_locator.dart';
import 'features/home/bloc/home_bloc.dart';
import 'features/notifications/bloc/notifications_bloc.dart';
import 'features/call_sync/bloc/call_sync_bloc.dart';
import 'router.dart';

class DialerApp extends StatefulWidget {
  const DialerApp({Key? key}) : super(key: key);

  @override
  State<DialerApp> createState() => _DialerAppState();
}

class _DialerAppState extends State<DialerApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
      providers: [
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
          BlocProvider<NotificationsBloc>(
            create: (context) => ServiceLocator().notificationsBloc
              ..add(const NotificationsRefreshRequested()),
          ),
          BlocProvider<CallSyncBloc>(
            create: (context) => ServiceLocator().callSyncBloc,
          ),
        ],
        child: MaterialApp.router(
          title: 'Dailathon Dialer',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      );
}
