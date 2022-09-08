import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appMethodsProvider = Provider<MethodChannel>( (ref) => const MethodChannel('app.methods'));