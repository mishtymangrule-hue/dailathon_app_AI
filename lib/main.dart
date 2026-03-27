import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all dependencies
  await ServiceLocator().setup();

  // Handle WorkManager-triggered CRM queue flush from native side
  const MethodChannel('com.mangrule.dailathon/crm_flush')
      .setMethodCallHandler((call) async {
    if (call.method == 'flushQueue') {
      await ServiceLocator().crmReportingService.flush();
    }
  });

  runApp(const DialerApp());
}
