import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

import 'package:menubar/menubar.dart' as menubar;

import 'utilities.dart';
import 'canvas.dart';
import 'tree.dart';
import 'draw_tree.dart' show TreeCustomPainter, DrawTree;

// ======================================================================

class BilApp extends StatelessWidget {
  BilPage _home_page;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bil',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: BilPage(),
    );
  }
}

// ======================================================================

// https://github.com/google/flutter-desktop-embedding/blob/master/plugins/menubar/lib/src/menu_item.dart
void make_menubar(BilPageState bil_page_state) {
  menubar.setApplicationMenu(<menubar.Submenu>[
    menubar.Submenu(label: "File", children: <menubar.AbstractMenuItem>[
      // MenuItem(label: "Open ...", enabled: false),
      menubar.MenuItem(
        label: "Open Tree ...",
        shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyO),
        onClicked: () => bil_page_state.reload_tree(force: true),
        enabled: true,
      ),
    ]),
    menubar.Submenu(label: "Export", children: <menubar.AbstractMenuItem>[
      // MenuItem(label: "Open ...", enabled: false),
      menubar.MenuItem(
        label: "Pdf ...",
        shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyP),
        onClicked: () => bil_page_state.widget.draw_tree.make_pdf(),
        enabled: true,
      ),
    ]),
  ]);
}

// ======================================================================

class BilPage extends StatefulWidget {
  // final TreeData tree_data = TreeData();
  Tree _tree;
  DrawTree draw_tree = DrawTree();

  void set_tree(Tree tree) {
    _tree = tree;
    draw_tree.set_tree(tree);
  }

  @override
  BilPageState createState() => BilPageState();
}

// ----------------------------------------------------------------------

class BilPageState extends State<BilPage> {
  String _title = "Bil";

  String get title => _title;

  @override
  void initState() {
    super.initState();
    make_menubar(this);
    reload_tree();
  }

  void reload_tree({bool force = false}) async {
    widget.set_tree(await Tree.load(force_reload: force));
    setState(() {
      _title = widget._tree?.filename ?? "Bil 2";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
        centerTitle: false,
      ),

      body: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 4.0 / 3.0,
            child: CustomPaint(painter: TreeCustomPainter(widget.draw_tree)),
          ),
          Text("Bil"),
          Text("Bil"),
        ],
      ),
    );
  }

}

// ======================================================================
