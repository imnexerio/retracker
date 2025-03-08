import 'package:flutter/material.dart';
import '../Utils/subject_utils.dart';
import 'CodeBar.dart';

class SubjectsBar extends StatefulWidget {
  @override
  _SubjectsBarState createState() => _SubjectsBarState();
}

class _SubjectsBarState extends State<SubjectsBar> with SingleTickerProviderStateMixin {
  String? _selectedSubject;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Stream subscription
  Stream<Map<String, dynamic>>? _subjectsStream;
  Map<String, dynamic>? _currentData;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Initialize with current data if available
    _initializeSelectedSubject();

    // Subscribe to the stream
    _subjectsStream = getSubjectsStream();

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeSelectedSubject() async {
    try {
      final data = await fetchSubjectsAndCodes();
      if (data['subjects'].isNotEmpty) {
        setState(() {
          _selectedSubject = data['subjects'].first;
          _currentData = data;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Map<String, dynamic>>(
        // Use the stream instead of future
        stream: _subjectsStream,
        initialData: _currentData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 3,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No records found try adding some',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!['subjects'].isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No subjects found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final subjects = snapshot.data!['subjects'];

          // If we have data but no selected subject, select the first one
          if (_selectedSubject == null && subjects.isNotEmpty) {
            _selectedSubject = subjects.first;
          }

          // If selected subject no longer exists in the updated list
          if (_selectedSubject != null && !subjects.contains(_selectedSubject)) {
            if (subjects.isNotEmpty) {
              _selectedSubject = subjects.first;
            } else {
              _selectedSubject = null;
            }
          }

          return Column(
            children: [
              if (_selectedSubject != null)
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: CodeBar(selectedSubject: _selectedSubject!),
                  ),
                ),
              Container(
                height: 70.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final isSelected = _selectedSubject == subject;

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        margin: EdgeInsets.symmetric(horizontal: 6.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSubject = subject;
                              });
                              _controller.reset();
                              _controller.forward();
                            },
                            borderRadius: BorderRadius.circular(15.0),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 12.0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(15.0),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                                    : null,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.book,
                                      size: 18,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      subject,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : Theme.of(context).colorScheme.onSurface,
                                        fontSize: 16,
                                        fontWeight:
                                        isSelected ? FontWeight.w600 : FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}