import 'dart:math' show max;
import 'dart:collection' show IterableBase;

import 'utilities.dart' show read_json_from_file, choose_file_to_read;

// ======================================================================

// Node is a thin wrapper over _data, it is created/destroyed in get children, it cannot have fields
class Node {
  Map<String, dynamic> _data;

  Node.cast(dynamic data) : _data = data as Map<String, dynamic>;

  double get edge => _data["l"] ?? 0.0;
  double get cumulative => _data["c"];
  void set cumulative(double cumul) => _data["c"] = cumul;
  Iterable<Node> get children => _data["t"].map<Node>((dynamic elt) => Node.cast(elt)); // .toList(growable: false);
  bool get has_children => !(_data["t"]?.isEmpty ?? true);
  Iterable<Node> get shown_children => children.where((Node node) => !node.hidden);
  bool get hidden => _data["H"] ?? false;
  String get seq_id => _data["n"];
  String get aa => _data["a"];
  String get date => _data["d"];
  String get continent => _data["C"];
  String get country => _data["D"];
  List<String> get hi_names => _data["h"];
  List<String> get aa_substitutions => _data["A"];
  List<String> get clades => _data["L"];

  double get _vertical_offset => _data["_vertical_offset"];
  void set _vertical_offset(double vo) => _data["_vertical_offset"] = vo;
  double get _cumulative_vertical_offset => _data["_cumulative_vertical_offset"];
  double set _cumulative_vertical_offset(double cvo) => _data["_cumulative_vertical_offset"] = cvo;
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

  void iterate_and_call({void Function(Node) pre, void Function(Node) leaf, void Function(Node) post, Node node, shown_only: true}) {
    node ??= this;
    if (!shown_only || !node.hidden) {
      if (node.has_children) {
        pre?.call(node);
        for (Node child in node.children) {
          iterate_and_call(pre: pre, leaf: leaf, post: post, node: child, shown_only: shown_only);
        }
        post?.call(node);
      } else {
        leaf?.call(node);
      }
    }
  }

  // ----------------------------------------------------------------------
  // Width and height
  // ----------------------------------------------------------------------

  void _compute_cumulative_lengths() {
    double cumul = 0.0;
    iterate_and_call(
      pre: (Node node) {
        cumul += node.edge;
        node.cumulative = cumul;
      },
      leaf: (Node node) => node.cumulative = cumul + node.edge,
      post: (Node node) => cumul -= node.edge,
      shown_only: false,
    );
  }

  // must be called upon hiding leaves and upon inserting gaps
  double _compute_cumulative_vertical_offsets() {
    double cumul = 0.0;
    iterate_and_call(
      leaf: (Node node) {
        node._vertical_offset ??= 1.0; // may be already set by gap making function
        cumul += node._vertical_offset;
        node._cumulative_vertical_offset = cumul;
        // print("leaf ${node._cumulative_vertical_offset} ${node.seq_id}");
      },
      post: (Node node) {
        var shown_children = node.shown_children;
        if (!shown_children.isEmpty) {
          node._cumulative_vertical_offset = (shown_children.first._cumulative_vertical_offset + shown_children.last._cumulative_vertical_offset) / 2.0;
        }
        else {
          print("WARNING: _compute_cumulative_vertical_offsets: shown node has no shown children");
        }
      },
      shown_only: false,
    );
    return cumul;
  }

  double get max_cumulative_length {
    double mcl = 0.0;
    iterate_and_call(leaf: (Node node) => mcl = max(mcl, node.cumulative), shown_only: true);
    return mcl;
  }

  int get number_of_leaves {
    int num_leaves = 0;
    iterate_and_call(leaf: (Node node) => ++num_leaves, shown_only: true);
    return num_leaves;
  }

  // ----------------------------------------------------------------------
  // constructing
  // ----------------------------------------------------------------------

  Tree._imported_from_json(Map<String, dynamic> data)
      : virus_type = data["v"],
        lineage = data["l"],
        super.cast(data["tree"]) {
    _upgrade(data["  version"]);
    final tree_height = _compute_cumulative_vertical_offsets();
    print("tree_height: $tree_height");
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

// ======================================================================
