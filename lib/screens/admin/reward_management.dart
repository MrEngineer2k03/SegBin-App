import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/reward.dart';
import '../../models/quest.dart';
import '../../services/reward_firestore_service.dart';
import '../../services/quest_firestore_service.dart';

class RewardManagement extends StatefulWidget {
  const RewardManagement({super.key});

  @override
  State<RewardManagement> createState() => _RewardManagementState();
}

class _RewardManagementState extends State<RewardManagement> {
  List<Reward> _rewards = [];
  List<Quest> _quests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rewards = await RewardFirestoreService.getAllRewards();
      final quests = await QuestFirestoreService.getAllQuests();
      setState(() {
        _rewards = rewards;
        _quests = quests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rewards: $e')),
        );
      }
    }
  }

  Future<void> _showAddRewardDialog({Reward? reward}) async {
    final nameController = TextEditingController(text: reward?.name ?? '');
    final descriptionController =
        TextEditingController(text: reward?.description ?? '');
    final pointsController = TextEditingController(
        text: reward?.minimumRequirement.toString() ?? '');
    final redeemCodeController =
        TextEditingController(text: reward?.redeemCode ?? '');
    
    // Rewards are always for mobile
    String selectedPlatform = 'mobile';

    final formKey = GlobalKey<FormState>();
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(reward == null ? 'Add New Reward' : 'Edit Reward'),
            content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Reward Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter reward name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Reward Information',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter reward information';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Reward Points Needed',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter points needed';
                    }
                    final points = int.tryParse(value);
                    if (points == null || points < 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: redeemCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Redeem Code (Optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Leave empty if no redeem code needed',
                  ),
                  textCapitalization: TextCapitalization.characters,
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
                    final redeemCode = redeemCodeController.text.trim();
                    await _saveReward(
                      reward?.id,
                      nameController.text.trim(),
                      descriptionController.text.trim(),
                      int.parse(pointsController.text.trim()),
                      redeemCode.isEmpty ? null : redeemCode.toUpperCase(),
                      selectedPlatform,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.brandColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(reward == null ? 'Create' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddQuestDialog({Quest? quest}) async {
    final nameController = TextEditingController(text: quest?.name ?? '');
    final descriptionController =
        TextEditingController(text: quest?.description ?? '');
    final rewardController = TextEditingController(text: quest?.reward ?? '');
    final targetController = TextEditingController(
        text: quest?.target.toString() ?? '1');
    
    QuestTrashType selectedType = quest?.type ?? QuestTrashType.plastic;

    final formKey = GlobalKey<FormState>();
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(quest == null ? 'Add New Quest' : 'Edit Quest'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name of Quest',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter quest name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<QuestTrashType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Name of Trash',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: QuestTrashType.plastic,
                          child: Text('Plastic'),
                        ),
                        DropdownMenuItem(
                          value: QuestTrashType.paper,
                          child: Text('Paper'),
                        ),
                        DropdownMenuItem(
                          value: QuestTrashType.singleStream,
                          child: Text('Single Stream'),
                        ),
                        DropdownMenuItem(
                          value: QuestTrashType.mixed,
                          child: Text('Mixed'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedType = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select trash type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: rewardController,
                      decoration: const InputDecoration(
                        labelText: 'Rewards',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter rewards';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: targetController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Trash',
                        border: OutlineInputBorder(),
                        helperText: 'Target number of items for this quest',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter number of trash';
                        }
                        final target = int.tryParse(value);
                        if (target == null || target < 1) {
                          return 'Please enter a valid number (at least 1)';
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
                    await _saveQuest(
                      quest?.id,
                      nameController.text.trim(),
                      selectedType.typeString,
                      descriptionController.text.trim(),
                      rewardController.text.trim(),
                      int.parse(targetController.text.trim()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(quest == null ? 'Create' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveQuest(
    String? id,
    String name,
    String type,
    String description,
    String reward,
    int target,
  ) async {
    try {
      if (id == null) {
        // Create new quest
        await QuestFirestoreService.createQuest(
          name: name,
          type: type,
          description: description,
          reward: reward,
          target: target,
          platform: 'kiosk', // Quests are for kiosk
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quest created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing quest
        final success = await QuestFirestoreService.updateQuest(
          id: id,
          name: name,
          type: type,
          description: description,
          reward: reward,
          target: target,
        );
        
        // Note: We don't update the reward automatically to avoid duplicates
        // Admin can manually update the reward if needed
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Quest updated successfully'
                  : 'Failed to update quest'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
      _loadRewards();
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

  Future<void> _deleteQuest(Quest quest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quest'),
        content: Text('Are you sure you want to delete "${quest.name}"?'),
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
        final success = await QuestFirestoreService.deleteQuest(quest.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Quest deleted successfully'
                  : 'Failed to delete quest'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
        _loadRewards();
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

  Future<void> _saveReward(
    String? id,
    String name,
    String description,
    int pointsNeeded,
    String? redeemCode,
    String platform,
  ) async {
    try {
      if (id == null) {
        // Create new reward
        await RewardFirestoreService.createReward(
          name: name,
          description: description,
          pointsNeeded: pointsNeeded,
          redeemCode: redeemCode,
          platform: platform,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reward created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing reward
        final success = await RewardFirestoreService.updateReward(
          id: id,
          name: name,
          description: description,
          pointsNeeded: pointsNeeded,
          redeemCode: redeemCode,
          platform: platform,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Reward updated successfully'
                  : 'Failed to update reward'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
      _loadRewards();
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

  Future<void> _deleteReward(Reward reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reward'),
        content: Text('Are you sure you want to delete "${reward.name}"?'),
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
        final success = await RewardFirestoreService.deleteReward(reward.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Reward deleted successfully'
                  : 'Failed to delete reward'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
        _loadRewards();
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
    return Container(
      color: AppConstants.bgColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: const Text(
                  'Reward Management',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showAddQuestDialog(),
                      icon: const Icon(Icons.assignment),
                      label: const Text('Add Quest'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRewardDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Reward'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.brandColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _rewards.isEmpty && _quests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.card_giftcard,
                              size: 64,
                              color: AppConstants.mutedColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No rewards yet',
                              style: TextStyle(
                                color: AppConstants.mutedColor,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click "Add Reward" or "Add Quest" to create your first reward',
                              style: TextStyle(
                                color: AppConstants.mutedColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _rewards.length + _quests.length,
                        itemBuilder: (context, index) {
                          // Show rewards first, then quests
                          if (index < _rewards.length) {
                            final reward = _rewards[index];
                            return Card(
                              color: AppConstants.cardColor,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  reward.name,
                                  style: const TextStyle(
                                    color: AppConstants.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      reward.description,
                                      style: const TextStyle(
                                        color: AppConstants.mutedColor,
                                      ),
                                    ),
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
                                          '${reward.minimumRequirement} points needed',
                                          style: TextStyle(
                                            color: AppConstants.brandColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                    if (reward.redeemCode != null &&
                                        reward.redeemCode!.isNotEmpty) ...[
                                          Icon(
                                            Icons.local_offer,
                                            size: 16,
                                            color: AppConstants.mutedColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Code: ${reward.redeemCode}',
                                            style: const TextStyle(
                                              color: AppConstants.mutedColor,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: reward.platform ==
                                                    RewardPlatform.mobile
                                                ? Colors.blue.withOpacity(0.1)
                                                : reward.platform ==
                                                        RewardPlatform.kiosk
                                                    ? Colors.orange.withOpacity(0.1)
                                                    : Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            reward.platform == RewardPlatform.mobile
                                                ? '📱 Mobile'
                                                : reward.platform ==
                                                        RewardPlatform.kiosk
                                                    ? '🖥️ Kiosk'
                                                    : '📱🖥️ Both',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: reward.platform ==
                                                      RewardPlatform.mobile
                                                  ? Colors.blue
                                                  : reward.platform ==
                                                          RewardPlatform.kiosk
                                                      ? Colors.orange
                                                      : Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      color: AppConstants.brandColor,
                                      onPressed: () =>
                                          _showAddRewardDialog(reward: reward),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: () => _deleteReward(reward),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            // Show quests
                            final questIndex = index - _rewards.length;
                            final quest = _quests[questIndex];
                            return Card(
                              color: AppConstants.cardColor,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        quest.name,
                                        style: const TextStyle(
                                          color: AppConstants.textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        '🖥️ Kiosk',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      quest.description,
                                      style: const TextStyle(
                                        color: AppConstants.mutedColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.assignment,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Type: ${quest.typeDisplayName}',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.flag,
                                          size: 16,
                                          color: AppConstants.brandColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Target: ${quest.target} items',
                                          style: TextStyle(
                                            color: AppConstants.brandColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.card_giftcard,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          quest.reward,
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      color: Colors.blue,
                                      onPressed: () =>
                                          _showAddQuestDialog(quest: quest),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: () => _deleteQuest(quest),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

