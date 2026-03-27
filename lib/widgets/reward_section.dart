import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reward.dart';
import '../services/reward_service.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';

class RewardSection extends StatefulWidget {
  const RewardSection({super.key});

  @override
  State<RewardSection> createState() => _RewardSectionState();
}

class _RewardSectionState extends State<RewardSection> {
  List<Reward> _rewards = [];
  bool _isLoading = true;
  final TextEditingController _redeemCodeController = TextEditingController();
  bool _isRedeeming = false;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  @override
  void dispose() {
    _redeemCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadRewards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await RewardService.initializeProgress();
      final rewards = await RewardService.getUserRewards();
      setState(() {
        _rewards = rewards;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading rewards: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _redeemReward(Reward reward) async {
    final success = await RewardService.redeemReward(reward.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reward.name} redeemed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadRewards(); // Refresh the list
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to redeem reward'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyRedeemCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redeem code copied: $code'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _redeemByCode() async {
    final code = _redeemCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 4-digit code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if it's a 4-digit code (reward code) or longer (reward redeem code)
    if (code.length == 4 && RegExp(r'^\d{4}$').hasMatch(code)) {
      // This is a reward code (4-digit code that gives points)
      setState(() {
        _isRedeeming = true;
      });

      try {
        final result = await RewardService.redeemRewardCode(code);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] as String),
              backgroundColor: result['success'] as bool ? Colors.green : Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );

          if (result['success'] as bool) {
            _redeemCodeController.clear();
            _loadRewards(); // Refresh the list
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isRedeeming = false;
          });
        }
      }
    } else {
      // This is a reward redeem code (longer code for redeeming rewards)
      setState(() {
        _isRedeeming = true;
      });

      try {
        final result = await RewardService.redeemByCode(code);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] as String),
              backgroundColor: result['success'] as bool ? Colors.green : Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );

          if (result['success'] as bool) {
            _redeemCodeController.clear();
            _loadRewards(); // Refresh the list
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isRedeeming = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_rewards.isEmpty) {
      return Center(
        child: Text(
          'No rewards available',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    final currentUser = AuthService.currentUser;
    final userPoints = currentUser?.points ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rewards',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadRewards,
                tooltip: 'Refresh rewards',
              ),
            ],
          ),
        ),
        // User Points Display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppConstants.brandColor.withOpacity(0.15),
                    AppConstants.brandColor.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.brandColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.stars,
                      color: AppConstants.brandColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Points',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$userPoints points',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppConstants.brandColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Redeem Code Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppConstants.brandColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppConstants.brandColor.withOpacity(0.1),
                    AppConstants.brandColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        color: AppConstants.brandColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Redeem Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _redeemCodeController,
                          decoration: InputDecoration(
                            hintText: 'Enter redeem code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppConstants.brandColor.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppConstants.brandColor.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppConstants.brandColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                          onSubmitted: (_) => _redeemByCode(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isRedeeming ? null : _redeemByCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isRedeeming
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Redeem',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _rewards.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _RewardCard(
              reward: _rewards[index],
              onRedeem: () => _redeemReward(_rewards[index]),
              onCopyCode: (code) => _copyRedeemCode(code),
            );
          },
        ),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  final Reward reward;
  final VoidCallback onRedeem;
  final ValueChanged<String> onCopyCode;

  const _RewardCard({
    required this.reward,
    required this.onRedeem,
    required this.onCopyCode,
  });

  Color _getStatusColor() {
    switch (reward.status) {
      case RewardStatus.locked:
        return Colors.grey;
      case RewardStatus.available:
        return AppConstants.brandColor;
      case RewardStatus.redeemed:
        return Colors.green;
    }
  }

  IconData _getStatusIcon() {
    switch (reward.status) {
      case RewardStatus.locked:
        return Icons.lock_outline;
      case RewardStatus.available:
        return Icons.check_circle_outline;
      case RewardStatus.redeemed:
        return Icons.check_circle;
    }
  }

  String _getStatusText() {
    switch (reward.status) {
      case RewardStatus.locked:
        return 'Locked';
      case RewardStatus.available:
        return 'Available';
      case RewardStatus.redeemed:
        return 'Redeemed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final statusColor = _getStatusColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: reward.status == RewardStatus.available
              ? statusColor.withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reward.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(),
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              reward.description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            // Progress section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '${reward.currentProgress.clamp(0.0, reward.minimumRequirement.toDouble())} / ${reward.minimumRequirement} points',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: reward.progressPercentage,
                    minHeight: 8,
                    backgroundColor: isLight
                        ? Colors.grey.shade200
                        : Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      reward.status == RewardStatus.redeemed
                          ? Colors.green
                          : statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(reward.progressPercentage * 100).toStringAsFixed(0)}% complete',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            // Redeem code section (only show if available/redeemed and has redeem code)
            if (reward.status != RewardStatus.locked &&
                reward.redeemCode != null &&
                reward.redeemCode!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLight
                      ? statusColor.withOpacity(0.1)
                      : statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 20,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Redeem Code',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reward.redeemCode!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: () => onCopyCode(reward.redeemCode!),
                      tooltip: 'Copy code',
                      color: statusColor,
                    ),
                  ],
                ),
              ),
            ],
            // Redeem button (only show if available)
            if (reward.status == RewardStatus.available) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRedeem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Redeem Now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

