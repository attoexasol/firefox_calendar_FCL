import 'package:flutter/material.dart';

/// Hoverable card widget with hover effect
class HoverableCard extends StatefulWidget {
  final bool isDark;
  final Color baseColor;
  final VoidCallback onTap;
  final Widget child;
  final BoxDecoration? decoration;

  const HoverableCard({
    super.key,
    required this.isDark,
    required this.baseColor,
    required this.onTap,
    required this.child,
    this.decoration,
  });

  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;
    if (_isHovered) {
      // Apply hover effect
      if (widget.decoration != null) {
        decoration = BoxDecoration(
          color: widget.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          borderRadius: widget.decoration!.borderRadius,
          border: widget.decoration!.border,
        );
      } else {
        decoration = BoxDecoration(
          color: widget.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        );
      }
    } else {
      decoration = widget.decoration ??
          BoxDecoration(
            color: widget.baseColor,
            borderRadius: BorderRadius.circular(4),
          );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: widget.decoration != null 
              ? EdgeInsets.zero // If custom decoration is provided, let the child handle padding
              : const EdgeInsets.all(4), // Default padding for other cards
          decoration: decoration,
          child: widget.child,
        ),
      ),
    );
  }
}

