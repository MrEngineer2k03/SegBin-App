import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/feedback_service.dart';
import '../../services/firestore_trash_service.dart';
import '../../services/news_service.dart';

class DashboardAdmin extends StatefulWidget {
  /// When true, shows staff-oriented dashboard (no Total Staff card, different header).
  final bool isStaff;

  const DashboardAdmin({super.key, this.isStaff = false});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  final FeedbackService _feedbackService = FeedbackService();
  final NewsService _newsService = NewsService();
  int _feedbackCount = 0;
  int _newsCount = 0;
  int _staffCount = 0;
  int _totalTrash = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    final feedback = await _feedbackService.getAllFeedback();
    final news = await _newsService.fetchArticles();
    if (!widget.isStaff) {
      final staffCount = await AuthService.getStaffCount();
      setState(() => _staffCount = staffCount);
    }
    final trashData = await FirestoreTrashService.getTrashData();
    final totalTrash =
        (trashData['Plastic'] ?? 0) +
        (trashData['Paper'] ?? 0) +
        (trashData['Single-stream'] ?? 0) +
        (trashData['Mixed'] ?? 0);

    setState(() {
      _feedbackCount = feedback.length;
      _newsCount = news.length;
      _totalTrash = totalTrash;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = AuthService.currentUser?.username ?? (widget.isStaff ? 'Staff' : 'Admin');
    final firstName = username.split(RegExp(r'[\s._-]+')).first;

    return Container(
      color: _DashboardColors.background,
      child: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _DashboardColors.accent,
                ),
              )
            : RefreshIndicator(
                color: _DashboardColors.accent,
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(firstName),
                      const SizedBox(height: 22),
                      _buildSearchBar(),
                      const SizedBox(height: 26),
                      _buildOverviewHeader(),
                      const SizedBox(height: 14),
                      _buildOverviewCards(),
                      const SizedBox(height: 18),
                      _buildGrowthCard(),
                      const SizedBox(height: 22),
                      _buildRecentActivityHeader(),
                      const SizedBox(height: 14),
                      _buildRecentActivities(),
                      const SizedBox(height: 16),
                      _buildViewAllTransactionsButton(),
                      const SizedBox(height: 22),
                      _buildLatestFeedbackCard(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(String firstName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, $firstName',
                style: const TextStyle(
                  color: _DashboardColors.muted,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isStaff ? 'DASHBOARD' : 'DASHBOARD',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildCircleIcon(Icons.notifications_none, outlined: false),
        const SizedBox(width: 10),
        _buildCircleIcon(Icons.assignment_outlined, outlined: true),
      ],
    );
  }

  Widget _buildCircleIcon(IconData icon, {required bool outlined}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _DashboardColors.card,
        shape: BoxShape.circle,
        border: outlined
            ? Border.all(color: _DashboardColors.accent, width: 2)
            : null,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _DashboardColors.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: _DashboardColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.isStaff ? 'Search analytics, bins...' : 'Search analytics, users...',
              style: const TextStyle(color: _DashboardColors.subtle, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewHeader() {
    return Row(
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: _DashboardColors.accent,
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            'View All',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            if (!widget.isStaff)
              Expanded(
                child: _buildOverviewCard(
                  icon: Icons.group,
                  iconColor: _DashboardColors.accent,
                  iconBackground: const Color(0xFF1F385F),
                  changeText: '~12%',
                  changeColor: const Color(0xFF22E7AA),
                  label: 'TOTAL STAFF',
                  value: _staffCount.toString(),
                  bars: const [
                    Color(0xFF16306D),
                    Color(0xFF22408E),
                    Color(0xFF22B5FF),
                    Color(0xFF1A3276),
                    Color(0xFF132A57),
                  ],
                ),
              ),
            if (!widget.isStaff) const SizedBox(width: 14),
            if (widget.isStaff)
              Expanded(
                child: _buildOverviewCard(
                  icon: Icons.feedback,
                  iconColor: const Color(0xFF22E7AA),
                  iconBackground: const Color(0xFF0D6F67),
                  changeText: '${_feedbackCount > 0 ? '' : '0'}',
                  changeColor: const Color(0xFF22E7AA),
                  label: 'FEEDBACK',
                  value: _feedbackCount.toString(),
                  bars: const [
                    Color(0xFF0D6F67),
                    Color(0xFF0A5A52),
                    Color(0xFF63F3CB),
                    Color(0xFF0D6F67),
                    Color(0xFF0A5A52),
                  ],
                ),
              ),
            if (widget.isStaff) const SizedBox(width: 14),
            Expanded(
              child: StreamBuilder<Map<String, int>>(
                stream: FirestoreTrashService.listenToTrashData(),
                builder: (context, snapshot) {
                  final trashData = snapshot.data;
                  final liveTotalTrash = trashData == null
                      ? _totalTrash
                      : (trashData['Plastic'] ?? 0) +
                            (trashData['Paper'] ?? 0) +
                            (trashData['Single-stream'] ?? 0) +
                            (trashData['Mixed'] ?? 0);

                  return _buildOverviewCard(
                    icon: Icons.delete_outline,
                    iconColor: const Color(0xFFC887FF),
                    iconBackground: const Color(0xFF3A2A5E),
                    changeText: '~0.4%',
                    changeColor: const Color(0xFF22E7AA),
                    label: 'TOTAL TRASH',
                    value: liveTotalTrash.toString(),
                    bars: const [
                      Color(0xFF312060),
                      Color(0xFF402872),
                      Color(0xFF563186),
                      Color(0xFFA360FF),
                      Color(0xFF593378),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        StreamBuilder<Map<String, int>>(
          stream: FirestoreTrashService.listenToTrashData(),
          builder: (context, snapshot) {
            final trashData =
                snapshot.data ??
                const {
                  'Plastic': 0,
                  'Paper': 0,
                  'Single-stream': 0,
                  'Mixed': 0,
                };
            return _buildTrashBreakdownCard(trashData);
          },
        ),
      ],
    );
  }

  Widget _buildTrashBreakdownCard(Map<String, int> trashData) {
    final plastic = trashData['Plastic'] ?? 0;
    final paper = trashData['Paper'] ?? 0;
    final singleUse = trashData['Single-stream'] ?? 0;
    final mixed = trashData['Mixed'] ?? 0;
    final total = plastic + paper + singleUse + mixed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DashboardColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DashboardColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trash Roles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: CustomPaint(
                  painter: _TrashBreakdownPainter(
                    values: [
                      plastic.toDouble(),
                      paper.toDouble(),
                      singleUse.toDouble(),
                      mixed.toDouble(),
                    ],
                    colors: const [
                      Color(0xFF22B5FF),
                      Color(0xFF8F5CFF),
                      Color(0xFF41E5A7),
                      Color(0xFFFF9E5A),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBreakdownRow(
                      'Plastic',
                      plastic,
                      const Color(0xFF22B5FF),
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow('Paper', paper, const Color(0xFF8F5CFF)),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      'Single Use',
                      singleUse,
                      const Color(0xFF41E5A7),
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow('Mixed', mixed, const Color(0xFFFF9E5A)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _DashboardColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String changeText,
    required Color changeColor,
    required String label,
    required String value,
    required List<Color> bars,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DashboardColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DashboardColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const Spacer(),
              Text(
                changeText,
                style: TextStyle(
                  color: changeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: _DashboardColors.muted,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.asMap().entries.map((entry) {
              final heights = [14.0, 22.0, 30.0, 18.0, 10.0];
              return Expanded(
                child: Container(
                  height: heights[entry.key],
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: entry.value,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthCard() {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final midDay = (daysInMonth / 2).round();
    final startLabel = _formatMonthDay(now.month, 1);
    final midLabel = _formatMonthDay(now.month, midDay);
    final endLabel = _formatMonthDay(now.month, daysInMonth);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: _DashboardColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _DashboardColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trash Growth',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Collection over time',
                      style: TextStyle(
                        color: _DashboardColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: _DashboardColors.panel,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    _TimePill(text: '30D', selected: true),
                    _TimePill(text: '90D', selected: false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: StreamBuilder<Map<String, int>>(
              stream: FirestoreTrashService.listenToTrashData(),
              builder: (context, snapshot) {
                final trashData =
                    snapshot.data ??
                    const {
                      'Plastic': 0,
                      'Paper': 0,
                      'Single-stream': 0,
                      'Mixed': 0,
                    };
                final chartValues = _buildTrashTrendValues(trashData);

                return CustomPaint(
                  painter: _GrowthChartPainter(values: chartValues),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(
                  startLabel,
                  style: const TextStyle(color: _DashboardColors.muted),
                ),
                const Spacer(),
                Text(
                  midLabel,
                  style: const TextStyle(color: _DashboardColors.muted),
                ),
                const Spacer(),
                Text(
                  endLabel,
                  style: const TextStyle(color: _DashboardColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonthDay(int month, int day) {
    const monthNames = <String>[
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final monthName = monthNames[month - 1];
    final dayText = day.toString().padLeft(2, '0');
    return '$monthName $dayText';
  }

  List<double> _buildTrashTrendValues(Map<String, int> trashData) {
    final plastic = (trashData['Plastic'] ?? 0).toDouble();
    final paper = (trashData['Paper'] ?? 0).toDouble();
    final singleStream = (trashData['Single-stream'] ?? 0).toDouble();
    final mixed = (trashData['Mixed'] ?? 0).toDouble();

    final cumulative = <double>[
      0,
      plastic,
      plastic + paper,
      plastic + paper + singleStream,
      plastic + paper + singleStream + mixed,
    ];

    final maxValue = cumulative.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) {
      return const [0.18, 0.24, 0.2, 0.32, 0.42];
    }

    return cumulative
        .map((v) => (v / maxValue).clamp(0.0, 1.0).toDouble())
        .toList();
  }

  Widget _buildRecentActivityHeader() {
    return Row(
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: _DashboardColors.card,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.more_horiz, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    final activities = <_ActivityItem>[
      const _ActivityItem(
        title: 'Sarah Jenkins',
        subtitle: 'joined as Viewer',
        time: '2 minutes ago',
        icon: Icons.person,
        iconBackground: Color(0xFF0D6F67),
        iconColor: Color(0xFF63F3CB),
      ),
      const _ActivityItem(
        title: 'System',
        subtitle: 'deployed v2.4.0',
        time: '1 hour ago',
        icon: Icons.rocket_launch,
        iconBackground: Color(0xFF3E2B70),
        iconColor: Color(0xFFC48BFF),
      ),
      const _ActivityItem(
        title: 'Security Alert:',
        subtitle: 'Failed logins',
        time: '3 hours ago',
        icon: Icons.warning_amber_rounded,
        iconBackground: Color(0xFF5D2742),
        iconColor: Color(0xFFFF8EA8),
      ),
    ];

    return Column(
      children: activities
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActivityTile(item),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActivityTile(_ActivityItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DashboardColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DashboardColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16),
                    children: [
                      TextSpan(
                        text: item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' ${item.subtitle}',
                        style: const TextStyle(
                          color: _DashboardColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.time,
                  style: const TextStyle(
                    color: _DashboardColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllTransactionsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF051A47),
          foregroundColor: _DashboardColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          'View All Transactions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildLatestFeedbackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF33A8F8), Color(0xFF8C5FF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.format_quote, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Latest Feedback',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '"The analytics updates are very fast and easy to understand."',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marcus Wu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Product Manager',
                    style: TextStyle(color: Color(0xFFE1E8FF), fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$_feedbackCount feedback',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardColors {
  static const Color background = Color(0xFF020B2C);
  static const Color panel = Color(0xFF22304E);
  static const Color card = Color(0xFF101E3F);
  static const Color border = Color(0xFF25365D);
  static const Color accent = Color(0xFF14C8FF);
  static const Color muted = Color(0xFF8C9BC4);
  static const Color subtle = Color(0xFF697BA6);
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });
}

class _TimePill extends StatelessWidget {
  final String text;
  final bool selected;

  const _TimePill({required this.text, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF3A4B6B) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : _DashboardColors.muted,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _GrowthChartPainter extends CustomPainter {
  final List<double> values;

  _GrowthChartPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final normalized = values.isEmpty
        ? const [0.18, 0.24, 0.2, 0.32, 0.42]
        : values;
    final count = normalized.length;
    final points = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = count == 1 ? 0.0 : (i / (count - 1)) * size.width;
      final y = size.height - (normalized[i] * 0.72 + 0.14) * size.height;
      points.add(Offset(x, y));
    }

    final curvePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlX = (p1.dx + p2.dx) / 2;
      curvePath.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
    }

    final fillPath = Path.from(curvePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x5031D4FF), Color(0x1028A9D2)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = _DashboardColors.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(curvePath, linePaint);

    final pointPaint = Paint()..color = _DashboardColors.accent;
    final pointBorderPaint = Paint()..color = _DashboardColors.background;
    for (int i = 2; i < points.length - 1; i += 2) {
      canvas.drawCircle(points[i], 4, pointPaint);
      canvas.drawCircle(points[i], 2, pointBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

class _TrashBreakdownPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _TrashBreakdownPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, v) => sum + v);
    final strokeWidth = size.width * 0.16;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF22385F);
    canvas.drawArc(rect, 0, 2 * 3.1415926535, false, basePaint);

    if (total <= 0) {
      return;
    }

    var start = -3.1415926535 / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * (2 * 3.1415926535);
      if (sweep <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = colors[i];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _TrashBreakdownPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}
