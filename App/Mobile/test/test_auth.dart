import 'package:pbl_semester5/app/auth_dependencies.dart';
import 'package:pbl_semester5/features/auth/data/datasources/demo_auth_data_source.dart';

/// Auth wiring for widget tests: offline, fast, and deterministic.
AuthDependencies demoAuth() =>
    AuthDependencies(authSource: DemoAuthDataSource());
