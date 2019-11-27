import 'dart:math' show max;
import 'dart:collection' show IterableBase;

import 'utilities.dart' show read_json_from_file, choose_file_to_read;

// ======================================================================

class Node {
  Map<String, dynamic> _data;
  double _vertical_offset;
  double _cumulative_vertical_offset;

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

  void _compute_cumulative_lengths_old({double cumul = 0.0}) {
    cumul += this.edge;
    _data["c"] = cumul;
    if (this.has_children) {
      for (Node subtree in this.children) {
        subtree._compute_cumulative_lengths(cumul: cumul);
      }
    }
  }

  double _compute_cumulative_vertical_offsets({double cumul = 0.0}) {
    //   if (!hidden) {
    //     cumul += _vertical_offset;
    //     _cumulative_vertical_offset = cumul;
    //     if (this.has_children) {
    //       for (Node subtree in this.children) {
    //         subtree._compute_cumulative_vertical_offsets(cumul: _cumulative_vertical_offset);
    //       }
    //     } else {
    //       _vertical_offset = 1.0;
    //       cumul += _vertical_offset;
    //       _cumulative_vertical_offset = cumul;
    //     }
    //   }
    return cumul;
  }

  double get max_cumulative_length {
    if (this.has_children) {
      return this.children.map<double>((Node node) => !node.hidden ? node.max_cumulative_length : 0.0).fold(0.0, max);
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

  // ----------------------------------------------------------------------
  // iterating
  // ----------------------------------------------------------------------

  // TreeLeafIterator leaves() => TreeLeafIterator(this);

  void all_leaves(void Function(Node) callback, [Node node]) {
    if (node == null) {
      node = this;
    }
    if (node.has_children) {
      for (final child in node.children) {
        all_leaves(callback, child);
      }
    }
    else {
      callback(node);
    }
  }

  void all_nodes(void Function(Node) callback, [Node node]) {
    if (node == null) {
      node = this;
    }
    callback(node);
    if (node.has_children) {
      for (final child in node.children) {
        all_nodes(callback, child);
      }
    }
  }

  // ----------------------------------------------------------------------

  // void _compute_cumulative_lengths({double cumul = 0.0}) {
  //   all_nodes((Node node) {
  //   });
  // }

  // ----------------------------------------------------------------------
  // constructing
  // ----------------------------------------------------------------------

  Tree._imported_from_json(Map<String, dynamic> data)
      : virus_type = data["v"],
        lineage = data["l"],
        super.cast(data["tree"]) {
    _upgrade(data["  version"]);
    // _compute_cumulative_vertical_offsets();
    // print("max_cumulative_lengths: ${max_cumulative_lengths}");
    // print("number_of_leaves: ${number_of_leaves}");

    // all_leaves((Node leaf) => print("${leaf.seq_id}"));
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
        final tree = new Tree._imported_from_json(content);
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

// ----------------------------------------------------------------------

// class TreeLeafIterator extends IterableBase<Node> implements Iterator<Node> {
//   List<int> _child_indexes = [];
//   List<Node> _parents = [];
//   Node _current;

//   TreeLeafIterator(Tree root) {
//     _parents.add(root);
//   }

//   @override
//   Node get current => _current;

//   @override
//   bool moveNext() {
//     if (_child_indexes.isEmpty) {
//       _current = _find_first_leaf(_parents[0]);
//       // print("moveNext ${_child_indexes}");
//       return true;
//     } else {
//       final cur = _find_next_leaf();
//       if (cur == null) {
//         return false;
//       } else {
//         _current = cur;
//         return true;
//       }
//     }
//   }

//   @override
//   TreeLeafIterator get iterator => this;

//   Node _find_first_leaf(Node start) {
//     if (start.has_children) {
//       _parents.add(start);
//       _child_indexes.add(0);
//       return _find_first_leaf(start.children[0]);
//     } else {
//       return start;
//     }
//   }

//     Node _find_next_leaf(Node start) {

// }

// ======================================================================
