import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/onboarding_provider.dart';

// ── Data ──────────────────────────────────────────────────────────────────────

class _PageData {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final List<Color> blobColors;
  final List<_Feature> features;
  final List<_FloatingCard> cards;

  const _PageData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.blobColors,
    required this.features,
    required this.cards,
  });
}

class _Feature {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);
}

class _FloatingCard {
  final String emoji;
  final String text;
  final Alignment alignment;
  const _FloatingCard(this.emoji, this.text, this.alignment);
}

const _pages = [
  _PageData(
    emoji: '💊',
    title: 'Médicaments\norganisés',
    subtitle: 'Planifiez chaque traitement et ne manquez plus aucune prise.',
    gradient: [Color(0xFF7C5CBF), Color(0xFF9B7EBD)],
    blobColors: [Color(0xFF6A4CA8), Color(0xFFB89DD4)],
    features: [
      _Feature(Icons.add_circle_outline_rounded, 'Ajoutez en quelques secondes'),
      _Feature(Icons.palette_outlined, 'Organisez par couleur et horaire'),
      _Feature(Icons.history_rounded, 'Suivez l\'historique de chaque prise'),
    ],
    cards: [
      _FloatingCard('💊', 'Doliprane 500mg • 08:00', Alignment.topRight),
      _FloatingCard('💉', 'Insuline • 12:30', Alignment.bottomLeft),
    ],
  ),
  _PageData(
    emoji: '🔔',
    title: 'Rappels\nintelligents',
    subtitle: 'Des alertes précises pour chaque médicament, à l\'heure exacte.',
    gradient: [Color(0xFF9B7EBD), Color(0xFFD06090)],
    blobColors: [Color(0xFF8B6BAD), Color(0xFFE8A0BF)],
    features: [
      _Feature(Icons.access_alarm_rounded, 'Notification à l\'heure choisie'),
      _Feature(Icons.sentiment_satisfied_alt_rounded, 'Suivez votre humeur après chaque prise'),
      _Feature(Icons.bar_chart_rounded, 'Consultez vos statistiques d\'observance'),
    ],
    cards: [
      _FloatingCard('⏰', 'Rappel dans 5 min', Alignment.topLeft),
      _FloatingCard('✅', 'Pris à 08:02', Alignment.bottomRight),
    ],
  ),
  _PageData(
    emoji: '👨‍👩‍👧',
    title: 'Famille\nconnectée',
    subtitle: 'Vos proches reçoivent une alerte quand vous prenez ou oubliez un médicament.',
    gradient: [Color(0xFFD06090), Color(0xFF9B7EBD)],
    blobColors: [Color(0xFFE8A0BF), Color(0xFFB89DD4)],
    features: [
      _Feature(Icons.qr_code_rounded, 'Partagez votre code famille'),
      _Feature(Icons.notifications_active_rounded, 'Alertes prises et oubliés en temps réel'),
      _Feature(Icons.insert_chart_outlined_rounded, 'Rapport PDF hebdomadaire'),
    ],
    cards: [
      _FloatingCard('⚠️', 'Médicament oublié !', Alignment.topRight),
      _FloatingCard('✅', 'Ahmed a pris Doliprane', Alignment.bottomLeft),
    ],
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;
  late final AnimationController _blobCtrl;

  @override
  void initState() {
    super.initState();
    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _blobCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(onboardingDoneProvider.notifier).markDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Pages ────────────────────────────────────────────────────
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _OnboardingPage(
              data: _pages[i],
              blobCtrl: _blobCtrl,
            ),
          ),

          // ── Bottom controls ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: active ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),

                    // Next / Start button
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _pages[_page].gradient.first,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      onPressed: _next,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _page == _pages.length - 1
                              ? 'Commencer'
                              : 'Suivant',
                          key: ValueKey(_page),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),

                    // Skip
                    if (_page < _pages.length - 1) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _finish,
                        child: Text(
                          'Passer',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 42),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single page ───────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  final AnimationController blobCtrl;
  const _OnboardingPage({required this.data, required this.blobCtrl});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // ── Animated background blobs ────────────────────────────────
          _AnimatedBlob(
            ctrl: blobCtrl,
            color: data.blobColors[0].withValues(alpha: 0.35),
            size: size.width * 0.75,
            startOffset: const Offset(-0.15, -0.18),
            endOffset: const Offset(-0.05, -0.08),
          ),
          _AnimatedBlob(
            ctrl: blobCtrl,
            color: data.blobColors[1].withValues(alpha: 0.28),
            size: size.width * 0.65,
            startOffset: const Offset(0.35, 0.55),
            endOffset: const Offset(0.25, 0.48),
          ),
          _AnimatedBlob(
            ctrl: blobCtrl,
            color: Colors.white.withValues(alpha: 0.08),
            size: size.width * 0.4,
            startOffset: const Offset(0.5, 0.1),
            endOffset: const Offset(0.6, 0.18),
          ),

          // ── Floating mock cards ──────────────────────────────────────
          ...data.cards.map((c) => _FloatingMockCard(card: c, size: size)),

          // ── Main content ─────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 200),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji hero
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                                begin: const Offset(0.92, 0.92),
                                end: const Offset(1.05, 1.05),
                                duration: 2200.ms,
                                curve: Curves.easeInOut),
                        Text(data.emoji,
                                style: const TextStyle(fontSize: 72))
                            .animate()
                            .scale(
                                duration: 600.ms,
                                curve: Curves.elasticOut)
                            .fade(duration: 300.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Title
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fade(delay: 100.ms, duration: 400.ms)
                      .slideX(begin: -0.15, curve: Curves.easeOutCubic),

                  const SizedBox(height: 14),

                  // Subtitle
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  )
                      .animate()
                      .fade(delay: 200.ms, duration: 400.ms)
                      .slideX(begin: -0.15, curve: Curves.easeOutCubic),

                  const SizedBox(height: 30),

                  // Feature bullets
                  ...data.features.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FeatureRow(feature: e.value),
                    )
                        .animate()
                        .fade(
                            delay: Duration(milliseconds: 300 + e.key * 90),
                            duration: 350.ms)
                        .slideX(
                            begin: -0.1, curve: Curves.easeOutCubic);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated blob ─────────────────────────────────────────────────────────────

class _AnimatedBlob extends AnimatedWidget {
  final Color color;
  final double size;
  final Offset startOffset;
  final Offset endOffset;

  const _AnimatedBlob({
    required AnimationController ctrl,
    required this.color,
    required this.size,
    required this.startOffset,
    required this.endOffset,
  }) : super(listenable: ctrl);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as AnimationController).value;
    final s = MediaQuery.sizeOf(context);
    final dx = startOffset.dx + (endOffset.dx - startOffset.dx) * t;
    final dy = startOffset.dy + (endOffset.dy - startOffset.dy) * t;
    return Positioned(
      left: s.width * dx,
      top: s.height * dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

// ── Floating mock notification card ──────────────────────────────────────────

class _FloatingMockCard extends StatelessWidget {
  final _FloatingCard card;
  final Size size;
  const _FloatingMockCard({required this.card, required this.size});

  @override
  Widget build(BuildContext context) {
    final isTop = card.alignment.y < 0;
    final isLeft = card.alignment.x < 0;

    return Positioned(
      top: isTop ? size.height * 0.04 : null,
      left: isLeft ? 12 : null,
      right: isLeft ? null : 12,
      bottom: isTop ? null : size.height * 0.2,
      child: Container(
        constraints: BoxConstraints(maxWidth: size.width * 0.5),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                card.text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: 0,
            end: isTop ? 10 : -10,
            duration: Duration(milliseconds: 2800 + (isLeft ? 400 : 0)),
            curve: Curves.easeInOut,
          ),
    );
  }
}

// ── Feature bullet row ────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(feature.icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            feature.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
