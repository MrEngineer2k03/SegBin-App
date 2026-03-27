import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/bin.dart';

class BinCard extends StatelessWidget {
  final Bin bin;
  final bool isStaff;
  final bool isHighlighted;
  final VoidCallback? onClearTrash; // Optional - staff can't clear trash
  final VoidCallback? onChargeBattery; // Optional - only staff can charge
  final VoidCallback? onAddPoints; // Optional - staff can't add points
  final VoidCallback? onHighlightDismissed;
  final VoidCallback? onClick;

  const BinCard({
    super.key,
    required this.bin,
    required this.isStaff,
    this.isHighlighted = false,
    this.onClearTrash,
    this.onChargeBattery,
    this.onAddPoints,
    this.onHighlightDismissed,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final binType = AppConstants.binTypes.firstWhere(
      (type) => type['type'] == bin.type,
      orElse: () => {'type': bin.type, 'color': AppConstants.brandColor},
    );

    final binColor = binType['color'] as Color;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Only make clickable if onClick is provided (staff only)
    Widget cardContent = SizedBox(
        width: 220, // Set your desired width
        height: 160, // Set your desired height
        child: Card(
          elevation: isHighlighted ? 8 : 2,
          shadowColor: isHighlighted ? AppConstants.brandColor.withOpacity(0.3) : null,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E293B), // slate-800
                  Color(0xFF0F172A), // slate-900
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHighlighted
                    ? AppConstants.brand2Color.withOpacity(0.6)
                    : AppConstants.brand2Color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Container(
                decoration: isStaff
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: const Border(
                          left: BorderSide(
                            color: AppConstants.brand2Color,
                            width: 4,
                          ),
                        ),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bin.locationOrId,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (bin.hasAlert) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.warning,
                                        size: 14,
                                        color: AppConstants.dangerColor,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Alert',
                                        style: TextStyle(
                                          color: AppConstants.dangerColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF475569).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              bin.type,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: bin.fillLevel / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getFillColor(bin.fillLevel),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${bin.fillLevel}% full',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                'Last Collected: ${bin.relativeTime}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Battery Section
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildBatteryIcon(bin.batteryLevel),
                            const SizedBox(width: 8),
                            Text(
                              '${bin.batteryLevel}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              bin.batteryStatusText,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Charge Button (only for staff)
                      if (isStaff && onChargeBattery != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppConstants.brand2Color, AppConstants.brandColor],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onChargeBattery,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.battery_charging_full,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Charge',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ),
            ),
          ),
        ),
      );
    
    // Wrap with GestureDetector only if onClick is provided (staff only)
    if (onClick != null) {
      return GestureDetector(
        onTap: () {
          onClick!();
        },
        child: cardContent,
      );
    } else if (isHighlighted && onHighlightDismissed != null) {
      return GestureDetector(
        onTap: () {
          onHighlightDismissed!();
        },
        child: cardContent,
      );
    }
    
    return cardContent;
  }

  Widget _buildBatteryIcon(int battery) {
    Color batteryColor = _getBatteryColor(battery);
    
    return Container(
      width: 22,
      height: 11,
      decoration: BoxDecoration(
        border: Border.all(color: AppConstants.mutedColor, width: 2),
        borderRadius: BorderRadius.circular(2),
        color: AppConstants.panelColor,
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: battery / 100,
            child: Container(
              decoration: BoxDecoration(
                color: batteryColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Positioned(
            right: -4,
            top: 2.5,
            child: Container(
              width: 2,
              height: 6,
              decoration: BoxDecoration(
                color: AppConstants.mutedColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(1),
                  bottomRight: Radius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor(int battery) {
    if (battery >= 70) return AppConstants.okColor;
    if (battery >= 40) return AppConstants.warnColor;
    return AppConstants.dangerColor;
  }

  Color _getFillColor(int level) {
    if (level >= 80) return AppConstants.dangerColor;
    if (level >= 60) return AppConstants.warnColor;
    if (level >= 40) return AppConstants.brand2Color;
    return const Color(0xFF60A5FA); // blue-400
  }

  Widget _buildStaffButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppConstants.brand2Color, AppConstants.brandColor],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppConstants.bgColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppConstants.bgColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard-style bin card: building, type, status pill, circular + bar progress, trend, battery, temp, DETAILS.
class BinDashboardCard extends StatefulWidget {
  final Bin bin;
  final bool isHighlighted;
  final VoidCallback? onDetailsPressed;

  static const _accent = Color(0xFF00E6FF); // bright teal
  static const _fullStart = Color(0xFFEF4444); // Red - Bin is full!
  static const _fullEnd = Color(0xFFDC2626);
  static const _criticalStart = Color(0xFFFF6B00); // Orange - Critical (90%)
  static const _criticalEnd = Color(0xFFFF8C00);
  static const _cautionStart = Color(0xFFFFD600); // Yellow - Caution (80%)
  static const _cautionEnd = Color(0xFFFFC107);
  static const _optimalStart = Color(0xFF00BFFF); // Cyan - Optimal (0-79%)
  static const _optimalEnd = Color(0xFF00E6FF);
  static const _muted = Color(0xFFB0B0B0);
  static const _cardBg = Color(0xFF262D3D);
  static const _panelBg = Color(0xFF1E293B);
  static const _trackBg = Color(0xFF505050);

  const BinDashboardCard({
    super.key,
    required this.bin,
    this.isHighlighted = false,
    this.onDetailsPressed,
  });

  @override
  State<BinDashboardCard> createState() => _BinDashboardCardState();
}

class _BinDashboardCardState extends State<BinDashboardCard> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  bool get _needsRedGlow =>
      widget.bin.fillLevel >= 100 || widget.bin.batteryLevel <= 15;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (_needsRedGlow) _glowController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant BinDashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_needsRedGlow) {
      if (!_glowController.isAnimating) _glowController.repeat(reverse: true);
    } else {
      if (_glowController.isAnimating) _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }


  /// Status pills based on fill level thresholds:
  /// 0-79% = Optimal, 80-89% = Caution, 90-99% = Critical, 100% = Bin is full!
  List<({String label, Color color})> get _statusPills {
    final isLowBattery = widget.bin.batteryLevel <= 15;
    final isFull = widget.bin.fillLevel >= 100;
    final isCritical = widget.bin.fillLevel >= 90 && widget.bin.fillLevel < 100;
    final isCaution = widget.bin.fillLevel >= 80 && widget.bin.fillLevel < 90;

    List<({String label, Color color})> pills = [];

    // Add low battery pill if applicable
    if (isLowBattery) {
      pills.add((label: 'LOW BATTERY', color: BinDashboardCard._fullStart));
    }

    // Add fill status pill
    if (isFull) {
      pills.add((label: 'BIN IS FULL!', color: BinDashboardCard._fullStart));
    } else if (isCritical) {
      pills.add((label: 'CRITICAL', color: BinDashboardCard._criticalStart));
    } else if (isCaution) {
      pills.add((label: 'CAUTION', color: BinDashboardCard._cautionEnd));
    } else {
      pills.add((label: 'OPTIMAL', color: BinDashboardCard._optimalEnd));
    }

    return pills;
  }

  /// Status pill color for single-pill case; first pill when multiple.
  Color get _statusColor => _statusPills.first.color;

  /// Fill-based gradient for progress bar and volume circle.
  /// 100% = Red, 90-99% = Orange, 80-89% = Yellow, 0-79% = Cyan
  List<Color> get _fillGradientColors {
    if (widget.bin.fillLevel >= 100) return [BinDashboardCard._fullStart, BinDashboardCard._fullEnd];
    if (widget.bin.fillLevel >= 90) return [BinDashboardCard._criticalStart, BinDashboardCard._criticalEnd];
    if (widget.bin.fillLevel >= 80) return [BinDashboardCard._cautionStart, BinDashboardCard._cautionEnd];
    return [BinDashboardCard._optimalEnd, BinDashboardCard._optimalStart];
  }

  /// Fill-based accent color for percentage text and trend.
  Color get _fillColor {
    if (widget.bin.fillLevel >= 100) return BinDashboardCard._fullStart;
    if (widget.bin.fillLevel >= 90) return BinDashboardCard._criticalStart;
    if (widget.bin.fillLevel >= 80) return BinDashboardCard._cautionEnd;
    return BinDashboardCard._optimalEnd;
  }

  Color get _detailsColor => BinDashboardCard._accent;

  /// Placeholder trend; in production could come from telemetry.
  String get _trendText {
    if (widget.bin.fillLevel >= 100) return 'FULL';
    if (widget.bin.fillLevel >= 90) return '+15%/h';
    if (widget.bin.fillLevel >= 80) return '+8%/h';
    return '+2%/h';
  }

  bool get _trendUp => widget.bin.fillLevel >= 80;

  /// Placeholder temperature per bin type.
  String get _temperature {
    const temps = {
      'Plastic Bin': '24°C',
      'Paper Bin': '21°C',
      'Organic Bin': '19°C',
      'Single-Stream Bin': '20°C',
      'Mixed Bin': '19°C',
    };
    return temps[widget.bin.type] ?? '22°C';
  }

  @override
  Widget build(BuildContext context) {
    final fillGradientColors = _fillGradientColors;
    final fillColor = _fillColor;
    final showRedGlow = _needsRedGlow;

    final cardChild = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.bin.location ?? widget.bin.id).replaceAll(RegExp(r'\s+Bin$'), '').toUpperCase(),
                      style: const TextStyle(color: BinDashboardCard._muted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.bin.type,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _statusPills.asMap().entries.map((entry) {
                      final p = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(left: entry.key > 0 ? 6 : 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: p.color.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            p.label,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 12, color: BinDashboardCard._muted),
                      const SizedBox(width: 4),
                      Text(widget.bin.relativeTime, style: const TextStyle(color: BinDashboardCard._muted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(72, 72),
                      painter: _CircleProgressPainter(
                        progress: widget.bin.fillLevel / 100,
                        gradientColors: fillGradientColors,
                        backgroundColor: BinDashboardCard._trackBg,
                      ),
                    ),
                    Text(
                      '${widget.bin.fillLevel}%',
                      style: TextStyle(color: fillColor, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT VOLUME',
                      style: TextStyle(color: BinDashboardCard._muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    _buildGradientProgressBar(fillGradientColors),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _trendUp ? Icons.arrow_upward : Icons.trending_down,
                          size: 14,
                          color: fillColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _trendText,
                          style: TextStyle(color: fillColor, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildBatteryChip(widget.bin.batteryLevel),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(Icons.thermostat, size: 16, color: BinDashboardCard._muted),
                      const SizedBox(width: 4),
                      Text(_temperature, style: const TextStyle(color: BinDashboardCard._muted, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onDetailsPressed != null) ...[
                    GestureDetector(
                      onTap: widget.onDetailsPressed,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('DETAILS', style: TextStyle(color: BinDashboardCard._accent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 10, color: BinDashboardCard._accent),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  _buildStatusIndicator(),
                ],
              ),
            ],
          ),
        ],
    );

    // When red status, wrap in breathing glow animation
    if (showRedGlow) {
      return AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, _) {
          final t = _glowAnimation.value;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: BinDashboardCard._cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: BinDashboardCard._fullStart.withOpacity(0.5 + 0.5 * t),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: BinDashboardCard._fullStart.withOpacity(0.15 + 0.35 * t),
                  blurRadius: 14 + 18 * t,
                  spreadRadius: 0.5 * t,
                ),
              ],
            ),
            child: cardChild,
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BinDashboardCard._cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isHighlighted
              ? BinDashboardCard._accent.withOpacity(0.6)
              : const Color(0xFF334155),
          width: widget.isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          if (widget.isHighlighted)
            BoxShadow(
              color: BinDashboardCard._accent.withOpacity(0.15),
              blurRadius: 16,
              spreadRadius: 0,
            ),
        ],
      ),
      child: cardChild,
    );
  }

  Widget _buildGradientProgressBar(List<Color> gradientColors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final filledWidth = constraints.maxWidth * (widget.bin.fillLevel / 100).clamp(0.0, 1.0);
          return SizedBox(
            height: 8,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: BinDashboardCard._trackBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                if (filledWidth > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: filledWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBatteryChip(int battery) {
    Color c = BinDashboardCard._optimalEnd; // cyan/teal for good battery
    if (battery <= 15) c = BinDashboardCard._fullStart; // Red for critical low battery
    else if (battery <= 30) c = BinDashboardCard._cautionEnd; // Yellow for low battery warning
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.battery_std, size: 18, color: c),
        const SizedBox(width: 4),
        Text('$battery%', style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    final isOnline = widget.bin.batteryLevel > 0;
    final statusColor = isOnline ? const Color(0xFF22C55E) : const Color(0xFF6B7280);
    final statusText = isOnline ? 'Active' : 'Offline';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: isOnline
                  ? [
                      BoxShadow(
                        color: statusColor.withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;
  final Color backgroundColor;

  _CircleProgressPainter({
    required this.progress,
    required this.gradientColors,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 6.0;
    final r = size.width / 2 - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: r);

    // Background arc (translucent grey)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, bgPaint);

    // Filled arc with gradient
    if (progress > 0) {
      final sweep = 2 * 3.1415926535 * progress;
      final gradient = SweepGradient(
        startAngle: -3.1415926535 / 2,
        endAngle: -3.1415926535 / 2 + sweep,
        colors: gradientColors,
      );
      final fillPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -3.1415926535 / 2, sweep, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter old) =>
      old.progress != progress || old.gradientColors != gradientColors;
}
