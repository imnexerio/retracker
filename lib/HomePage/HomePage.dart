import 'package:flutter/material.dart';
import '../Utils/FetchRecord.dart';
import 'DailyProgressCard.dart';
import 'ProgressCalendarCard.dart';
import 'SubjectDistributionCard.dart';
import 'WeeklyProgressCard.dart';
import 'calculation_utils.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final FetchRecord _recordService = FetchRecord();
  Stream<Map<String, dynamic>>? _recordsStream;

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
                'Total Lectures',
                calculateTotalLectures(allRecords).toString(),
                const Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Revisions',
                calculateTotalRevisions(allRecords).toString(),
                const Color(0xFFDA5656),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Percentage Completion",
                "${calculatePercentageCompletion(allRecords).toStringAsFixed(1)}%",
                getCompletionColor(calculatePercentageCompletion(allRecords)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Missed Revision",
                calculateMissedRevisions(allRecords).toString(),
                const Color(0xFF008CC4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Single row layout for larger screens
  Widget _buildSingleRowStatsGrid(List<Map<String, dynamic>> allRecords) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Lectures',
            calculateTotalLectures(allRecords).toString(),
            const Color(0xFF6C63FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Revisions',
            calculateTotalRevisions(allRecords).toString(),
            const Color(0xFFDA5656),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Percentage Completion",
            "${calculatePercentageCompletion(allRecords).toStringAsFixed(1)}%",
            getCompletionColor(calculatePercentageCompletion(allRecords)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Missed Revision",
            calculateMissedRevisions(allRecords).toString(),
            const Color(0xFF008CC4),
          ),
        ),
      ],
    );
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


  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
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
    );
  }
}