import 'package:flutter/material.dart';
import '../models/bin.dart';
import '../constants/app_constants.dart';

class BinDetailModal extends StatelessWidget {
  final Bin bin;
  final List<CollectionRecord> collectionRecords;
  final TotalAcrossAllBins totalAcrossAllBins;
  final VoidCallback onClose;

  const BinDetailModal({
    super.key,
    required this.bin,
    required this.collectionRecords,
    required this.totalAcrossAllBins,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close on outside tap
        onClose();
      },
      child: Material(
        color: Colors.black.withOpacity(0.7),
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping inside
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 700,
                maxHeight: 900,
              ),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B), // slate-900
                    Color(0xFF0F172A), // slate-800
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppConstants.brand2Color.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBinOverview(context),
                            const SizedBox(height: 24),
                            _buildProgressIndicators(context),
                            const SizedBox(height: 24),
                            _buildBatteryInformation(context),
                            const SizedBox(height: 24),
                            _buildCollectionRecords(context),
                            const SizedBox(height: 24),
                            _buildOverallSummary(context),
                            const SizedBox(height: 24),
                            _buildSensorStatus(context),
                            const SizedBox(height: 24),
                            _buildAdditionalInformation(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: AppConstants.brand2Color.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bin.nameOrId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bin.locationOrId,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBinOverview(BuildContext context) {
    return _buildSection(
      context,
      title: 'Bin Overview',
      icon: Icons.trending_up,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildInfoRow('Type:', bin.type),
            const SizedBox(height: 12),
            _buildStatusRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    IconData iconData;
    Color color;
    String statusText;

    switch (bin.status) {
      case BinStatus.active:
        iconData = Icons.check_circle;
        color = AppConstants.okColor;
        statusText = 'Active';
        break;
      case BinStatus.offline:
        iconData = Icons.cancel;
        color = AppConstants.dangerColor;
        statusText = 'Offline';
        break;
      case BinStatus.needsAttention:
        iconData = Icons.warning;
        color = AppConstants.warnColor;
        statusText = 'Needs Attention';
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Status:',
          style: TextStyle(color: Color(0xFFCBD5E1)),
        ),
        Row(
          children: [
            Icon(iconData, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicators(BuildContext context) {
    return _buildSection(
      context,
      title: 'Progress Indicators',
      icon: Icons.trending_up,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildFillLevelProgress(),
            const SizedBox(height: 16),
            _buildVolumeInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildFillLevelProgress() {
    Color fillColor;
    if (bin.fillLevel >= 80) {
      fillColor = AppConstants.dangerColor;
    } else if (bin.fillLevel >= 60) {
      fillColor = AppConstants.warnColor;
    } else {
      fillColor = AppConstants.okColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fill Level',
              style: TextStyle(color: Color(0xFFCBD5E1)),
            ),
            Text(
              '${bin.fillLevel}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: bin.fillLevel / 100,
            child: Container(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeInfo() {
    final currentVol = bin.currentVolume ?? (bin.fillLevel * 10);
    final maxCap = bin.maxCapacity ?? 100;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Volume',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
              Text(
                '${currentVol}L',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Max Capacity',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
              Text(
                '${maxCap}L',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyProgress() {
    final progress = bin.dailyProgress ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF334155), width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Goal Progress',
                    style: TextStyle(color: Color(0xFFCBD5E1)),
                  ),
                  Text(
                    '$progress%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (progress > 100 ? 100 : progress) / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppConstants.brand2Color, AppConstants.brandColor],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryInformation(BuildContext context) {
    return _buildSection(
      context,
      title: 'Battery Information',
      icon: Icons.battery_charging_full,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Battery Level:',
                  style: TextStyle(color: Color(0xFFCBD5E1)),
                ),
                Text(
                  '${bin.batteryLevel}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: bin.batteryLevel / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getBatteryColor(bin.batteryLevel),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Health Status',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        bin.batteryStatusText,
                        style: TextStyle(
                          color: _getBatteryHealthColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Est. Time Remaining',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${bin.estimatedTimeRemaining ?? 24}h',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionRecords(BuildContext context) {
    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthStart = DateTime(today.year, today.month, 1);

    final todayItems = collectionRecords
        .where((r) =>
            r.collectedAt.year == today.year &&
            r.collectedAt.month == today.month &&
            r.collectedAt.day == today.day)
        .fold<int>(0, (sum, r) => sum + r.itemsCollected);

    final weekItems = collectionRecords
        .where((r) => r.collectedAt.isAfter(weekAgo))
        .fold<int>(0, (sum, r) => sum + r.itemsCollected);

    final monthItems = collectionRecords
        .where((r) => r.collectedAt.isAfter(monthStart) || r.collectedAt.isAtSameMomentAs(monthStart))
        .fold<int>(0, (sum, r) => sum + r.itemsCollected);

    return _buildSection(
      context,
      title: 'Collection Records - This Bin',
      icon: Icons.calendar_today,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatColumn('Today', todayItems),
            ),
            Container(
              width: 1,
              height: 60,
              color: const Color(0xFF334155),
            ),
            Expanded(
              child: _buildStatColumn('This Week', weekItems),
            ),
            Container(
              width: 1,
              height: 60,
              color: const Color(0xFF334155),
            ),
            Expanded(
              child: _buildStatColumn('This Month', monthItems),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'items',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildOverallSummary(BuildContext context) {
    return _buildSection(
      context,
      title: 'Overall Summary - All Bins Combined',
      icon: Icons.trending_up,
      titleColor: AppConstants.brandColor,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppConstants.brandColor.withOpacity(0.3),
              AppConstants.brand2Color.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.brandColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn('Paper', totalAcrossAllBins.paper),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: const Color(0xFF334155),
                ),
                Expanded(
                  child: _buildStatColumn('Plastic', totalAcrossAllBins.plastic),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: const Color(0xFF334155),
                ),
                Expanded(
                  child: _buildStatColumn('Single-Stream', totalAcrossAllBins.singleStream),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: const Color(0xFF334155),
                ),
                Expanded(
                  child: _buildStatColumn('Mixed', totalAcrossAllBins.mixed),
                ),
              ],
            ),
        const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF334155), width: 1),
                ),
              ),
              child: _buildStatColumn('Total', totalAcrossAllBins.total),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStatus(BuildContext context) {
    return _buildSection(
      context,
      title: 'Sensor Status',
      icon: Icons.sensors,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSensorIndicator(
                    'Ultrasonic',
                    bin.sensorUltrasonic ?? true,
                  ),
                ),
                Expanded(
                  child: _buildSensorIndicator(
                    'LED Screen',
                    bin.sensorLedScreen ?? true,
                  ),
                ),
                Expanded(
                  child: _buildSensorIndicator(
                    'Servo Motor',
                    bin.sensorServoMotor ?? true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSensorIndicator(
                    'Thermal Printer',
                    bin.sensorThermalPrinter ?? true,
                  ),
                ),
                Expanded(
                  child: _buildSensorIndicator(
                    'Battery',
                    bin.sensorBattery ?? true,
                  ),
                ),
                Expanded(
                  child: _buildSensorIndicator(
                    'Solar Panel',
                    bin.sensorSolarPanel ?? true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorIndicator(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppConstants.okColor : AppConstants.dangerColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 12,
          ),
        ),
        Text(
          isActive ? 'Active' : 'Offline',
          style: TextStyle(
            color: isActive ? AppConstants.okColor : AppConstants.dangerColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInformation(BuildContext context) {
    return _buildSection(
      context,
      title: 'Additional Information',
      icon: Icons.info_outline,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildInfoRow('Last Emptied:', bin.timeAgo),
            if (bin.hasAlert && bin.alertMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.dangerColor.withOpacity(0.3),
                  border: Border.all(
                    color: AppConstants.dangerColor.withOpacity(0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning,
                      color: AppConstants.dangerColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Alerts',
                            style: TextStyle(
                              color: AppConstants.dangerColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bin.alertMessage!,
                            style: const TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    Color? titleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: titleColor ?? AppConstants.brand2Color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: titleColor ?? AppConstants.brand2Color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFCBD5E1)),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getBatteryColor(int level) {
    if (level >= 70) return AppConstants.okColor;
    if (level >= 40) return AppConstants.warnColor;
    return AppConstants.dangerColor;
  }

  Color _getBatteryHealthColor() {
    final health = bin.batteryStatusText;
    if (health == 'Excellent') return AppConstants.okColor;
    if (health == 'Good') return AppConstants.brand2Color;
    if (health == 'Fair') return AppConstants.warnColor;
    return AppConstants.dangerColor;
  }
}

class TotalAcrossAllBins {
  final int paper;
  final int plastic;
  final int singleStream;
  final int mixed;
  final int total;

  TotalAcrossAllBins({
    required this.paper,
    required this.plastic,
    required this.singleStream,
    required this.mixed,
    required this.total,
  });
}

