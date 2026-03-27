import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/trash_points_service.dart';

class TrashPointsManagement extends StatefulWidget {
  const TrashPointsManagement({super.key});

  @override
  State<TrashPointsManagement> createState() => _TrashPointsManagementState();
}

class _TrashPointsManagementState extends State<TrashPointsManagement> {
  Map<String, double> _points = {};
  Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPoints() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final points = await TrashPointsService.getTrashPoints();
      setState(() {
        _points = points;
        // Initialize controllers with current values
        _controllers = {
          'Plastic': TextEditingController(text: points['Plastic']?.toString() ?? '5'),
          'Paper': TextEditingController(text: points['Paper']?.toString() ?? '3'),
          'Single-stream': TextEditingController(text: points['Single-stream']?.toString() ?? '4'),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading points: $e')),
        );
      }
    }
  }

  Future<void> _savePoints() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Validate all inputs
      final Map<String, double> newPoints = {};
      for (final entry in _controllers.entries) {
        final value = double.tryParse(entry.value.text.trim());
        if (value == null || value < 0) {
          throw Exception('Invalid points value for ${entry.key}. Please enter a non-negative number.');
        }
        newPoints[entry.key] = value;
      }

      await TrashPointsService.setTrashPoints(newPoints);
      
      setState(() {
        _points = newPoints;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Points updated successfully!'),
            backgroundColor: AppConstants.okColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving points: $e'),
            backgroundColor: AppConstants.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all points to default values?\n\n'
          'Default values:\n'
          '• Plastic: 5.0 points\n'
          '• Paper: 3.0 points\n'
          '• Single-stream: 4.0 points',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppConstants.dangerColor),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isSaving = true;
      });

      try {
        await TrashPointsService.resetToDefaults();
        await _loadPoints();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Points reset to defaults successfully!'),
              backgroundColor: AppConstants.okColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting points: $e'),
              backgroundColor: AppConstants.dangerColor,
            ),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildPointInputCard(String type, String label, IconData icon, Color color) {
    final controller = _controllers[type];
    if (controller == null) return const SizedBox.shrink();

    return Card(
      color: AppConstants.cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Points awarded per item',
                        style: TextStyle(
                          color: AppConstants.mutedColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: AppConstants.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Points',
                labelStyle: TextStyle(color: AppConstants.mutedColor),
                hintText: 'Enter points',
                hintStyle: TextStyle(color: AppConstants.mutedColor.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppConstants.mutedColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppConstants.mutedColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                filled: true,
                fillColor: AppConstants.panelColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixText: 'pts',
                suffixStyle: TextStyle(
                  color: AppConstants.mutedColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: AppConstants.bgColor,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.brandColor),
          ),
        ),
      );
    }

    return Container(
      color: AppConstants.bgColor,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'Trash Points Configuration',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust the points awarded for each trash type',
            style: TextStyle(
              color: AppConstants.mutedColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _buildPointInputCard(
            'Plastic',
            'Plastic',
            Icons.recycling,
            const Color(0xFFEF4444), // Red
          ),
          _buildPointInputCard(
            'Paper',
            'Paper',
            Icons.description,
            const Color(0xFFF59E0B), // Orange
          ),
          _buildPointInputCard(
            'Single-stream',
            'Single-stream',
            Icons.inventory_2,
            const Color(0xFF3B82F6), // Blue
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _resetToDefaults,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppConstants.mutedColor.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Reset to Defaults',
                    style: TextStyle(
                      color: AppConstants.mutedColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePoints,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.brandColor,
                    foregroundColor: AppConstants.bgColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.bgColor),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: AppConstants.cardColor.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppConstants.brand2Color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These points will be awarded to users when they dispose items in the respective trash bins.',
                      style: TextStyle(
                        color: AppConstants.mutedColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

