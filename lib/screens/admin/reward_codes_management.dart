import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/reward_code.dart';
import '../../services/reward_code_firestore_service.dart';

class RewardCodesManagement extends StatefulWidget {
  const RewardCodesManagement({super.key});

  @override
  State<RewardCodesManagement> createState() => _RewardCodesManagementState();
}

class _RewardCodesManagementState extends State<RewardCodesManagement> {
  List<RewardCode> _rewardCodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRewardCodes();
  }

  Future<void> _loadRewardCodes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final codes = await RewardCodeFirestoreService.getAllRewardCodes();
      setState(() {
        _rewardCodes = codes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reward codes: $e')),
        );
      }
    }
  }

  Future<void> _showAddRewardCodeDialog() async {
    final codeController = TextEditingController();
    final pointsController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Reward Code'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Enter 4 digit code',
                    border: OutlineInputBorder(),
                    hintText: '0000',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a 4-digit code';
                    }
                    if (value.length != 4) {
                      return 'Code must be exactly 4 digits';
                    }
                    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                      return 'Code must contain only numbers';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Enter number of points',
                    border: OutlineInputBorder(),
                    hintText: '100',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter number of points';
                    }
                    final points = double.tryParse(value);
                    if (points == null || points < 0) {
                      return 'Please enter a valid number (non-negative)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                await _saveRewardCode(
                  codeController.text.trim(),
                  double.parse(pointsController.text.trim()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRewardCode(String code, double points) async {
    try {
      await RewardCodeFirestoreService.createRewardCode(
        code: code,
        points: points,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reward code created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadRewardCodes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRewardCode(RewardCode rewardCode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reward Code'),
        content: Text('Are you sure you want to delete code "${rewardCode.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success =
            await RewardCodeFirestoreService.deleteRewardCode(rewardCode.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Reward code deleted successfully'
                  : 'Failed to delete reward code'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
        _loadRewardCodes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reward Codes Management',
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _rewardCodes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: 64,
                              color: AppConstants.mutedColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reward codes yet',
                              style: TextStyle(
                                color: AppConstants.mutedColor,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click "Add Reward Code" to create your first code',
                              style: TextStyle(
                                color: AppConstants.mutedColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _rewardCodes.length,
                        itemBuilder: (context, index) {
                          final code = _rewardCodes[index];
                          return Card(
                            color: AppConstants.cardColor,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  Text(
                                    code.code,
                                    style: TextStyle(
                                      color: AppConstants.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (code.isRedeemed)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Redeemed',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Available',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.stars,
                                        size: 16,
                                        color: AppConstants.brandColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${code.points} points',
                                        style: TextStyle(
                                          color: AppConstants.brandColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (code.isRedeemed && code.redeemedAt != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Redeemed on: ${_formatDate(code.redeemedAt!)}',
                                        style: TextStyle(
                                          color: AppConstants.mutedColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => _deleteRewardCode(code),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRewardCodeDialog(),
        backgroundColor: AppConstants.brandColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

