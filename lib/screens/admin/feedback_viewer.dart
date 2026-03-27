import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/feedback_service.dart';
import '../../models/feedback.dart' as feedback_model;

/// Feedback category colors matching the design
class _FeedbackColors {
  static const background = Color(0xFF1A202C);
  static const cardBg = Color(0xFF262D3D);
  static const support = Color(0xFF22C55E);
  static const bugs = Color(0xFFEF4444);
  static const ideas = Color(0xFF22D3EE);
  static const accent = Color(0xFF60A5FA);
  static const muted = Color(0xFFB0B0B0);
}

class _FeedbackUserMeta {
  final String? profilePicture;
  final String? idNumber;

  const _FeedbackUserMeta({this.profilePicture, this.idNumber});
}

class FeedbackViewer extends StatefulWidget {
  const FeedbackViewer({super.key});

  @override
  State<FeedbackViewer> createState() => _FeedbackViewerState();
}

class _FeedbackViewerState extends State<FeedbackViewer> {
  final FeedbackService _feedbackService = FeedbackService();
  List<feedback_model.Feedback> _feedbackList = [];
  bool _isLoading = true;
  String _timeFilter = 'Last 30 days';

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
    });
    final feedback = await _feedbackService.getAllFeedback();
    final resolvedUserMetadata = await _resolveMissingUserMetadata(feedback);
    final enrichedFeedback = feedback.map((item) {
      final meta = resolvedUserMetadata[item.userId];
      var updated = item;

      if ((updated.profilePicture == null || updated.profilePicture!.isEmpty) &&
          meta?.profilePicture != null &&
          meta!.profilePicture!.isNotEmpty) {
        updated = updated.copyWith(profilePicture: meta.profilePicture);
      }

      if ((updated.idNumber == null || updated.idNumber!.isEmpty) &&
          meta?.idNumber != null &&
          meta!.idNumber!.isNotEmpty) {
        updated = updated.copyWith(idNumber: meta.idNumber);
      }

      return updated;
    }).toList();
    setState(() {
      _feedbackList = enrichedFeedback;
      _isLoading = false;
    });
  }

  Future<Map<String, _FeedbackUserMeta>> _resolveMissingUserMetadata(
    List<feedback_model.Feedback> feedbackItems,
  ) async {
    final userIds = feedbackItems
        .where(
          (item) =>
              ((item.profilePicture == null || item.profilePicture!.isEmpty) ||
                  (item.idNumber == null || item.idNumber!.isEmpty)) &&
              item.userId != null &&
              item.userId!.isNotEmpty,
        )
        .map((item) => item.userId!)
        .toSet()
        .toList();

    if (userIds.isEmpty) return const <String, _FeedbackUserMeta>{};

    final result = <String, _FeedbackUserMeta>{};
    await Future.wait(
      userIds.map((userId) async {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          if (!userDoc.exists) return;
          final data = userDoc.data();
          final profilePicture = data?['profilePicture'];
          final idNumber = data?['idNumber'];
          result[userId] = _FeedbackUserMeta(
            profilePicture:
                profilePicture is String && profilePicture.isNotEmpty ? profilePicture : null,
            idNumber: idNumber is String && idNumber.isNotEmpty ? idNumber : null,
          );
        } catch (_) {
          // Keep feedback loading resilient even if one lookup fails.
        }
      }),
    );

    return result;
  }

  Future<void> _deleteFeedback(String feedbackId) async {
    final success = await _feedbackService.deleteFeedback(feedbackId);
    if (success && mounted) {
      _loadFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback deleted successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete feedback')),
      );
    }
  }

  /// Categorize feedback for overview. Uses stored category or derives from message.
  Map<String, int> _getCategoryCounts() {
    final counts = <String, int>{'Support': 0, 'Bugs': 0, 'Ideas': 0};
    for (final f in _feedbackList) {
      final cat = (f.category ?? 'Support').toLowerCase();
      if (cat == 'bugs' || cat == 'bugs & errors') {
        counts['Bugs'] = (counts['Bugs'] ?? 0) + 1;
      } else if (cat == 'ideas' || cat == 'ideas and suggestions') {
        counts['Ideas'] = (counts['Ideas'] ?? 0) + 1;
      } else {
        counts['Support'] = (counts['Support'] ?? 0) + 1;
      }
    }
    return counts;
  }

  Color _colorForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'bugs':
      case 'bugs & errors':
        return _FeedbackColors.bugs;
      case 'ideas':
      case 'ideas and suggestions':
        return _FeedbackColors.ideas;
      default:
        return _FeedbackColors.support;
    }
  }

  String _categoryDisplayLabel(String cat) {
    final c = cat.toLowerCase();
    if (c == 'bugs' || c == 'bugs & errors') return 'BUGS & ERRORS';
    if (c == 'ideas' || c == 'ideas and suggestions') return 'IDEAS AND SUGGESTIONS';
    return cat.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FeedbackColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _FeedbackColors.accent),
            )
          : RefreshIndicator(
              onRefresh: _loadFeedback,
              color: _FeedbackColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCard(),
                    const SizedBox(height: 24),
                    _buildRecentItemsHeader(),
                    const SizedBox(height: 12),
                    if (_feedbackList.isEmpty)
                      _buildEmptyState()
                    else
                      ..._feedbackList.take(20).map(_buildFeedbackCard).toList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to feedback submission or show compose dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add feedback coming soon')),
          );
        },
        backgroundColor: _FeedbackColors.support,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final counts = _getCategoryCounts();
    final total = counts.values.fold(0, (a, b) => a + b);
    final supportCount = counts['Support'] ?? 0;
    final bugsCount = counts['Bugs'] ?? 0;
    final ideasCount = counts['Ideas'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _FeedbackColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OVERVIEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _timeFilter = _timeFilter == 'Last 30 days'
                        ? 'Last 7 days'
                        : 'Last 30 days';
                  });
                },
                child: Text(
                  _timeFilter,
                  style: const TextStyle(
                    color: _FeedbackColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    values: [
                      supportCount / total.clamp(1, 0x7FFFFFFF),
                      bugsCount / total.clamp(1, 0x7FFFFFFF),
                      ideasCount / total.clamp(1, 0x7FFFFFFF),
                    ],
                    colors: const [
                      _FeedbackColors.support,
                      _FeedbackColors.bugs,
                      _FeedbackColors.ideas,
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: _FeedbackColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendRow('Support', supportCount, _FeedbackColors.support),
                    const SizedBox(height: 10),
                    _buildLegendRow('Bugs & Errors', bugsCount, _FeedbackColors.bugs),
                    const SizedBox(height: 10),
                    _buildLegendRow('Ideas and Suggestions', ideasCount, _FeedbackColors.ideas),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: _FeedbackColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItemsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Items',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Sort by Date',
            style: TextStyle(
              color: _FeedbackColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.feedback_outlined, size: 64, color: _FeedbackColors.muted),
            const SizedBox(height: 16),
            Text(
              'No feedback available',
              style: TextStyle(color: _FeedbackColors.muted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImageProvider(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) return null;
    if (profilePicture.startsWith('data:')) {
      final commaIndex = profilePicture.indexOf(',');
      if (commaIndex != -1) {
        try {
          final base64String = profilePicture.substring(commaIndex + 1);
          final bytes = base64Decode(base64String);
          return MemoryImage(bytes);
        } catch (_) {
          return null;
        }
      }
    }
    return NetworkImage(profilePicture);
  }

  Widget _buildFeedbackCard(feedback_model.Feedback feedback) {
    final category = feedback.category ?? 'Support';
    final color = _colorForCategory(category);
    final subject = feedback.subject ??
        (feedback.message.length > 50
            ? '${feedback.message.substring(0, 50)}...'
            : feedback.message);
    final displayName = feedback.name ?? 'Anonymous User';
    final subtext = (feedback.idNumber != null && feedback.idNumber!.isNotEmpty)
        ? 'ID: ${feedback.idNumber}'
        : (feedback.email ?? 'ID: #${feedback.id.substring(0, 5).toUpperCase()}');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final profileImage = _getProfileImageProvider(feedback.profilePicture);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _FeedbackColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: profileImage != null ? Colors.transparent : color.withOpacity(0.3),
                backgroundImage: profileImage,
                child: profileImage == null
                    ? (displayName == 'Anonymous User'
                        ? Icon(Icons.person_outline, color: _FeedbackColors.muted, size: 20)
                        : Text(
                            initial,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtext,
                      style: const TextStyle(
                        color: _FeedbackColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _categoryDisplayLabel(category),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: _FeedbackColors.muted, size: 20),
                    color: _FeedbackColors.cardBg,
                    onSelected: (value) {
                      if (value == 'delete') _deleteFeedback(feedback.id);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subject,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            feedback.message.length > 100
                ? '${feedback.message.substring(0, 100)}...'
                : feedback.message,
            style: const TextStyle(
              color: _FeedbackColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: _FeedbackColors.muted.withOpacity(0.3), height: 1, thickness: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(feedback.feedbackTime),
                style: const TextStyle(
                  color: _FeedbackColors.muted,
                  fontSize: 12,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.reply, size: 14, color: _FeedbackColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Reply',
                          style: TextStyle(
                            color: _FeedbackColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showFeedbackDetail(feedback),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility, size: 14, color: _FeedbackColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'View',
                          style: TextStyle(
                            color: _FeedbackColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final am = dt.hour < 12 ? 'AM' : 'PM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • ${h.toString().padLeft(2, '0')}:$min $am';
  }

  void _showFeedbackDetail(feedback_model.Feedback feedback) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _FeedbackColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feedback.subject ?? 'Feedback',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              feedback.message,
              style: const TextStyle(
                color: _FeedbackColors.muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatDate(feedback.feedbackTime),
              style: const TextStyle(color: _FeedbackColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(backgroundColor: _FeedbackColors.support),
                  child: const Text('Reply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final strokeWidth = 12.0;

    double start = -3.1415926535 / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = 2 * 3.1415926535 * values[i].clamp(0.0, 1.0);
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) =>
      old.values != values || old.colors != colors;
}
