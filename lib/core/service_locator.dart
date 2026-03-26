import 'package:dailathon_dialer/core/channels/call_method_channel.dart';
import 'package:dailathon_dialer/core/channels/contacts_method_channel.dart';
import 'package:dailathon_dialer/core/channels/speed_dial_method_channel.dart';
import 'package:dailathon_dialer/core/channels/call_event_channel.dart';
import 'package:dailathon_dialer/core/channels/ussd_event_channel.dart';
import 'package:dailathon_dialer/core/repositories/call_log_repository.dart';
import 'package:dailathon_dialer/core/repositories/call_forwarding_repository.dart';
import 'package:dailathon_dialer/core/repositories/crm_repository.dart';
import 'package:dailathon_dialer/core/api/api_client.dart';
import 'package:dailathon_dialer/core/services/call_event_logger.dart';
import 'package:dailathon_dialer/features/login/bloc/login_bloc.dart';
import 'package:dailathon_dialer/features/dialer/bloc/dialer_bloc.dart';
import 'package:dailathon_dialer/features/in_call/bloc/in_call_bloc.dart';
import 'package:dailathon_dialer/features/contacts/bloc/contacts_bloc.dart';
import 'package:dailathon_dialer/features/call_log/bloc/call_log_bloc.dart';
import 'package:dailathon_dialer/features/blocked_numbers/bloc/blocked_numbers_bloc.dart';
import 'package:dailathon_dialer/features/admission_calling/bloc/admission_calling_bloc.dart';
import 'package:dailathon_dialer/features/settings/bloc/settings_bloc.dart';
import 'package:dailathon_dialer/features/home/bloc/home_bloc.dart';

/// Simple service locator for dependency injection (no external packages).
/// 
/// Centralizes the creation and management of all BLoCs and Repositories.
/// Register all dependencies here before the app starts.
class ServiceLocator {

  factory ServiceLocator() => _instance;

  ServiceLocator._internal();
  static final ServiceLocator _instance = ServiceLocator._internal();

  // Channels (Platform to Native Bridge)
  late CallMethodChannel _callMethodChannel;
  late ContactsMethodChannel _contactsMethodChannel;
  late SpeedDialMethodChannel _speedDialMethodChannel;
  late CallEventChannel _callEventChannel;
  late UssdEventChannel _ussdEventChannel;

  // Repositories
  late CallLogRepository _callLogRepository;
  late CallForwardingRepository _callForwardingRepository;
  late CrmRepository _crmRepository;

  // API
  late ApiClient _apiClient;

  // Services
  late CallEventLogger _callEventLogger;

  // BLoCs
  late LoginBloc _loginBloc;
  late DialerBloc _dialerBloc;
  late InCallBloc _inCallBloc;
  late CallLogBloc _callLogBloc;
  late ContactsBloc _contactsBloc;
  late BlockedNumbersBloc _blockedNumbersBloc;
  late AdmissionCallingBloc _admissionCallingBloc;
  late SettingsBloc _settingsBloc;
  late HomeBloc _homeBloc;

  /// Initialize all dependencies.
  /// 
  /// Must be called once in main() before running the app:
  /// ```dart
  /// await ServiceLocator().setup();
  /// runApp(const DialerApp());
  /// ```
  Future<void> setup() async {
    // ============ Channels (Platform to Native Bridge) ============
    
    _callMethodChannel = CallMethodChannel();
    _contactsMethodChannel = ContactsMethodChannel();
    _speedDialMethodChannel = SpeedDialMethodChannel();
    _callEventChannel = CallEventChannel();
    _ussdEventChannel = UssdEventChannel();

    // ============ API Client ============
    
    _apiClient = ApiClient();
    // Load stored authentication tokens if any
    await _apiClient.loadStoredTokens();

    // ============ Repositories ============
    
    _callLogRepository = CallLogRepository(
      contactsMethodChannel: _contactsMethodChannel,
    );
    _callForwardingRepository = CallForwardingRepository(_callMethodChannel);
    _crmRepository = CrmRepository(apiClient: _apiClient);

    // ============ Services ============
    
    _callEventLogger = CallEventLogger(
      crmRepository: _crmRepository,
      apiClient: _apiClient,
    );

    // ============ BLoCs ============
    
    _loginBloc = LoginBloc();
    _dialerBloc = DialerBloc(callMethodChannel: _callMethodChannel);
    _inCallBloc = InCallBloc(callEventChannel: _callEventChannel);
    _callLogBloc = CallLogBloc(_callLogRepository);
    _contactsBloc = ContactsBloc();
    _blockedNumbersBloc = BlockedNumbersBloc();
    _admissionCallingBloc = AdmissionCallingBloc();
    _settingsBloc = SettingsBloc();
    _homeBloc = HomeBloc();
  }

  /// Get CallMethodChannel
  CallMethodChannel get callMethodChannel => _callMethodChannel;

  /// Get ContactsMethodChannel
  ContactsMethodChannel get contactsMethodChannel => _contactsMethodChannel;

  /// Get SpeedDialMethodChannel
  SpeedDialMethodChannel get speedDialMethodChannel => _speedDialMethodChannel;

  /// Get CallEventChannel
  CallEventChannel get callEventChannel => _callEventChannel;

  /// Get UssdEventChannel
  UssdEventChannel get ussdEventChannel => _ussdEventChannel;

  /// Get CallLogRepository
  CallLogRepository get callLogRepository => _callLogRepository;

  /// Get CallForwardingRepository
  CallForwardingRepository get callForwardingRepository =>
      _callForwardingRepository;

  /// Get CrmRepository
  CrmRepository get crmRepository => _crmRepository;

  /// Get ApiClient
  ApiClient get apiClient => _apiClient;

  /// Get CallEventLogger
  CallEventLogger get callEventLogger => _callEventLogger;

  /// Get LoginBloc
  LoginBloc get loginBloc => _loginBloc;

  /// Get DialerBloc
  DialerBloc get dialerBloc => _dialerBloc;

  /// Get InCallBloc
  InCallBloc get inCallBloc => _inCallBloc;

  /// Get CallLogBloc
  CallLogBloc get callLogBloc => _callLogBloc;

  /// Get ContactsBloc
  ContactsBloc get contactsBloc => _contactsBloc;

  /// Get BlockedNumbersBloc
  BlockedNumbersBloc get blockedNumbersBloc => _blockedNumbersBloc;

  /// Get AdmissionCallingBloc
  AdmissionCallingBloc get admissionCallingBloc => _admissionCallingBloc;

  /// Get SettingsBloc
  SettingsBloc get settingsBloc => _settingsBloc;

  /// Get HomeBloc
  HomeBloc get homeBloc => _homeBloc;

  /// Dispose all BLoCs.
  /// 
  /// Call this in the app's dispose method to clean up resources:
  /// ```dart
  /// onDispose: () {
  ///   ServiceLocator().dispose();
  /// }
  /// ```
  Future<void> dispose() async {
    await _loginBloc.close();
    await _dialerBloc.close();
    await _inCallBloc.close();
    await _callLogBloc.close();
    await _contactsBloc.close();
    await _blockedNumbersBloc.close();
    await _admissionCallingBloc.close();
    await _settingsBloc.close();
    await _telegramCallingBloc.close();
    await _homeBloc.close();
  }
}
