import 'package:flutter/material.dart';
import 'package:retracker/HomePage/revision_calculations.dart';
import '../Utils/FetchRecord.dart';
import '../Utils/FetchTypesUtils.dart';
import 'DailyProgressCard.dart';
import 'ProgressCalendarCard.dart';
import 'SubjectDistributionCard.dart';
import 'WeeklyProgressCard.dart';
import 'calculation_utils.dart';
import 'completion_utils.dart';
import 'lecture_calculations.dart';
import 'missed_calculations.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final FetchRecord _recordService = FetchRecord();
  Stream<Map<String, dynamic>>? _recordsStream;

  // Add these state variables
  String _lectureViewType = 'Total';
  String _revisionViewType = 'Total';
  String _completionViewType = 'Total';
  String _missedViewType = 'Total';
  Map<String, Set<String>> _selectedTrackingTypesMap = {
    'lecture': {},
    'revision': {},
    'completion': {},
    'missed': {},
  };

  // Track custom total values
  int _customTotalLectures = 0; // Default value from your code
  int _customTotalRevisions = 0;
  int _customCompletionTarget = 322;
  int _customMissedRevisions = 0;

  // Add MediaQuery size caching
  Size? _previousSize;

  @override
  bool get wantKeepAlive => true; // Keep state alive when widget is not visible

  @override
  void initState() {
    super.initState();
    _recordService.startRealTimeUpdates();
    _recordsStream = _recordService.recordsStream;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App is in background, pause real-time updates
      _recordService.stopRealTimeUpdates();
    } else if (state == AppLifecycleState.resumed) {
      // App is in foreground again, resume real-time updates
      _recordService.startRealTimeUpdates();
    }
  }

  @override
  void dispose() {
    // Stop listening when the widget is disposed
    _recordService.stopRealTimeUpdates();
    _recordService.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final currentSize = MediaQuery.of(context).size;
    final screenWidth = currentSize.width;

    // Only rebuild the layout if the screen size has changed significantly
    final rebuildLayout = _previousSize == null ||
        (_previousSize!.width != currentSize.width &&
            (_crossesBreakpoint(_previousSize!.width, currentSize.width, 600) ||
                _crossesBreakpoint(_previousSize!.width, currentSize.width, 900)));

    // Update the previous size
    _previousSize = currentSize;

    final horizontalPadding = screenWidth > 600 ? 24.0 : 16.0;
    final cardPadding = screenWidth > 600 ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
          child: StreamBuilder(
            stream: _recordsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return _buildErrorWidget();
              } else if (!snapshot.hasData || snapshot.data!['allRecords']!.isEmpty) {
                return _buildEmptyWidget();
              }

              List<Map<String, dynamic>> allRecords = snapshot.data!['allRecords']!;
              Map<String, int> subjectDistribution = calculateSubjectDistribution(allRecords);

              return CustomScrollView(
                // Use a unique key for CustomScrollView that doesn't depend on data
                // but still preserves scroll position
                key: const PageStorageKey('homeScrollView'),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance Analytics',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Overview Section with responsive grid
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Responsive grid layout for stats - only rebuild if needed
                              rebuildLayout
                                  ? screenWidth > 900
                                  ? _buildSingleRowStatsGrid(allRecords)
                                  : _buildTwoByTwoStatsGrid(allRecords)
                                  : screenWidth > 900
                                  ? _buildSingleRowStatsGrid(allRecords)
                                  : _buildTwoByTwoStatsGrid(allRecords),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Dynamic layout for main sections - only rebuild if needed
                  SliverToBoxAdapter(
                    child: rebuildLayout
                        ? screenWidth > 900
                        ? _buildTwoColumnLayout(allRecords, subjectDistribution, cardPadding)
                        : _buildSingleColumnLayout(allRecords, subjectDistribution, cardPadding)
                        : screenWidth > 900
                        ? _buildTwoColumnLayout(allRecords, subjectDistribution, cardPadding)
                        : _buildSingleColumnLayout(allRecords, subjectDistribution, cardPadding),
                  ),
                ],
              );
            },
          ),
        ),
    );
  }

  // Check if the width crosses any of our breakpoints
  bool _crossesBreakpoint(double oldWidth, double newWidth, double breakpoint) {
    return (oldWidth <= breakpoint && newWidth > breakpoint) ||
        (oldWidth > breakpoint && newWidth <= breakpoint);
  }

  // Error widget - extracted to reduce build method complexity
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red[300],
            ),
          ),
        ],
      ),
    );
  }

  // Empty widget - extracted to reduce build method complexity
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No records yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Two-by-two grid for medium screens
  Widget _buildTwoByTwoStatsGrid(List<Map<String, dynamic>> allRecords) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Lectures',
                _getLectureValue(allRecords, _lectureViewType),
                const Color(0xFF6C63FF),
                _lectureViewType,
                    () => _cycleViewType('lecture'),
                    () => _showCustomizationSheet('lecture'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Revisions',
                _getRevisionValue(allRecords, _revisionViewType),
                const Color(0xFFDA5656),
                _revisionViewType,
                    () => _cycleViewType('revision'),
                    () => _showCustomizationSheet('revision'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Completion",
                _getCompletionValue(allRecords, _completionViewType),
                getCompletionColor(calculatePercentageCompletion(allRecords,_selectedTrackingTypesMap,_customTotalLectures)),
                _completionViewType,
                    () => _cycleViewType('completion'),
                    () => _showCustomizationSheet('completion'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Missed",
                _getMissedValue(allRecords, _missedViewType),
                const Color(0xFF008CC4),
                _missedViewType,
                    () => _cycleViewType('missed'),
                    () => _showCustomizationSheet('missed'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _cycleViewType(String type) {
    setState(() {
      switch (type) {
        case 'lecture':
          _lectureViewType = _getNextViewType(_lectureViewType);
          break;
        case 'revision':
          _revisionViewType = _getNextViewType(_revisionViewType);
          break;
        case 'completion':
          _completionViewType = _getNextViewType(_completionViewType);
          break;
        case 'missed':
          _missedViewType = _getNextViewType(_missedViewType);
          break;
      }
    });
  }

  String _getNextViewType(String currentType) {
    switch (currentType) {
      case 'Total':
        return 'Monthly';
      case 'Monthly':
        return 'Weekly';
      case 'Weekly':
        return 'Daily';
      case 'Daily':
        return 'Total';
      default:
        return 'Total';
    }
  }

  String _getLectureValue(List<Map<String, dynamic>> records, String viewType) {
    switch (viewType) {
      case 'Total':
        return calculateTotalLectures(records,_selectedTrackingTypesMap).toString();
      case 'Monthly':
        return calculateMonthlyLectures(records,_selectedTrackingTypesMap).toString(); // Updated function call
      case 'Weekly':
        return calculateWeeklyLectures(records,_selectedTrackingTypesMap).toString(); // Updated function call
      case 'Daily':
        return calculateDailyLectures(records,_selectedTrackingTypesMap).toString(); // Updated function call
      default:
        return calculateTotalLectures(records,_selectedTrackingTypesMap).toString();
    }
  }

  String _getRevisionValue(List<Map<String, dynamic>> records, String viewType) {
    switch (viewType) {
      case 'Total':
        return calculateTotalRevisions(records,_selectedTrackingTypesMap).toString();
      case 'Monthly':
        return calculateMonthlyRevisions(records,_selectedTrackingTypesMap).toString(); // Updated function call
      case 'Weekly':
        return calculateWeeklyRevisions(records,_selectedTrackingTypesMap).toString(); // Updated function call
      case 'Daily':
        return calculateDailyRevisions(records,_selectedTrackingTypesMap).toString(); // Updated function call
      default:
        return calculateTotalRevisions(records,_selectedTrackingTypesMap).toString();
    }
  }

  String _getCompletionValue(List<Map<String, dynamic>> records, String viewType) {
    switch (viewType) {
      case 'Total':
        return "${calculatePercentageCompletion(records,_selectedTrackingTypesMap,_customTotalLectures).toStringAsFixed(1)}%";
      case 'Monthly':
        return "${calculateMonthlyCompletion(records, _selectedTrackingTypesMap,_customTotalLectures).toStringAsFixed(1)}%";
      case 'Weekly':
        return "${calculateWeeklyCompletion(records, _selectedTrackingTypesMap,_customTotalLectures).toStringAsFixed(1)}%";
      case 'Daily':
        return "${calculateDailyCompletion(records, _selectedTrackingTypesMap,_customTotalLectures).toStringAsFixed(1)}%";
      default:
        return "${calculatePercentageCompletion(records,_selectedTrackingTypesMap,_customTotalLectures).toStringAsFixed(1)}%";
    }
  }

  String _getMissedValue(List<Map<String, dynamic>> records, String viewType) {
    switch (viewType) {
      case 'Total':
        return calculateMissedRevisions(records,_selectedTrackingTypesMap).toString();
      case 'Monthly':
        return calculateMonthlyMissed(records,_selectedTrackingTypesMap).toString();
      case 'Weekly':
        return calculateWeeklyMissed(records,_selectedTrackingTypesMap).toString();
      case 'Daily':
        return calculateDailyMissed(records,_selectedTrackingTypesMap).toString();
      default:
        return calculateMissedRevisions(records,_selectedTrackingTypesMap).toString();
    }
  }



  // Single row layout for larger screens
  Widget _buildSingleRowStatsGrid(List<Map<String, dynamic>> allRecords) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Lectures',
            _getLectureValue(allRecords, _lectureViewType),
            const Color(0xFF6C63FF),
            _lectureViewType,
                () => _cycleViewType('lecture'),
                () => _showCustomizationSheet('lecture'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Revisions',
            _getRevisionValue(allRecords, _revisionViewType),
            const Color(0xFFDA5656),
            _revisionViewType,
                () => _cycleViewType('revision'),
                () => _showCustomizationSheet('revision'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Completion",
            _getCompletionValue(allRecords, _completionViewType),
            getCompletionColor(calculatePercentageCompletion(allRecords,_selectedTrackingTypesMap,_customTotalLectures)),
            _completionViewType,
                () => _cycleViewType('completion'),
                () => _showCustomizationSheet('completion'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Missed",
            _getMissedValue(allRecords, _missedViewType),
            const Color(0xFF008CC4),
            _missedViewType,
                () => _cycleViewType('missed'),
                () => _showCustomizationSheet('missed'),
          ),
        ),
      ],
    );
  }


  Future<void> _showCustomizationSheet(String type) async {
    final trackingTypes = await FetchtrackingTypeUtils.fetchtrackingType();
    final TextEditingController controller = TextEditingController();

    // Set initial controller values
    switch (type) {
      case 'lecture':
        controller.text = _customTotalLectures.toString();
        break;
      case 'revision':
        controller.text = _customTotalRevisions.toString();
        break;
      case 'completion':
        controller.text = _customCompletionTarget.toString();
        break;
      case 'missed':
        controller.text = _customMissedRevisions.toString();
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize ${_getTypeTitle(type)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Show tracking types
              if (trackingTypes.isNotEmpty) ...[
                Text(
                  'Select Tracking Type:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: trackingTypes.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(trackingTypes[index]),
                          selected: _selectedTrackingTypesMap[type]!.contains(trackingTypes[index]),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTrackingTypesMap[type]!.add(trackingTypes[index]);
                              } else {
                                _selectedTrackingTypesMap[type]!.remove(trackingTypes[index]);
                              }
                            });
                            print('Selected for $type: ${_selectedTrackingTypesMap[type]}');
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getTypeTitle(String type) {
    switch (type) {
      case 'lecture':
        return 'Lectures';
      case 'revision':
        return 'Revisions';
      case 'completion':
        return 'Completion Target';
      case 'missed':
        return 'Missed Revisions';
      default:
        return '';
    }
  }

  double calculatePercentageCompletion(List<Map<String, dynamic>> records, Map<String, Set<String>> selectedTrackingTypesMap, int customCompletionTarget) {
    Set<String> selectedCompletionTypes = selectedTrackingTypesMap['completion'] ?? {};
    int completedLectures = records.where((record) =>
      record['details']['date_learnt'] != null &&
      selectedCompletionTypes.contains(record['details']['lecture_type'])
    ).length;
    double percentageCompletion = customCompletionTarget > 0
        ? (completedLectures / customCompletionTarget) * 100
        : 0;
    return percentageCompletion;
  }

  // Two column layout for larger screens
  Widget _buildTwoColumnLayout(
      List<Map<String, dynamic>> allRecords,
      Map<String, int> subjectDistribution,
      double cardPadding) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          flex: 1,
          child: Column(
            children: [
              buildDailyProgressCard(allRecords, cardPadding,context),
              const SizedBox(height: 32),
              buildSubjectDistributionCard(subjectDistribution, cardPadding,context),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Right column
        Expanded(
          flex: 1,
          child: Column(
            children: [
              buildWeeklyProgressCard(allRecords, cardPadding,context),
              const SizedBox(height: 32),
              buildProgressCalendarCard(allRecords, cardPadding,context),
            ],
          ),
        ),
      ],
    );
  }

  // Single column layout for smaller screens
  Widget _buildSingleColumnLayout(
      List<Map<String, dynamic>> allRecords,
      Map<String, int> subjectDistribution,
      double cardPadding) {
    return Column(
      children: [
        buildDailyProgressCard(allRecords, cardPadding,context),
        const SizedBox(height: 24),
        buildWeeklyProgressCard(allRecords, cardPadding,context),
        const SizedBox(height: 24),
        buildProgressCalendarCard(allRecords, cardPadding,context),
        const SizedBox(height: 24),
        buildSubjectDistributionCard(subjectDistribution, cardPadding,context),
      ],
    );
  }


  Widget _buildStatCard(String title, String value, Color color, String viewType, Function() onTap, Function() onLongPress) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  viewType,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}