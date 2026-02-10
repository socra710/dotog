import 'package:flutter/material.dart';

class AtmosphericScaffold extends StatelessWidget {
  const AtmosphericScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.actions,
    required this.body,
    this.footer,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final Widget? badge;
  final List<Widget>? actions;
  final Widget body;
  final Widget? footer;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1F2A24),
                  Color(0xFF2A3C33),
                  Color(0xFF0E1411),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -40,
            child: _Orb(
              size: size.width * 0.6,
              color: const Color(0xFF5FD1B7).withOpacity(0.18),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _Orb(
              size: size.width * 0.75,
              color: const Color(0xFFE7C46A).withOpacity(0.12),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (showBack)
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.white70,
                        ),
                      if (badge != null) badge!,
                      const Spacer(),
                      ...?actions,
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF3F8F2),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontFamily: 'Galmuri11',
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Expanded(child: body),
                  if (footer != null) ...[
                    const SizedBox(height: 16),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}
