import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

class DecodeImagePicker extends StatefulWidget {
  final bool hasImage;
  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final bool isScanning;

  const DecodeImagePicker({
    super.key,
    required this.hasImage,
    required this.imageBytes,
    required this.onTap,
    this.isScanning = false,
  });

  @override
  State<DecodeImagePicker> createState() => _DecodeImagePickerState();
}

class _DecodeImagePickerState extends State<DecodeImagePicker> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isScanning) {
      _scanController.repeat();
    }
  }

  @override
  void didUpdateWidget(DecodeImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !oldWidget.isScanning) {
      _scanController.repeat();
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _scanController.stop();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: widget.hasImage ? 240 : 200,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: scheme.surfaceContainerLow,
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.hasImage && widget.imageBytes != null) ...[
                Image.memory(widget.imageBytes!, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                if (widget.isScanning)
                  AnimatedBuilder(
                    animation: _scanController,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          Positioned(
                            top: _scanController.value * 240,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.primary.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  scheme.primary.withValues(alpha: 0.05),
                                  Colors.transparent,
                                ],
                                stops: [
                                  (_scanController.value - 0.2).clamp(0.0, 1.0),
                                  _scanController.value,
                                  (_scanController.value + 0.2).clamp(0.0, 1.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Change Image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ] else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.file_open_rounded, size: 32, color: scheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Encoded Image',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPEG, PNG or WEBP up to 20MB',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
