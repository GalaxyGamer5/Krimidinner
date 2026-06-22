import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A full-screen overlay that shows an evidence image.
/// The user can tap anywhere or the close button to dismiss.
class EvidenceLightbox extends StatefulWidget {
  const EvidenceLightbox({
    super.key,
    required this.title,
    required this.description,
    required this.assetPath,
    this.isNetworkImage = false,
  });

  final String title;
  final String description;
  final String assetPath;
  final bool isNetworkImage;

  @override
  State<EvidenceLightbox> createState() => _EvidenceLightboxState();
}

class _EvidenceLightboxState extends State<EvidenceLightbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: GestureDetector(
        onTap: _dismiss,
        child: Scaffold(
          backgroundColor: Colors.black.withOpacity(0.92),
          body: Stack(
            children: [
              // Image
              Center(
                child: ScaleTransition(
                  scale: _scale,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: AppPalette.gold,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Image card
                        GestureDetector(
                          onTap: () {}, // consume tap so it doesn't dismiss
                          child: Container(
                            constraints: const BoxConstraints(
                              maxWidth: 900,
                              maxHeight: 600,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppPalette.gold.withOpacity(0.2),
                                  blurRadius: 60,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: widget.isNetworkImage
                                  ? Image.network(
                                      widget.assetPath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          _errorWidget(),
                                    )
                                  : Image.asset(
                                      widget.assetPath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          _errorWidget(),
                                    ),
                            ),
                          ),
                        ),
                        if (widget.description.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            widget.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          'Tippe irgendwo zum Schließen',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 40,
                right: 24,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return Container(
      width: 400,
      height: 300,
      color: Colors.white.withOpacity(0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded,
              color: Colors.white.withOpacity(0.3), size: 64),
          const SizedBox(height: 12),
          Text(
            'Bild konnte nicht geladen werden',
            style: TextStyle(color: Colors.white.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }
}

/// Small thumbnail card used inside the Evidence floating window.
class EvidenceThumbnail extends StatelessWidget {
  const EvidenceThumbnail({
    super.key,
    required this.title,
    required this.description,
    required this.assetPath,
    this.isNetworkImage = false,
    this.unlockedLabel,
  });

  final String title;
  final String description;
  final String assetPath;
  final bool isNetworkImage;
  final String? unlockedLabel;

  void _openLightbox(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, _, __) => EvidenceLightbox(
          title: title,
          description: description,
          assetPath: assetPath,
          isNetworkImage: isNetworkImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openLightbox(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.gold.withOpacity(0.25)),
          color: Colors.white.withOpacity(0.04),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  isNetworkImage
                      ? Image.network(assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder())
                      : Image.asset(assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder()),
                  // Hover overlay
                  Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white.withOpacity(0),
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.parchment),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (unlockedLabel != null)
                    Text(
                      unlockedLabel!,
                      style: TextStyle(
                          fontSize: 10,
                          color: AppPalette.gold.withOpacity(0.7)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: Icon(Icons.image_rounded,
          color: Colors.white.withOpacity(0.2), size: 40),
    );
  }
}
