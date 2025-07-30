import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? text;
  final bool isLoading;
  final double borderRadius;
  final double height;
  final double? width;
  final List<Color> gradientColors;

  const GradientButton({
    super.key,
    this.onPressed,
    this.child,
    this.text,
    this.isLoading = false,
    this.borderRadius = 30,
    this.height = 48,
    this.width,
    this.gradientColors = const [
      Color(0xFFEF6850),
      Color(0xFF8B2192),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1.0,
      child: Container(
        width: width,
        height: height,
        constraints: BoxConstraints(
          minWidth: width ?? 0,
          maxWidth: width ?? double.infinity,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            stops: const [0.4, 0.8],
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (child != null) {
      // If child is a Text widget, ensure it has white color
      if (child is Text) {
        final textChild = child as Text;
        return Text(
          textChild.data ?? '',
          style: textChild.style?.copyWith(color: Colors.white) ??
              const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
        );
      }
      return child!;
    }

    return Text(
      text ?? '',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
