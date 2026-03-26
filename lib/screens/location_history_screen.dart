import 'package:flutter/material.dart';
import '../models/oltrap.dart';
import '../services/database_helper.dart';
import '../theme/neumorphism_theme.dart';

class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({super.key});

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  Map<String, List<OLTrap>> _locationGroups = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final oltraps = await DatabaseHelper.instance.getAllOLTraps();

      final Map<String, List<OLTrap>> grouped = {};
      for (final oltrap in oltraps) {
        final location = oltrap.locationName ?? 'Unassigned';
        if (!grouped.containsKey(location)) {
          grouped[location] = [];
        }
        grouped[location]!.add(oltrap);
      }

      setState(() {
        _locationGroups = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _showLocationDetails(String locationName, List<OLTrap> oltraps) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationDetailScreen(
          locationName: locationName,
          oltraps: oltraps,
          onRefresh: _loadData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location History'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locationGroups.isEmpty
          ? RefreshIndicator(
              onRefresh: _loadData,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 64,
                      color: AppTheme.secondaryTextColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No locations found',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start scanning QR codes to create locations',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _locationGroups.length,
                itemBuilder: (context, index) {
                  final locationName = _locationGroups.keys.elementAt(index);
                  final oltraps = _locationGroups[locationName]!;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        locationName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '${oltraps.length} OLTrap${oltraps.length == 1 ? '' : 's'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Menu button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: PopupMenuButton(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey.shade700,
                                      size: 20,
                                    ),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.visibility,
                                              color: Colors.grey.shade700,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text('View Details'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'view':
                                          _showLocationDetails(
                                            locationName,
                                            oltraps,
                                          );
                                          break;
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Statistics row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.location_on,
                                    label: 'Deployed',
                                    value:
                                        '${oltraps.where((t) => t.status == OLTrapStatus.deployed).length}',
                                    color: Colors.red.shade600,
                                    backgroundColor: Colors.red.shade50,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.location_on,
                                    label: 'Harvested',
                                    value:
                                        '${oltraps.where((t) => t.status == OLTrapStatus.harvested).length}',
                                    color: Colors.orange.shade600,
                                    backgroundColor: Colors.orange.shade50,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Harvested details row
                            if (oltraps.any((t) => t.status == OLTrapStatus.harvested))
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: Icons.help_outline,
                                      label: 'Missing',
                                      value:
                                          '${oltraps.where((t) => t.status == OLTrapStatus.harvested && t.isMissing).length}',
                                      color: Colors.red.shade600,
                                      backgroundColor: Colors.red.shade50,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: Icons.warning,
                                      label: 'Damaged',
                                      value:
                                          '${oltraps.where((t) => t.status == OLTrapStatus.harvested && t.isDamaged).length}',
                                      color: Colors.brown.shade600,
                                      backgroundColor: Colors.brown.shade50,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),
                            // Recent OLTraps section
                            Text(
                              'Recent OLTraps',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: AppTheme.secondaryTextColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: oltraps.take(3).map((oltrap) {
                                      return Chip(
                                        label: Text(
                                          oltrap.qrCodeData.length > 12
                                              ? '${oltrap.qrCodeData.substring(0, 12)}...'
                                              : oltrap.qrCodeData,
                                        ),
                                        backgroundColor:
                                            oltrap.status ==
                                                OLTrapStatus.deployed
                                            ? Colors.red.shade100
                                            : Colors.orange.shade100,
                                        deleteIcon: null,
                                      );
                                    }).toList(),
                                  ),
                                ),
                                if (oltraps.length > 3)
                                  Text(
                                    '+${oltraps.length - 3} more',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.secondaryTextColor,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // View all button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _showLocationDetails(locationName, oltraps),
                                icon: const Icon(Icons.list_alt),
                                label: const Text('View All OLTraps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

Widget _buildStatCard({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
  required Color backgroundColor,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2), width: 1),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class LocationDetailScreen extends StatefulWidget {
  final String locationName;
  final List<OLTrap> oltraps;
  final VoidCallback onRefresh;

  const LocationDetailScreen({
    super.key,
    required this.locationName,
    required this.oltraps,
    required this.onRefresh,
  });

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.location_on, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.locationName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [],
      ),
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Statistics header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailStatCard(
                        icon: Icons.location_on,
                        label: 'Deployed',
                        value:
                            '${widget.oltraps.where((t) => t.status == OLTrapStatus.deployed).length}',
                        color: Colors.red.shade600,
                        backgroundColor: Colors.red.shade50,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailStatCard(
                        icon: Icons.location_on,
                        label: 'Harvested',
                        value:
                            '${widget.oltraps.where((t) => t.status == OLTrapStatus.harvested).length}',
                        color: Colors.orange.shade600,
                        backgroundColor: Colors.orange.shade50,
                      ),
                    ),
                  ],
                ),
                if (widget.oltraps.any((t) => t.status == OLTrapStatus.harvested))
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailStatCard(
                              icon: Icons.help_outline,
                              label: 'Missing',
                              value:
                                  '${widget.oltraps.where((t) => t.status == OLTrapStatus.harvested && t.isMissing).length}',
                              color: Colors.red.shade600,
                              backgroundColor: Colors.red.shade50,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailStatCard(
                              icon: Icons.warning,
                              label: 'Damaged',
                              value:
                                  '${widget.oltraps.where((t) => t.status == OLTrapStatus.harvested && t.isDamaged).length}',
                              color: Colors.brown.shade600,
                              backgroundColor: Colors.brown.shade50,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // List header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'All OLTraps (${widget.oltraps.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // OLTraps list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.oltraps.length,
              itemBuilder: (context, index) {
                final oltrap = widget.oltraps[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with status
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: oltrap.status == OLTrapStatus.deployed
                                      ? Colors.red.shade50
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        oltrap.status == OLTrapStatus.deployed
                                        ? Colors.red.shade200
                                        : Colors.orange.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      oltrap.status == OLTrapStatus.deployed
                                          ? Icons.location_on
                                          : Icons.location_on,
                                      color:
                                          oltrap.status == OLTrapStatus.deployed
                                          ? Colors.red.shade700
                                          : Colors.orange.shade700,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      oltrap.status.displayName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            oltrap.status ==
                                                OLTrapStatus.deployed
                                            ? Colors.red.shade700
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(oltrap.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // QR Code section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      color: Colors.grey.shade600,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'QR Code',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  oltrap.qrCodeData,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Details row
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailInfoCard(
                                  icon: Icons.gps_fixed,
                                  label: 'Coordinates',
                                  value:
                                      '${oltrap.location.latitude.toStringAsFixed(6)}, ${oltrap.location.longitude.toStringAsFixed(6)}',
                                  iconColor: Colors.purple.shade600,
                                ),
                              ),
                            ],
                          ),
                          if (oltrap.notes != null && oltrap.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _buildDetailInfoCard(
                                icon: Icons.note_alt,
                                label: 'Notes',
                                value: oltrap.notes!,
                                iconColor: Colors.grey.shade600,
                              ),
                            ),
                          if (oltrap.status == OLTrapStatus.harvested)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  if (oltrap.isMissing)
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.help_outline, color: Colors.red.shade600, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Missing',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.red.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (oltrap.isMissing && oltrap.isDamaged) const SizedBox(width: 8),
                                  if (oltrap.isDamaged)
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.brown.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.brown.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning, color: Colors.brown.shade600, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Damaged',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.brown.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}
