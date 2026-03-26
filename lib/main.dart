import 'package:flutter/material.dart';
import 'app.dart';
import 'core/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize all dependencies
  await ServiceLocator().setup();
  
  runApp(const DialerApp());
}
