import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FloatingWindow extends StatefulWidget {
  const FloatingWindow({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.onClose,
    this.initialOffset = const Offset(80, 120),
    this.width = 380,
    this.height = 520,
    this.accentColor,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onClose;
  final Offset initialOffset;
  final double width;
  final double height;
  final Color? accentColor;

  @override
  State<FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<FloatingWindow>
    with SingleTickerProviderStateMixin {
  late Offset _offset;
  bool _isMinimized = false;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _offset = widget.initialOffset;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final screenSize = MediaQuery.of(context).size;
    setState(() {
      _offset = Offset(
        (_offset.dx + details.delta.dx)
            .clamp(0, screenSize.width - widget.width),
        (_offset.dy + details.delta.dy)
            .clamp(0, screenSize.height - (_isMinimized ? 56 : widget.height)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppPalette.gold;

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: ScaleTransition(
        scale: _scaleAnim,
        alignment: Alignment.topLeft,
        child: Material(
          color: Colors.transparent,
          elevation: 24,
          shadowColor: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: widget.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1028).withOpacity(0.97),
                    const Color(0xFF0E0A18).withOpacity(0.99),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.08),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title bar (drag handle)
                  GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withOpacity(0.18),
                            accent.withOpacity(0.06),
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: accent.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(widget.icon, color: accent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                color: accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Cursor hint
                          Icon(
                            Icons.drag_indicator_rounded,
                            color: Colors.white.withOpacity(0.2),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          // Minimize button
                          _TitleBarButton(
                            icon: _isMinimized
                                ? Icons.expand_more_rounded
                                : Icons.remove_rounded,
                            color: Colors.white.withOpacity(0.6),
                            tooltip: _isMinimized ? 'Maximieren' : 'Minimieren',
                            onTap: () =>
                                setState(() => _isMinimized = !_isMinimized),
                          ),
                          const SizedBox(width: 4),
                          // Close button
                          _TitleBarButton(
                            icon: Icons.close_rounded,
                            color: Colors.redAccent.withOpacity(0.8),
                            tooltip: 'Schließen',
                            onTap: widget.onClose,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Body
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _isMinimized
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: SizedBox(
                      height: widget.height - 52,
                      child: widget.child,
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBarButton extends StatelessWidget {
  const _TitleBarButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
        ),
      ),
    );
  }
}
