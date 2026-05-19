import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/agent_log.dart';
import 'pulsing_dot.dart';

class AgentBadge extends StatelessWidget {
  final AgentId agentId;
  final bool isActive;
  final bool compact;

  const AgentBadge({
    super.key,
    required this.agentId,
    this.isActive = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final info = agentRegistry[agentId]!;
    final color = Color(info.colorValue);
    final bgColor = Color(info.bgColorValue);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              PulsingDot(color: color, size: 6),
              const SizedBox(width: 6),
            ] else ...[
              Icon(Icons.check_circle, color: color, size: 12),
              const SizedBox(width: 6),
            ],
            Text(
              info.name,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.6) : color.withValues(alpha: 0.2),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 2)]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_awesome, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      info.name,
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      info.urduName,
                      style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  info.description,
                  style: GoogleFonts.inter(
                    color: color.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            PulsingDot(color: color, size: 10)
                .animate(onPlay: (c) => c.repeat())
          else
            Icon(Icons.check_circle_outline, color: color, size: 18),
        ],
      ),
    );
  }
}
