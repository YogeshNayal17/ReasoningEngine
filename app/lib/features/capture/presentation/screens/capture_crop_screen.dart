import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../controllers/capture_controller.dart';

/// Lets the user drag a rectangle over the just-captured screenshot and
/// crops to it — this is plain Flutter UI (unlike the overlay bubble)
/// because it only runs once the app is already in the foreground, so
/// none of the system-overlay-window constraints apply here.
class CaptureCropScreen extends ConsumerStatefulWidget {
  const CaptureCropScreen({super.key});

  @override
  ConsumerState<CaptureCropScreen> createState() => _CaptureCropScreenState();
}

class _CaptureCropScreenState extends ConsumerState<CaptureCropScreen> {
  Rect? _selection;
  Offset? _dragStart;
  Size _widgetSize = Size.zero;
  bool _isCropping = false;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _dragStart = details.localPosition;
      _selection = Rect.fromPoints(details.localPosition, details.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final start = _dragStart;
    if (start == null) return;
    setState(() {
      _selection = Rect.fromPoints(start, details.localPosition);
    });
  }

  Future<void> _confirmCrop(Uint8List sourceBytes) async {
    final selection = _selection;
    if (selection == null || selection.width < 4 || selection.height < 4) return;

    setState(() => _isCropping = true);

    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final image = frame.image;

    // Map the on-screen selection (widget coordinates) to image-pixel
    // coordinates, accounting for BoxFit.contain's scale + letterboxing.
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.contain, imageSize, _widgetSize);
    final displayedSize = fitted.destination;
    final offsetX = (_widgetSize.width - displayedSize.width) / 2;
    final offsetY = (_widgetSize.height - displayedSize.height) / 2;
    final scale = imageSize.width / displayedSize.width;

    final cropRect = Rect.fromLTRB(
      ((selection.left - offsetX).clamp(0, displayedSize.width)) * scale,
      ((selection.top - offsetY).clamp(0, displayedSize.height)) * scale,
      ((selection.right - offsetX).clamp(0, displayedSize.width)) * scale,
      ((selection.bottom - offsetY).clamp(0, displayedSize.height)) * scale,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      cropRect,
      Rect.fromLTWH(0, 0, cropRect.width, cropRect.height),
      Paint(),
    );
    final cropped = await recorder.endRecording().toImage(
      cropRect.width.round().clamp(1, 1 << 20),
      cropRect.height.round().clamp(1, 1 << 20),
    );
    final byteData = await cropped.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    cropped.dispose();

    if (!mounted || byteData == null) return;
    ref.read(captureControllerProvider.notifier).setCroppedImage(byteData.buffer.asUint8List());
    setState(() => _isCropping = false);
    if (mounted) unawaited(context.push(RoutePaths.ocrResult));
  }

  @override
  Widget build(BuildContext context) {
    final bytes = ref.watch(captureControllerProvider).lastCapture;

    return Scaffold(
      appBar: AppBar(title: const Text('Drag to select text')),
      body: bytes == null
          ? const Center(child: Text('No capture available.'))
          : LayoutBuilder(
              builder: (context, constraints) {
                _widgetSize = constraints.biggest;
                return GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(bytes, fit: BoxFit.contain),
                      if (_selection != null) CustomPaint(painter: _SelectionPainter(_selection!)),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: bytes == null || _selection == null
          ? null
          : FloatingActionButton(
              onPressed: _isCropping ? null : () => unawaited(_confirmCrop(bytes)),
              child: _isCropping
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
            ),
    );
  }
}

/// Dims everything outside the selection and outlines it, snip-tool style.
class _SelectionPainter extends CustomPainter {
  _SelectionPainter(this.selection);

  final Rect selection;

  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = const Color(0x99000000);
    final fullRect = Offset.zero & size;

    canvas.drawRect(Rect.fromLTRB(fullRect.left, fullRect.top, fullRect.right, selection.top), dimPaint);
    canvas.drawRect(Rect.fromLTRB(fullRect.left, selection.bottom, fullRect.right, fullRect.bottom), dimPaint);
    canvas.drawRect(Rect.fromLTRB(fullRect.left, selection.top, selection.left, selection.bottom), dimPaint);
    canvas.drawRect(Rect.fromLTRB(selection.right, selection.top, fullRect.right, selection.bottom), dimPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(selection, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) => oldDelegate.selection != selection;
}
