import 'dart:io' show File, Process, ProcessResult;
import 'dart:convert' show utf8, jsonDecode;
import 'dart:async' show Completer;

import 'package:file_chooser/file_chooser.dart' show showOpenPanel, showSavePanel, FileChooserResult;
import 'package:path/path.dart' as path;

// ======================================================================

Future<String> choose_file_to_read({List<String> allowedFileTypes}) async {
  final completer = Completer<String>();
  showOpenPanel(
    (FileChooserResult result, List<String> paths) {
      if (result == FileChooserResult.ok) {
        completer.complete(paths[0]);
      } else {
        completer.complete(null);
      }
    },
    allowedFileTypes: allowedFileTypes,
  );
  return completer.future;
}

// ----------------------------------------------------------------------

Future<String> choose_file_to_write({String suggestedFileName, List<String> allowedFileTypes}) async {
  final completer = Completer<String>();
  showSavePanel(
    (FileChooserResult result, List<String> paths) {
      if (result == FileChooserResult.ok) {
        completer.complete(paths[0]);
      } else {
        completer.complete(null);
      }
    },
    suggestedFileName: suggestedFileName,
    allowedFileTypes: allowedFileTypes,
  );
  return completer.future;
}

// ----------------------------------------------------------------------

dynamic read_json_from_file(String filename, {Object reviver(Object key, Object value)}) async {
  String content;
  if (path.extension(filename) == ".xz") {
    final ProcessResult xz_result = await Process.run("xz", ["-d", "-c", filename], stdoutEncoding: utf8);
    if (xz_result.exitCode == 0) {
      content = xz_result.stdout;
    }
    else {
      throw "xz failed";
    }
  }
  else {
    content = await File(filename).readAsString();
  }
  return jsonDecode(content, reviver: reviver);
}

// ======================================================================
