import 'dart:ui' show Offset, Size, Rect, Canvas, Color, Paint, PaintingStyle;
import 'package:flutter/foundation.dart'; // @required
import 'package:flutter/material.dart' show Matrix4;

import 'package:pdf/pdf.dart' show PdfGraphics, PdfColor, PdfPageFormat;
import 'package:pdf/widgets.dart' show PdfLineCap, Document, Page, Context;

// ======================================================================

class Pixels {
  final double _value;
  const Pixels(this._value);
}

class Scaled {
  final double _value;
  const Scaled(this._value);
}

// ======================================================================

abstract class Leinwand {
  double _scale;
  final Size size;
  Offset get top_left => Offset(0.0, 0.0);
  Offset get bottom_right => Offset(size.width, size.height);
  Leinwand(Size size)
      : _scale = 1.0,
        size = Size(size.width / size.height, 1.0) {
    scale(size.height);
  }
  void save();
  void restore();
  void scale(double scal) => _scale *= scal;
  void line_scaled(Offset p1, Offset p2, Color color, Scaled width); // LineCap, Dash
  void line(Offset p1, Offset p2, Color color, Pixels width) => line_scaled(p1, p2, color, _pixels_to_scaled(width)); // LineCap, Dash
  void rectangle_scaled(Rect rect, {Color outline, Scaled outline_width = const Scaled(0.0), Color fill});
  void rectangle(Rect rect, {Color outline, Pixels outline_width = const Pixels(1.0), Color fill}) =>
      rectangle_scaled(rect, outline: outline, outline_width: _pixels_to_scaled(outline_width), fill: fill);
  void circle_scaled(Offset center, Scaled radius, {Color outline, Scaled outline_width = const Scaled(0.0), Color fill});
  void circle(Offset center, Pixels radius, {Color outline, Pixels outline_width = const Pixels(1.0), Color fill}) =>
      circle_scaled(center, _pixels_to_scaled(radius), outline: outline, outline_width: _pixels_to_scaled(outline_width), fill: fill);
  Scaled _pixels_to_scaled(Pixels pix) => Scaled(pix._value / _scale);
}

// ----------------------------------------------------------------------

abstract class LeinwandDraw<Draw> extends Leinwand {
  Draw canvas_;

  LeinwandDraw(this.canvas_, Size size) : super(size);
}

// ======================================================================

// Draw dashed lines: https://pub.dev/packages/path_drawing

class LeinwandCanvas extends LeinwandDraw<Canvas> {
  LeinwandCanvas(Canvas canvas, Size size) : super(canvas, size);

  @override
  void save() => canvas_.save();

  @override
  void restore() => canvas_.restore();

  @override
  void scale(double scal) {
    super.scale(scal);
    canvas_.scale(scal);
  }

  @override
  void line_scaled(Offset p1, Offset p2, Color color, Scaled width) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width._value
      ..color = color;
    canvas_.drawLine(p1, p2, paint);
  }

  @override
  void rectangle_scaled(Rect rect, {Color outline, Scaled outline_width = const Scaled(0.0), Color fill}) {
    if (outline == null && fill == null) {
      throw "rectangle() must be called with either outline= or fill=";
    }
    if (fill != null) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = fill;
      canvas_.drawRect(rect, paint);
    }
    if (outline != null && outline_width._value > 0.0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outline_width._value
        ..color = outline;
      canvas_.drawRect(rect, paint);
    }
  }

  @override
  void circle_scaled(Offset center, Scaled radius, {Color outline, Scaled outline_width = const Scaled(0.0), Color fill}) {
    if (outline == null && fill == null) {
      throw "circle() must be called with either outline= or fill=";
    }
    if (fill != null) {
      canvas_.drawCircle(
          center,
          radius._value,
          Paint()
            ..style = PaintingStyle.fill
            ..color = fill);
    }
    if (outline != null && outline_width._value > 0.0) {
      canvas_.drawCircle(
          center,
          radius._value,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = outline_width._value
            ..color = outline);
    }
  }
}

// ======================================================================

class LeinwandPdf extends LeinwandDraw<PdfGraphics> {
  LeinwandPdf(PdfGraphics canvas, Size size) : super(canvas, size) {
    flip_ns();
  }

  @override
  void save() => canvas_.saveContext();

  @override
  void restore() => canvas_.restoreContext();

  @override
  void scale(double scal) {
    super.scale(scal);
    final mat = Matrix4.identity();
    mat.scale(scal, scal);
    canvas_.setTransform(mat);
  }

  @override
  void line_scaled(Offset p1, Offset p2, Color color, Scaled width) {
    canvas_
          // ..saveContext()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..setStrokeColor(pdf_color(color))
          ..setLineWidth(width._value)
          // ..setLineJoin(pdf.PdfLineCap join)
          // ..setLineCap(pdf.PdfLineCap cap)
          ..strokePath()
        // ..restoreContext()
        ;

    // print("LeinwandPdf::line $p1 $p2 $color $width");
  }

  @override
  void rectangle_scaled(Rect rect, {Color outline, Scaled outline_width = const Scaled(0.0), Color fill}) {
    if (outline == null && fill == null) {
      throw "rectangle() must be called with either outline= or fill=";
    }
    // canvas_.saveContext()
    if (fill != null) {
      canvas_
        ..setFillColor(pdf_color(fill))
        ..drawRect(rect.left, rect.top, rect.width, rect.height)
        ..fillPath();
    }
    if (outline != null && outline_width._value > 0.0) {
      canvas_
        ..setStrokeColor(pdf_color(outline))
        ..setLineWidth(outline_width._value)
        ..drawRect(rect.left, rect.top, rect.width, rect.height)
        ..strokePath();
    }
    // canvas_.restoreContext();
  }

  @override
  void circle_scaled(Offset center, Scaled radius, {Color outline, Scaled outline_width = const Scaled(0.0), Color fill}) {
    if (outline == null && fill == null) {
      throw "circle() must be called with either outline= or fill=";
    }
    // canvas_.saveContext()
    if (fill != null) {
      canvas_
        ..setFillColor(pdf_color(fill))
        ..drawEllipse(center.dx, center.dy, radius._value, radius._value)
        ..fillPath();
    }
    if (outline != null && outline_width._value > 0.0) {
      canvas_
        ..setStrokeColor(pdf_color(outline))
        ..setLineWidth(outline_width._value)
        ..drawEllipse(center.dx, center.dy, radius._value, radius._value)
        ..strokePath();
    }
    // canvas_.restoreContext();
  }

  PdfColor pdf_color(Color src) => PdfColor.fromInt(src.value);

  void flip_ns() {
    // print("flip_ns ${canvas_.page.pageFormat.width} x ${canvas_.page.pageFormat.height}");
    final mat = Matrix4.identity();
    // mat.setRotationZ(0.5);
    mat.scale(1.0, -1.0, 1.0);
    mat.translate(0.0, -size.height);
    canvas_.setTransform(mat);
  }
}

// ----------------------------------------------------------------------

Document draw_pdf({@required Size size, @required void Function(Leinwand) paint}) {
  final doc = Document();
  doc.addPage(Page(
    pageFormat: PdfPageFormat(size.width, size.height),
    build: (Context context) {
      paint(LeinwandPdf(context.canvas, size));
    },
  ));
  return doc;
}

// ======================================================================
