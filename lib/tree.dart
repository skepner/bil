import 'dart:math' show max;

import 'utilities.dart' show read_json_from_file, choose_file_to_read;

// ======================================================================

class Node {
  Map<String, dynamic> _data;

  Node.cast(dynamic data) : _data = data as Map<String, dynamic>;

  double get edge => _data["l"] ?? 0.0;
  double get cumulative => _data["c"];
  List<Node> get children => _data["t"].map<Node>((dynamic elt) => Node.cast(elt)).toList(growable: false);
  bool get has_children => !(_data["t"]?.isEmpty ?? true);
  bool get hidden => _data["H"] ?? false;
  String get seq_id => _data["n"];
  String get aa => _data["a"];
  String get date => _data["d"];
  String get continent => _data["C"];
  String get country => _data["D"];
  List<String> get hi_names => _data["h"];
  List<String> get aa_substitutions => _data["A"];
  List<String> get clades => _data["L"];

  void _compute_cumulative_lengths({double cumul = 0.0}) {
    cumul += this.edge;
    _data["c"] = cumul;
    if (this.has_children) {
      for (Node subtree in this.children) {
        subtree._compute_cumulative_lengths(cumul: cumul);
      }
    }
  }

  double get max_cumulative_lengths {
    if (this.has_children) {
      return this.children.map<double>((Node node) => !node.hidden ? node.max_cumulative_lengths : 0.0).fold(0.0, max);
    } else {
      return this.cumulative;
    }
  }

  int get number_of_leaves {
    if (this.hidden) {
      return 0;
    } else if (this.has_children) {
      return this.children.map<int>((Node node) => node.number_of_leaves).fold(0, (int prev, int elt) => prev + elt);
    } else {
      return 1;
    }
  }
}

// ----------------------------------------------------------------------

class Tree extends Node {
  String _filename;
  String virus_type;
  String lineage;

  String get filename => _filename;

  Tree._imported_from_json(Map<String, dynamic> data)
      : virus_type = data["v"],
        lineage = data["l"],
        super.cast(data["tree"]) {
    _upgrade(data["  version"]);
    // print("max_cumulative_lengths: ${max_cumulative_lengths}");
    // print("number_of_leaves: ${number_of_leaves}");
  }

  static Future<Tree> load({String filename, bool force_reload = false}) async {
    if (filename != null || force_reload) {
      if (filename == null) {
        filename = await choose_file_to_read(allowedFileTypes: <String>["json", "xz"]);
      }
      if (filename != null) {
        final content = await read_json_from_file(filename);
        if (content['  version'] != "newick-tree-v1" && content['  version'] != "phylogenetic-tree-v3") {
          throw "Unrecogned tree file version: ${content['  version']}";
        }
        final tree = Tree._imported_from_json(content);
        tree._filename = filename;
        return tree;
      }
    }
    return null;
  }

  void _upgrade(String version) {
    if (version == "newick-tree-v1") {
      _compute_cumulative_lengths();
    }
  }
}

// ======================================================================
