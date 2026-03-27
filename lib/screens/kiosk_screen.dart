import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/kiosk_data_service.dart';

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

enum ScreenId {
  home,
  insertTrash,
  howToUse,
  taskSelection,
  activeQuest,
  printing,
  thankYou,
}

class Quest {
  Quest({
    required this.id,
    required this.type,
    required this.target,
    required this.title,
    required this.desc,
    required this.reward,
  });

  final String id;
  final String type;
  final int target;
  final String title;
  final String desc;
  final String reward;
}

class _KioskScreenState extends State<KioskScreen>
    with SingleTickerProviderStateMixin {
  ScreenId _screen = ScreenId.home;
  bool _showMenu = false;
  bool _showCompletion = false;

  int _bgIndex = 0;
  Timer? _bgTimer;

  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  Quest? _selectedQuest;
  Quest? _activeQuest;
  int _progress = 0;
  int _wrongItemsCount = 0;
  int _timeLeft = 20;
  Timer? _questTimer;
  bool _showWrongTrashMessage = false;

  List<LinearGradient> get _backgrounds => [
    LinearGradient(colors: [AppConstants.brandColor, AppConstants.brand2Color]),
    LinearGradient(colors: [AppConstants.brand2Color, AppConstants.brandColor]),
    LinearGradient(colors: [AppConstants.brandColor.withOpacity(0.8), AppConstants.brand2Color.withOpacity(0.8)]),
    LinearGradient(colors: [AppConstants.brand2Color.withOpacity(0.8), AppConstants.brandColor.withOpacity(0.8)]),
    LinearGradient(colors: [AppConstants.brandColor, AppConstants.brand2Color]),
  ];

  final List<Quest> _quests = [
    Quest(
      id: 'plastic-2',
      type: 'plastic',
      target: 2,
      title: 'Plastic Bottles',
      desc: 'Insert 2 plastic bottles',
      reward: '2% Discount Coupon',
    ),
    Quest(
      id: 'plastic-4',
      type: 'plastic',
      target: 4,
      title: 'Plastic Bottles',
      desc: 'Insert 4 plastic bottles',
      reward: '5% Discount Coupon',
    ),
    Quest(
      id: 'paper-10',
      type: 'paper',
      target: 10,
      title: 'Paper Trash',
      desc: 'Insert 10 paper items',
      reward: '5% Discount Coupon',
    ),
    Quest(
      id: 'mixed-20',
      type: 'mixed',
      target: 20,
      title: 'Mixed Trash',
      desc: 'Insert 20 mixed items',
      reward: '7% Discount Coupon',
    ),
    Quest(
      id: 'single-stream-15',
      type: 'single-stream',
      target: 15,
      title: 'Single Stream',
      desc: 'Insert 15 single stream items',
      reward: '6% Discount Coupon',
    ),
    Quest(
      id: 'plastic-6',
      type: 'plastic',
      target: 6,
      title: 'Plastic Bottles',
      desc: 'Insert 6 plastic bottles',
      reward: '8% Discount Coupon',
    ),
    Quest(
      id: 'paper-5',
      type: 'paper',
      target: 5,
      title: 'Paper Trash',
      desc: 'Insert 5 paper items',
      reward: '3% Discount Coupon',
    ),
    Quest(
      id: 'mixed-10',
      type: 'mixed',
      target: 10,
      title: 'Mixed Trash',
      desc: 'Insert 10 mixed items',
      reward: '4% Discount Coupon',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _bgTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() => _bgIndex = (_bgIndex + 1) % _backgrounds.length);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _bgTimer?.cancel();
    _questTimer?.cancel();
    super.dispose();
  }

  void _goHome() {
    _stopQuest();
    setState(() {
      _screen = ScreenId.home;
      _showMenu = false;
      _selectedQuest = null;
      _showWrongTrashMessage = false;
    });
  }

  void _hideWrongTrashMessage() {
    setState(() {
      _showWrongTrashMessage = false;
    });
    _stopQuest();
    _goHome();
  }

  void _showTaskSelection(Quest quest) {
    setState(() {
      _selectedQuest = quest;
      _screen = ScreenId.taskSelection;
    });
  }

  void _startQuest() {
    final quest = _selectedQuest;
    if (quest == null) return;

    setState(() {
      _activeQuest = quest;
      _progress = 0;
      _wrongItemsCount = 0;
      _timeLeft = 20;
      _screen = ScreenId.activeQuest;
    });

    _questTimer?.cancel();
    _questTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft <= 1) {
        _questTimer?.cancel();
        _questTimeout();
        return;
      }
      setState(() => _timeLeft--);
    });
  }

  void _stopQuest() {
    _questTimer?.cancel();
    _activeQuest = null;
    _progress = 0;
    _wrongItemsCount = 0;
  }

  void _questTimeout() {
    if (_wrongItemsCount > 0) {
      setState(() {
        _showWrongTrashMessage = true;
      });
    } else {
      _stopQuest();
      _goHome();
    }
  }

  void _addItem(String type) async {
    if (_activeQuest == null) return;
    final now = DateTime.now();
    
    if (type != _activeQuest!.type) {
      setState(() {
        _progress++;
        _wrongItemsCount++;
      });
      _showSnack('Wrong item type!', error: true);
      
      // Save wrong item to kiosk data (still counts for dashboard)
      await KioskDataService.addKioskRecord(
        type: type,
        items: 1,
        timestamp: now,
      );
    } else {
      setState(() => _progress++);
      _showSnack('Correct item added!');
      
      // Save correct item to kiosk data
      await KioskDataService.addKioskRecord(
        type: type,
        items: 1,
        timestamp: now,
      );
      
      if (_progress >= _activeQuest!.target) {
        _questTimer?.cancel();
        _showCompletionPopup();
      }
    }
  }

  void _showCompletionPopup() {
    setState(() => _showCompletion = true);
  }

  void _hideCompletionPopup() {
    setState(() => _showCompletion = false);
  }

  void _printVoucher() {
    _hideCompletionPopup();
    setState(() => _screen = ScreenId.printing);

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _screen = ScreenId.thankYou);
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        _goHome();
      });
    });
  }

  void _showSnack(String message, {bool error = false}) {
    final color = error ? AppConstants.dangerColor : AppConstants.okColor;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: color,
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Vipnagorgialla',
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${days[dt.weekday % 7]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
  }

  bool _isCompact(BuildContext context) {
    return MediaQuery.of(context).size.width < 700;
  }

  double _scale(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return (shortestSide / 800).clamp(0.7, 1.0);
  }

  double _contentWidth(BuildContext context, double maxWidth) {
    final width = MediaQuery.of(context).size.width;
    return math.min(maxWidth, math.max(0, width - 32));
  }

  Widget _buildBody() {
    switch (_screen) {
      case ScreenId.home:
        return _buildHome();
      case ScreenId.insertTrash:
        return _buildInsertTrash();
      case ScreenId.howToUse:
        return _buildHowToUse();
      case ScreenId.taskSelection:
        return _buildTaskSelection();
      case ScreenId.activeQuest:
        return _buildActiveQuest();
      case ScreenId.printing:
        return _buildPrinting();
      case ScreenId.thankYou:
        return _buildThankYou();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBody(),
          _buildMenuModal(),
          _buildCompletionPopup(),
          _buildWrongTrashMessage(),
        ],
      ),
    );
  }

  Widget _buildHome() {
    final scale = _scale(context);
    final titleSize = 72 * scale;
    final dateSize = 26 * scale;
    final timeSize = 48 * scale;
    final tapSize = 28 * scale;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(seconds: 1),
          decoration: BoxDecoration(
            gradient: _backgrounds[_bgIndex],
          ),
        ),
        Center(
          child: InkWell(
            onTap: () => setState(() => _showMenu = true),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SegBin',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 4,
                    fontFamily: 'Vipnagorgialla',
                    shadows: const [
                      Shadow(
                          color: Colors.black38,
                          blurRadius: 20,
                          offset: Offset(2, 2)),
                    ],
                  ),
                ),
                SizedBox(height: 24 * scale),
                Text(
                  _formatDate(_now),
                  style: TextStyle(
                    fontSize: dateSize,
                    color: Colors.white,
                    fontFamily: 'Vipnagorgialla',
                  ),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  _formatTime(_now),
                  style: TextStyle(
                      fontSize: timeSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Vipnagorgialla'),
                ),
                SizedBox(height: 32 * scale),
                _PulseText('Tap to continue', fontSize: tapSize),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, VoidCallback onBack) {
    final isCompact = _isCompact(context);
    final titleSize = isCompact ? 22.0 : 28.0;
    final height = isCompact ? 70.0 : 90.0;
    final buttonPadding = isCompact
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 16);

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.mutedColor,
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Back',
                style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    color: Colors.white,
                    fontFamily: 'Vipnagorgialla')),
          ),
          const Spacer(),
          Text(title,
              style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Vipnagorgialla')),
          const Spacer(),
          SizedBox(width: isCompact ? 60 : 120),
        ],
      ),
    );
  }

  Widget _buildInsertTrash() {
    final isCompact = _isCompact(context);
    final gridPadding = isCompact ? 16.0 : 24.0;
    final gridCount = isCompact ? 1 : 2;
    final aspectRatio = isCompact ? 2.2 : 1.4;
    final titleSize = isCompact ? 22.0 : 28.0;
    final questTitleSize = isCompact ? 18.0 : 20.0;
    final questDescSize = isCompact ? 14.0 : 16.0;
    final rewardSize = isCompact ? 14.0 : 16.0;

    return Column(
      children: [
        _buildHeader('Insert Trash', _goHome),
        Expanded(
          child: Container(
            color: AppConstants.cardColor,
            padding: EdgeInsets.all(gridPadding),
            child: Column(
              children: [
                Text(
                  'Choose a Quest',
                  style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Vipnagorgialla',
                      color: AppConstants.textColor),
                ),
                SizedBox(height: isCompact ? 16 : 24),
                Expanded(
                  child: GridView.builder(
                    itemCount: _quests.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      final quest = _quests[index];
                      final selected = _selectedQuest?.id == quest.id;
                      return GestureDetector(
                        onTap: () => _showTaskSelection(quest),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppConstants.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppConstants.brandColor
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 12)
                            ],
                          ),
                          padding: EdgeInsets.all(isCompact ? 12 : 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_iconForType(quest.type),
                                  style: const TextStyle(fontSize: 36)),
                              SizedBox(height: isCompact ? 6 : 8),
                              Text(quest.title,
                                  style: TextStyle(
                                      fontSize: questTitleSize,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Vipnagorgialla',
                                      color: AppConstants.textColor)),
                              SizedBox(height: isCompact ? 4 : 6),
                              Text(quest.desc,
                                  style: TextStyle(
                                      fontSize: questDescSize,
                                      color: AppConstants.mutedColor,
                                      fontFamily: 'Vipnagorgialla')),
                              SizedBox(height: isCompact ? 8 : 10),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 10 : 12,
                                    vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppConstants.brandColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  quest.reward,
                                  style: TextStyle(
                                    fontSize: rewardSize,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.brandColor,
                                    fontFamily: 'Vipnagorgialla',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskSelection() {
    final quest = _selectedQuest;
    if (quest == null) return const SizedBox.shrink();
    final isCompact = _isCompact(context);
    final width = _contentWidth(context, 600);

    return Column(
      children: [
        _buildHeader('Quest Selected', () {
          setState(() => _screen = ScreenId.insertTrash);
        }),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppConstants.brandColor, AppConstants.brand2Color]),
            ),
            child: Center(
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _iconForType(quest.type),
                      style: TextStyle(
                          fontSize: isCompact ? 64 : 80, color: Colors.white),
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    Text(
                      quest.title,
                      style: TextStyle(
                        fontSize: isCompact ? 32 : 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Vipnagorgialla',
                      ),
                    ),
                    SizedBox(height: isCompact ? 6 : 8),
                    Text(
                      quest.desc,
                      style: TextStyle(
                          fontSize: isCompact ? 18 : 22,
                          color: Colors.white70,
                          fontFamily: 'Vipnagorgialla'),
                    ),
                    SizedBox(height: isCompact ? 12 : 16),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 14 : 18,
                          vertical: isCompact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Text(
                        quest.reward,
                        style: TextStyle(
                          fontSize: isCompact ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Vipnagorgialla',
                        ),
                      ),
                    ),
                    SizedBox(height: isCompact ? 16 : 24),
                    Container(
                      padding: EdgeInsets.all(isCompact ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        children: [
                          _detailRow('Target:', '${quest.target} items'),
                          _detailRow('Time Limit:', '20 seconds'),
                          _detailRow('Reward:', quest.reward),
                        ],
                      ),
                    ),
                    SizedBox(height: isCompact ? 16 : 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _startQuest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppConstants.brandColor,
                            padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 20 : 28,
                                vertical: isCompact ? 14 : 18),
                          ),
                          child: Text(
                            'Start Quest',
                            style: TextStyle(
                                fontSize: isCompact ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vipnagorgialla'),
                          ),
                        ),
                        SizedBox(width: isCompact ? 12 : 16),
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => _screen = ScreenId.insertTrash),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 20 : 28,
                                vertical: isCompact ? 14 : 18),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                fontSize: isCompact ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vipnagorgialla'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    final isCompact = _isCompact(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: isCompact ? 16 : 18,
                      color: Colors.white70,
                      fontFamily: 'Vipnagorgialla'))),
          Text(
            value,
            style: TextStyle(
                fontSize: isCompact ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Vipnagorgialla'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuest() {
    final quest = _activeQuest;
    if (quest == null) return const SizedBox.shrink();
    final isCompact = _isCompact(context);
    final progressPct = (_progress / quest.target).clamp(0.0, 1.0);
    final width = _contentWidth(context, 700);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppConstants.brandColor, AppConstants.brand2Color]),
      ),
      child: Center(
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _card(
                compact: isCompact,
                child: Column(
                  children: [
                    Text('Time Remaining',
                        style: TextStyle(
                            fontSize: isCompact ? 18 : 20,
                            color: AppConstants.mutedColor,
                            fontFamily: 'Vipnagorgialla')),
                    SizedBox(height: isCompact ? 4 : 6),
                    Text(
                      '$_timeLeft',
                      style: TextStyle(
                        fontSize: isCompact ? 48 : 64,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.brandColor,
                        fontFamily: 'Vipnagorgialla',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isCompact ? 12 : 16),
              _card(
                compact: isCompact,
                child: Column(
                  children: [
                    Text(
                      '$_progress / ${quest.target} items inserted',
                      style: TextStyle(
                          fontSize: isCompact ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Vipnagorgialla',
                          color: AppConstants.textColor),
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: LinearProgressIndicator(
                        minHeight: isCompact ? 20 : 24,
                        value: progressPct,
                        backgroundColor: AppConstants.mutedColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(AppConstants.brandColor),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isCompact ? 12 : 16),
              _card(
                compact: isCompact,
                child: Column(
                  children: [
                    Text('Demo Controls (Testing)',
                        style: TextStyle(
                            fontSize: isCompact ? 18 : 20,
                            color: AppConstants.mutedColor,
                            fontFamily: 'Vipnagorgialla')),
                    SizedBox(height: isCompact ? 8 : 12),
                    Wrap(
                      spacing: isCompact ? 8 : 12,
                      runSpacing: isCompact ? 8 : 12,
                      children: [
                        _demoButton('+1 Plastic Bottle', () => _addItem('plastic'),
                            compact: isCompact),
                        _demoButton('+1 Paper', () => _addItem('paper'),
                            compact: isCompact),
                        _demoButton('+1 Single Stream',
                            () => _addItem('single-stream'),
                            compact: isCompact),
                        _demoButton('+1 Mixed', () => _addItem('mixed'),
                            compact: isCompact),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoButton(String text, VoidCallback onTap, {bool compact = false}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.okColor,
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 18, vertical: compact ? 12 : 16),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Vipnagorgialla')),
    );
  }

  Widget _card({required Widget child, bool compact = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: child,
    );
  }

  Widget _buildHowToUse() {
    final isCompact = _isCompact(context);
    final width = _contentWidth(context, 800);

    return Column(
      children: [
        _buildHeader('How to Use', _goHome),
        Expanded(
          child: Container(
            color: AppConstants.bgColor,
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Center(
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    _InstructionStep(
                      number: '1',
                      title: 'Choose Your Action',
                      text:
                          'You can throw a trash or you can interact with the trashbin using the screen.',
                      compact: isCompact,
                    ),
                    _InstructionStep(
                      number: '2',
                      title: 'Tap the Screen',
                      text: 'Tap the screen and choose insert trash.',
                      compact: isCompact,
                    ),
                    _InstructionStep(
                      number: '3',
                      title: 'Choose Your Task',
                      text: 'Choose your preferred task.',
                      compact: isCompact,
                    ),
                    _InstructionStep(
                      number: '4',
                      title: 'Earn Voucher',
                      text: 'Earn Voucher by throwing trash!',
                      compact: isCompact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrinting() {
    final isCompact = _isCompact(context);

    return _FullCenterGradient(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Spinner(),
          SizedBox(height: isCompact ? 12 : 16),
          Text(
            'Printing...',
            style: TextStyle(
                fontSize: isCompact ? 28 : 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Vipnagorgialla'),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text('Please wait',
              style: TextStyle(
                  fontSize: isCompact ? 16 : 20,
                  color: Colors.white70,
                  fontFamily: 'Vipnagorgialla')),
        ],
      ),
    );
  }

  Widget _buildThankYou() {
    final isCompact = _isCompact(context);

    return _FullCenterGradient(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _SuccessIcon(),
          SizedBox(height: isCompact ? 12 : 16),
          Text(
            'Thank You!',
            style: TextStyle(
                fontSize: isCompact ? 32 : 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Vipnagorgialla'),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text('Please get your voucher.',
              style: TextStyle(
                  fontSize: isCompact ? 16 : 20,
                  color: Colors.white70,
                  fontFamily: 'Vipnagorgialla')),
        ],
      ),
    );
  }

  Widget _buildMenuModal() {
    final isCompact = _isCompact(context);
    final width = _contentWidth(context, 600);

    return AnimatedOpacity(
      opacity: _showMenu ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_showMenu,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              width: width,
              padding: EdgeInsets.all(isCompact ? 20 : 32),
              decoration: BoxDecoration(
                color: AppConstants.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'What would you like to do?',
                    style: TextStyle(
                        fontSize: isCompact ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vipnagorgialla',
                        color: AppConstants.textColor),
                  ),
                  SizedBox(height: isCompact ? 16 : 24),
                  _menuButton('Insert Trash', () {
                    setState(() {
                      _showMenu = false;
                      _screen = ScreenId.insertTrash;
                    });
                  }, compact: isCompact),
                  SizedBox(height: isCompact ? 8 : 12),
                  _menuButton('How to Use', () {
                    setState(() {
                      _showMenu = false;
                      _screen = ScreenId.howToUse;
                    });
                  }, compact: isCompact),
                  SizedBox(height: isCompact ? 8 : 12),
                  _menuButton('Back to Home Screen', () {
                    _goHome();
                  }, secondary: true, compact: isCompact),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton(String label, VoidCallback onTap,
      {bool secondary = false, bool compact = false}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            secondary ? AppConstants.mutedColor : AppConstants.brandColor,
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 18 : 24, vertical: compact ? 14 : 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
                fontSize: compact ? 16 : 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Vipnagorgialla')),
      ),
    );
  }

  Widget _buildCompletionPopup() {
    final isCompact = _isCompact(context);
    final width = _contentWidth(context, 520);

    return AnimatedOpacity(
      opacity: _showCompletion ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_showCompletion,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              width: width,
              padding: EdgeInsets.all(isCompact ? 20 : 32),
              decoration: BoxDecoration(
                color: AppConstants.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Quest Complete!',
                    style: TextStyle(
                      fontSize: isCompact ? 24 : 30,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.okColor,
                      fontFamily: 'Vipnagorgialla',
                    ),
                  ),
                  SizedBox(height: isCompact ? 8 : 12),
                  Text(
                    'Congratulations! You\'ve completed your quest.',
                    style: TextStyle(
                        fontSize: isCompact ? 16 : 18,
                        color: AppConstants.mutedColor,
                        fontFamily: 'Vipnagorgialla'),
                  ),
                  SizedBox(height: isCompact ? 12 : 18),
                  Text(
                    'Print my voucher?',
                    style: TextStyle(
                        fontSize: isCompact ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vipnagorgialla',
                        color: AppConstants.textColor),
                  ),
                  SizedBox(height: isCompact ? 12 : 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _printVoucher,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.okColor),
                          child: Text(
                            'YES',
                            style: TextStyle(
                                fontSize: isCompact ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vipnagorgialla'),
                          ),
                        ),
                      ),
                      SizedBox(width: isCompact ? 8 : 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _hideCompletionPopup();
                            _goHome();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.mutedColor),
                          child: Text(
                            'NO',
                            style: TextStyle(
                                fontSize: isCompact ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vipnagorgialla'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWrongTrashMessage() {
    final isCompact = _isCompact(context);
    final width = _contentWidth(context, 520);

    return AnimatedOpacity(
      opacity: _showWrongTrashMessage ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_showWrongTrashMessage,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              width: width,
              padding: EdgeInsets.all(isCompact ? 20 : 32),
              decoration: BoxDecoration(
                color: AppConstants.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: isCompact ? 64 : 80,
                    color: AppConstants.warnColor,
                  ),
                  SizedBox(height: isCompact ? 16 : 20),
                  Text(
                    'Wrong Trash Detected',
                    style: TextStyle(
                      fontSize: isCompact ? 24 : 30,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.warnColor,
                      fontFamily: 'Vipnagorgialla',
                    ),
                  ),
                  SizedBox(height: isCompact ? 12 : 16),
                  Text(
                    'You put a wrong trash, different from the task you choose. Still thank you for using our trashbin and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: isCompact ? 16 : 18,
                        color: AppConstants.textColor,
                        fontFamily: 'Vipnagorgialla'),
                  ),
                  SizedBox(height: isCompact ? 20 : 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hideWrongTrashMessage,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.brandColor,
                          padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 20 : 28,
                              vertical: isCompact ? 14 : 18)),
                      child: Text(
                        'OK',
                        style: TextStyle(
                            fontSize: isCompact ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vipnagorgialla'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _iconForType(String type) {
    switch (type) {
      case 'plastic':
        return '🧴';
      case 'paper':
        return '📄';
      case 'mixed':
        return '🗑️';
      case 'single-stream':
        return '♻️';
      default:
        return '🗑️';
    }
  }
}

class _PulseText extends StatefulWidget {
  const _PulseText(this.text, {this.fontSize = 28});

  final String text;
  final double fontSize;

  @override
  State<_PulseText> createState() => _PulseTextState();
}

class _PulseTextState extends State<_PulseText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
          vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(
        widget.text,
        style: TextStyle(
            fontSize: widget.fontSize,
            color: Colors.white,
            fontFamily: 'Vipnagorgialla'),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.number,
    required this.title,
    required this.text,
    this.compact = false,
  });

  final String number;
  final String title;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 12 : 18),
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 52 : 60,
            height: compact ? 52 : 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [AppConstants.brandColor, AppConstants.brand2Color]),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                  fontSize: compact ? 22 : 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vipnagorgialla'),
            ),
          ),
          SizedBox(width: compact ? 12 : 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: compact ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vipnagorgialla',
                        color: AppConstants.textColor)),
                SizedBox(height: compact ? 4 : 6),
                Text(text,
                    style: TextStyle(
                        fontSize: compact ? 16 : 18,
                        color: AppConstants.mutedColor,
                        fontFamily: 'Vipnagorgialla')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullCenterGradient extends StatelessWidget {
  const _FullCenterGradient({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppConstants.brandColor, AppConstants.brand2Color]),
      ),
      child: Center(child: child),
    );
  }
}

class _Spinner extends StatefulWidget {
  const _Spinner();

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 8),
        ),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: CircularProgressIndicator(
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation(Colors.white),
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.check, size: 64, color: AppConstants.okColor),
    );
  }
}

