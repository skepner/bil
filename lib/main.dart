import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/widgets.dart' show runApp;

import 'bil.dart';

// ======================================================================

class Args {
  String tree;
}

// ----------------------------------------------------------------------

void main(List<String> argv) {
  _enablePlatformOverrideForDesktop();
  final Args args = parse_args(argv);
  if (args.tree == null || args.tree?.isEmpty) {
    runApp(BilApp());
  } else {
    // make pdf and exit
    exit(0);
  }
}

// ======================================================================

Args parse_args(List<String> argv) {
  // 2019-11-20: dart or flutter does not pass command line arguments to main, have to use Platform.environment to pass data from command line
  return Args();
}

void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void debug_main_platform(List<String> argv) {
  print("main $argv");
  print("Executable ${Platform.executable}");
  print("executableArguments ${Platform.executableArguments}");
  print("resolvedExecutable ${Platform.resolvedExecutable}");
  print("script ${Platform.script}");
  print("version ${Platform.version}");
  print("Platform.environment ${Platform.environment}");
}

// ======================================================================
