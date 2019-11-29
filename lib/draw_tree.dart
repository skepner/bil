import 'dart:io' show File, Process;
import 'package:flutter/foundation.dart'; // @required
import 'package:flutter/material.dart';

import 'package:window_size/window_size.dart' show getWindowInfo, setWindowFrame;

import 'tree.dart';
import 'canvas.dart' show Leinwand, LeinwandCanvas, Pixels, draw_pdf;
import 'utilities.dart' show choose_file_to_write;

// ======================================================================

class DrawTree {
  Tree _tree;
  Size _size_painted;

  bool get has_tree => _tree != null;

  void set_tree(Tree tree) {
    _tree = tree;
    // print("DrawTree set_tree $_tree");
  }

  void make_pdf() async {
    final doc = draw_pdf(size: _size_painted, paint: (Leinwand leinwand) => this.paint(leinwand));
    final filename = await choose_file_to_write(suggestedFileName: "tree.pdf", allowedFileTypes: <String>["pdf"]);
    await File(filename).writeAsBytes(doc.save());
    final proc_result = await Process.run('open', [filename]);
    print(proc_result.stdout);
  }

  void paint(Leinwand leinwand, [Size size]) {
    if (has_tree) {
      if (size != null) {
        _size_painted = size;
      }
      print("DrawTree::paint leinwand size ${leinwand.size}");
      print("DrawTree::paint tree: $_tree  tree width (max_cumulative_length): ${_tree.max_cumulative_length}  num_leaves: ${_tree.number_of_leaves}");

      final vertical_step = leinwand.size.height / _tree.height;
      final horizontal_step = leinwand.size.width / _tree?.max_cumulative_length;
      print("horizontal_step: $horizontal_step  vertical_step: $vertical_step");

      leinwand.rectangle(leinwand.top_left & leinwand.size, outline: Color(0xFF008080), outline_width: Pixels(1.0));
      // leinwand.rectangle(const Offset(0.5, 0.5) & const Size(0.2, 0.1), outline: Color(0xFF008080), outline_width: Pixels(5.0), fill: Color(0xFFFF80FF));

      // leinwand.line(Offset(0, 0), Offset(0.2, 0.2), Color(0xFFff0000), Pixels(5.0));
      // leinwand.line(Offset(0, leinwand.size.height), Offset(0.2, leinwand.size.height - 0.2), Color(0xFF00ff00), Pixels(5.0));
      // leinwand.line(Offset(0.2, 0.2), Offset(0.2, leinwand.size.height - 0.1), Color(0xFF0000ff), Pixels(5.0));

      // leinwand.circle(Offset(0.5, 0.5), Pixels(5.0), outline: Color(0xFF0000ff), outline_width: Pixels(1.0), fill: Color(0xFFffff00));
      // leinwand.circle(Offset(0.5, 0.45), Pixels(5.0), outline: Color(0xFF0000ff), outline_width: Pixels(1.0), fill: Color(0xFFffff00));
      // leinwand.circle(Offset(0.55, 0.6), Pixels(25.0), outline: Color(0xFF0000ff), outline_width: Pixels(5.0), fill: Color(0xFFffff00));
      // leinwand.circle(Offset(0.65, 0.6), Pixels(25.0), outline: Color(0xFF0000ff), outline_width: Pixels(5.0), fill: Color(0xA0ffff00));
    }
  }
}

// ======================================================================

class TreeCustomPainter extends CustomPainter {
  DrawTree _draw_tree;
  // int _paint_no = 0;

  TreeCustomPainter(DrawTree draw_tree)
      : _draw_tree = draw_tree,
        super();

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => _draw_tree.has_tree;

  // void resize_window(Canvas canvas, Size size) async {
  //   var win_info = await getWindowInfo();
  //   if (win_info.frame.width < 500.0) {
  //     await setWindowFrame(win_info.frame.topLeft & Size.square(500.0));
  //   } else if (win_info.frame.width != win_info.frame.height) {
  //     await setWindowFrame(win_info.frame.topLeft & Size.square(win_info.frame.width));
  //   }
  // }

  @override
  void paint(Canvas canvas, Size size) {
    // resize_window(canvas, size);
    if (size.width >= 500.0) {
      // ++_paint_no;
      // print("paint $_paint_no $size");
      _draw_tree.paint(LeinwandCanvas(canvas, size), size);
    }

    // print("paint $size");
    // var leinwand = LeinwandCanvas(canvas);
    // leinwand.line(Offset(size.width - 100, 100), Offset(size.width + 100, 100), Color(0xFFff0000), 5.0);

    // var para_b = ParagraphBuilder(ParagraphStyle(textDirection: TextDirection.ltr))
    //   ..pushStyle(ui.TextStyle(color: const Color(0xFF0000FF)))
    //   ..addText("JOPA\n")
    //   ..pop()
    //   ..pushStyle(ui.TextStyle(color: const Color(0xFFFF00FF), fontSize: 20))
    //   ..addText("JOPA\n")
    //   ..pop()
    //   ..pushStyle(ui.TextStyle(color: const Color(0xFF00FFFF), fontSize: 1))
    //   ..addText("JOPA\n");
    // canvas.drawParagraph(para_b.build()..layout(ParagraphConstraints(width: 500)), Offset(20, 10));
  }
}

// ======================================================================
