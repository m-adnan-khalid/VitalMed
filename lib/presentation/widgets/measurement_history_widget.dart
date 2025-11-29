
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ble_provider.dart';
import '../../domain/entities/measurement.dart';

class MeasurementHistoryWidget extends ConsumerStatefulWidget {
  const MeasurementHistoryWidget({super.key});

  @override
  ConsumerState<MeasurementHistoryWidget> createState() => _MeasurementHistoryWidgetState();
}

class _MeasurementHistoryWidgetState extends ConsumerState<MeasurementHistoryWidget> {
  MeasurementType? _selectedType;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final measurementsAsync = ref.watch(savedMeasurementsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<MeasurementType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Device Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
                    DropdownMenuItem(
                      value: MeasurementType.bloodPressure,
                      child: Text('Blood Pressure'),
                    ),
                    DropdownMenuItem(
                      value: MeasurementType.glucose,
                      child: Text('Glucose'),
                    ),
                    DropdownMenuItem(
                      value: MeasurementType.weight,
                      child: Text('Weight'),
                    ),
                    DropdownMenuItem(
                      value: MeasurementType.pulseOximeter,
                      child: Text('Pulse Oximeter'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                    _refreshMeasurements();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(_dateRange == null 
                      ? 'Select Date Range' 
                      : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sync button
          ElevatedButton.icon(
            onPressed: () {
              ref.read(saveMeasurementUseCaseProvider).syncPendingMeasurements();
            },
            icon: const Icon(Icons.sync),
            label: const Text('Sync Pending Measurements'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 16),

          // Measurements list
          Expanded(
            child: measurementsAsync.when(
              data: (measurements) => measurements.isEmpty
                  ? const Center(
                      child: Text('No measurements found.'),
                    )
                  : ListView.builder(
                      itemCount: measurements.length,
                      itemBuilder: (context, index) {
                        final measurement = measurements[index];
                        return HistoryMeasurementCard(measurement: measurement);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${error.toString()}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshMeasurements,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
      _refreshMeasurements();
    }
  }

  void _refreshMeasurements() {
    ref.invalidate(savedMeasurementsProvider);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class HistoryMeasurementCard extends ConsumerWidget {
  final Measurement measurement;

  const HistoryMeasurementCard({
    super.key,
    required this.measurement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getMeasurementIcon(measurement.type),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMeasurementTypeName(measurement.type),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Time: ${_formatDateTime(measurement.timestamp)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      measurement.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                      color: measurement.isSynced ? Colors.green : Colors.orange,
                    ),
                    Text(
                      measurement.isSynced ? 'Synced' : 'Pending',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: measurement.isSynced ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMeasurementValues(context),
            if (!measurement.isSynced && measurement.syncError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Sync Error: ${measurement.syncError}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementValues(BuildContext context) {
    switch (measurement.type) {
      case MeasurementType.bloodPressure:
        final systolic = measurement.values['systolic']?.toString() ?? '0';
        final diastolic = measurement.values['diastolic']?.toString() ?? '0';
        final pulse = measurement.values['pulse']?.toString() ?? '0';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildValueItem(context, 'Systolic', '$systolic mmHg'),
            _buildValueItem(context, 'Diastolic', '$diastolic mmHg'),
            _buildValueItem(context, 'Pulse', '$pulse bpm'),
          ],
        );

      case MeasurementType.glucose:
        final glucoseValue = measurement.values['glucoseValue']?.toString() ?? '0';
        final unit = measurement.values['unit']?.toString() ?? 'mg/dL';

        return Center(
          child: _buildValueItem(context, 'Glucose', '$glucoseValue $unit'),
        );

      case MeasurementType.weight:
        final weight = measurement.values['weight']?.toString() ?? '0';
        final unit = measurement.values['unit']?.toString() ?? 'kg';

        return Center(
          child: _buildValueItem(context, 'Weight', '$weight $unit'),
        );

      case MeasurementType.pulseOximeter:
        final spo2 = measurement.values['spo2']?.toString() ?? '0';
        final pulse = measurement.values['pulse']?.toString() ?? '0';
        final perfusionIndex = measurement.values['perfusionIndex']?.toString();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildValueItem(context, 'SpO2', '$spo2%'),
            _buildValueItem(context, 'Pulse', '$pulse bpm'),
            if (perfusionIndex != null)
              _buildValueItem(context, 'PI', '$perfusionIndex%'),
          ],
        );

    }
  }

  Widget _buildValueItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Measurement'),
        content: const Text('Are you sure you want to delete this measurement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(saveMeasurementUseCaseProvider).deleteMeasurement(measurement.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getMeasurementIcon(MeasurementType type) {
    switch (type) {
      case MeasurementType.bloodPressure:
        return Icons.favorite;
      case MeasurementType.glucose:
        return Icons.opacity;
      case MeasurementType.weight:
        return Icons.monitor_weight;
      case MeasurementType.pulseOximeter:
        return Icons.favorite_border;
    }
  }

  String _getMeasurementTypeName(MeasurementType type) {
    switch (type) {
      case MeasurementType.bloodPressure:
        return 'Blood Pressure';
      case MeasurementType.glucose:
        return 'Glucose';
      case MeasurementType.weight:
        return 'Weight';
      case MeasurementType.pulseOximeter:
        return 'Pulse Oximeter';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }
}
