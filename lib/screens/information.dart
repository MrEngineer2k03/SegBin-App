import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FeatureItem {
  final IconData icon;
  final String title;
  final String desc;
  const FeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

class StatItem {
  final IconData icon;
  final String value;
  final String label;
  const StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });
}

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  static const route = '/information';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About SEGBIN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            HowItWorksSection(),
            FeaturesSection(),
            ImpactStatsSection(),
          ],
        ),
      ),
    );
  }
}

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How SEGBIN Works',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Three simple steps to a cleaner, greener campus',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _HowCard(
            number: '1',
            title: 'Campus-Wide Installation',
            description:
                'EcoSort smart bins are strategically placed throughout the campus. Each bin uses AI sensors and computer vision to identify waste instantly.',
            imageUrl: 'lib/assets/images/background6.jpg',
            slideFromLeft: true,
            delayMs: 0,
          ),
          _HowCard(
            number: '2',
            title: 'Students Simply Dispose',
            description:
                'Dispose naturally. The smart system automatically identifies recyclables, compostables, and general waste as items are dropped.',
            imageUrl: 'lib/assets/images/students.jpg',
            slideFromLeft: false,
            delayMs: 100,
          ),
          _HowCard(
            number: '3',
            title: 'Automatic Sorting',
            description:
                'Items are routed to the correct compartment in milliseconds. Track your impact through the dashboard and contribute to a sustainable future.',
            imageUrl: 'lib/assets/images/SegBin.png',
            slideFromLeft: true,
            delayMs: 200,
          ),
        ],
      ),
    );
  }
}

class _HowCard extends StatefulWidget {
  final String number;
  final String title;
  final String description;
  final String? imageUrl;
  final bool slideFromLeft;
  final int delayMs;

  const _HowCard({
    required this.number,
    required this.title,
    required this.description,
    this.imageUrl,
    this.slideFromLeft = true,
    this.delayMs = 0,
  });

  @override
  State<_HowCard> createState() => _HowCardState();
}

class _HowCardState extends State<_HowCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    final beginOffset = widget.slideFromLeft
        ? const Offset(-0.15, 0)
        : const Offset(0.15, 0);
    _slide = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted && _isMostlyVisible) {
        _started = true;
        _controller.forward();
      }
    });
  }

  bool get _isMostlyVisible => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = widget.imageUrl == null
        ? const SizedBox.shrink()
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: widget.imageUrl!.startsWith('http')
                  ? Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF262626),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Image.asset(widget.imageUrl!, fit: BoxFit.cover),
            ),
          );

    return VisibilityDetector(
      key: Key('how_card_${widget.number}'),
      onVisibilityChanged: (info) {
        if (!_started && info.visibleFraction >= 0.4) {
          _started = true;
          Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
            if (mounted) _controller.forward();
          });
        }
      },
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Card(
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF2ECC71),
                      child: Text(
                        widget.number,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                imageWidget,
                if (widget.imageUrl != null) const SizedBox(height: 12),
                Text(widget.description),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeaturesSection extends StatelessWidget {
  const FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final List<FeatureItem> items = const [
      FeatureItem(
        icon: Icons.document_scanner_outlined,
        title: 'AI Recognition',
        desc:
            'Computer vision instantly identifies waste type with high accuracy.',
      ),
      FeatureItem(
        icon: Icons.alt_route,
        title: 'Automatic Sorting',
        desc: 'Items are routed to recyclable, compostable, or general waste.',
      ),
      FeatureItem(
        icon: Icons.bar_chart,
        title: 'Real-Time Analytics',
        desc: 'Track recycling rates, waste reduction metrics, and impact.',
      ),
      FeatureItem(
        icon: Icons.notifications,
        title: 'Smart Notifications',
        desc: 'Get alerts as bins approach capacity.',
      ),
      FeatureItem(
        icon: Icons.people_outline,
        title: 'Community Impact',
        desc: 'See how your contributions compare and celebrate milestones.',
      ),
      FeatureItem(
        icon: Icons.verified_user,
        title: 'Privacy First',
        desc: 'Anonymous usage data only; no personal tracking.',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Features',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Advanced technology meets environmental responsibility',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1000
                  ? 3
                  : constraints.maxWidth >= 640
                  ? 2
                  : 1;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.0,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0x332ECC71), Color(0x0D2ECC71)],
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              color: const Color(0xFF2ECC71),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.desc,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class ImpactStatsSection extends StatelessWidget {
  const ImpactStatsSection();

  @override
  Widget build(BuildContext context) {
    final List<StatItem> stats = const [
      StatItem(
        icon: Icons.inventory_2_outlined,
        value: '250K+',
        label: 'Items Sorted This Year',
      ),
      StatItem(
        icon: Icons.trending_up,
        value: '72%',
        label: 'Average Recycling Rate',
      ),
      StatItem(
        icon: Icons.eco_outlined,
        value: '45 Tons',
        label: 'CO2 Emissions Prevented',
      ),
      StatItem(
        icon: Icons.groups_2_outlined,
        value: '3,200+',
        label: 'Active Campus Users',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environmental Impact',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Together, we\'re making a real difference for our planet',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1024
                  ? 4
                  : constraints.maxWidth >= 640
                  ? 2
                  : 1;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.3,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.length,
                itemBuilder: (_, i) {
                  final item = stats[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0x332ECC71),
                                      Color(0x0D2ECC71),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: const Color(0xFF2ECC71),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.value,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            item.label,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
