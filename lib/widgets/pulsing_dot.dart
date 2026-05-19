import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class PulsingDot extends StatelessWidget {
  final Color color;
  final double size;

  const PulsingDot({super.key, this.color = AppColors.primary, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(begin: 0.8, end: 1.2, duration: 800.ms, curve: Curves.easeInOut)
        .then()
        .scaleXY(begin: 1.2, end: 0.8, duration: 800.ms, curve: Curves.easeInOut);
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .moveY(
                  begin: 0,
                  end: -6,
                  delay: (i * 150).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                )
                .then()
                .moveY(begin: -6, end: 0, duration: 400.ms, curve: Curves.easeIn),
          ),
      ],
    );
  }
}
