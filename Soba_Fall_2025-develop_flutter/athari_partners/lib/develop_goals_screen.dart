import 'package:flutter/material.dart';
import 'goals_tab.dart';
import 'initiatives_tab.dart';

/// Main screen for developing goals and initiatives for strategic focus areas.
///
/// This screen provides a tabbed interface with two main sections:
/// - Goals: For defining strategic goals for each focus area
/// - Initiatives: For defining specific initiatives to achieve each goal
///
/// The screen manages shared state like selected focus area and input controller.
class DevelopGoalsScreen extends StatefulWidget {
  const DevelopGoalsScreen({super.key});

  @override
  State<DevelopGoalsScreen> createState() => _DevelopGoalsScreenState();
}

class _DevelopGoalsScreenState extends State<DevelopGoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Currently selected focus area in the dropdown
  String? selectedFocusArea = 'Market Expansion';

  /// Controller for the goal input text field
  final TextEditingController _goalController = TextEditingController();

  /// Available strategic focus areas for goal planning
  final List<String> focusAreas = [
    'Market Expansion',
    'Customer Retention',
    'Product Innovation',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main title
                const Text(
                  "Develop Goals & Initiatives for Each Focus Area",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Instructional text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'For each strategic focus area, define specific goals and the key initiatives required to achieve them. Use insights from executive interviews and employee surveys to inform your planning.',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab navigation
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: Colors.blue,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: "Goals"),
                    Tab(text: "Initiatives"),
                  ],
                ),
              ],
            ),
          ),

          // Tab content area - Fixed height container
          Container(
            height: 500, // Adjusted height for Goals tab
            child: TabBarView(
              controller: _tabController,
              children: [
                // Goals Tab (Firestore version)
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GoalsTab(
                    selectedFocusArea: selectedFocusArea,
                    focusAreas: focusAreas,
                    goalController: _goalController,
                    onFocusAreaChanged: (value) =>
                        setState(() => selectedFocusArea = value),
                  ),
                ),

                // Initiatives Tab (still uses local state for now)
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: InitiativesTab(),
                ),
              ],
            ),
          ),

          // Save button section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(onPressed: () {}, child: const Text('Back')),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B7BEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save & Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
