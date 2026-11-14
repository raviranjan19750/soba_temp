import 'package:flutter/material.dart';

/// A customizable horizontal tab selector widget that displays tabs in a row.
///
/// This widget creates a row of interactive tabs where each tab can contain
/// an icon, title, and optional subtitle. Tabs change appearance based on
/// their active/inactive state and support click interactions.
///
/// Example usage:
/// ```dart
/// HorizontalTabSelector(
///   tabs: [
///     TabItem(title: 'Tab 1', subtitle: 'Description', icon: Icons.star),
///     TabItem(title: 'Tab 2', subtitle: 'Details', icon: Icons.info),
///   ],
///   onTabChanged: (index) => print('Tab $index selected'),
///   initialIndex: 0,
/// )
/// ```
class HorizontalTabSelector extends StatefulWidget {
  /// Creates a horizontal tab selector.
  ///
  /// The [tabs] parameter must not be null and must contain at least one tab.
  const HorizontalTabSelector({
    super.key,
    required this.tabs,
    this.onTabChanged,
    this.initialIndex,
  });

  /// The list of tabs to display in the selector.
  ///
  /// Each [TabItem] defines the content and appearance of an individual tab.
  /// The tabs will be displayed in the order they appear in this list.
  final List<TabItem> tabs;

  /// Callback function that is called when a tab is selected.
  ///
  /// The callback receives the index of the newly selected tab.
  /// If null, tab selections will only update the internal state without
  /// notifying the parent widget.
  final Function(int)? onTabChanged;

  /// The index of the tab that should be initially selected.
  ///
  /// If null, no tab will be selected initially. The value must be a valid
  /// index within the [tabs] list, or null.
  final int? initialIndex;

  @override
  State<HorizontalTabSelector> createState() => _HorizontalTabSelectorState();
}

/// State class for HorizontalTabSelector that manages the active tab index
class _HorizontalTabSelectorState extends State<HorizontalTabSelector> {
  int? _activeIndex; // Tracks the currently active tab index

  @override
  void initState() {
    super.initState();
    // Initialize with the provided initial index or null if none provided
    _activeIndex = widget.initialIndex;
  }

  /// Updates the active tab index and triggers the callback if provided
  void _setActiveIndex(int index) {
    setState(() => _activeIndex = index); // Update UI with new selection
    if (widget.onTabChanged != null) {
      widget.onTabChanged!(index); // Notify parent widget of change
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Generate a tab widget for each item in the tabs list
        for (final (index, tab) in widget.tabs.indexed)
          Expanded(
            child: _TabWidget(
              isActive: index == _activeIndex,
              onSelected: () => _setActiveIndex(index),
              tab: tab,
            ),
          ),
      ],
    );
  }
}

/// Represents a single tab item in the HorizontalTabSelector.
///
/// Each tab item can contain a title, optional subtitle, and optional icon
/// that are displayed in the tab UI.
class TabItem {
  /// Creates a tab item with the given properties.
  const TabItem({
    required this.title,
    this.subtitle,
    this.icon,
  });

  /// The primary text displayed in the tab.
  ///
  /// This is typically the main label for the tab and is displayed in a
  /// bold font. This parameter must not be null.
  final String title;

  /// Additional descriptive text displayed below the title.
  ///
  /// This is optional and can be used to provide more context about the tab.
  /// If null, only the title will be displayed.
  final String? subtitle;

  /// An optional icon displayed to the left of the text content.
  ///
  /// If provided, the icon will be displayed with appropriate coloring
  /// based on the tab's active/inactive state.
  final IconData? icon;
}

/// Private widget that represents an individual tab in the selector.
///
/// This widget handles the visual representation of a single tab including
/// its active state styling and tap interactions.
class _TabWidget extends StatelessWidget {
  const _TabWidget({
    super.key,
    required this.isActive,
    required this.onSelected,
    required this.tab,
  });

  final bool isActive; // Whether this tab is currently selected
  final VoidCallback onSelected; // Callback when tab is tapped
  final TabItem tab; // The tab item data to display

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected, // Handle tap to select this tab
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          // Change background color based on active state
          color: isActive ? Colors.blue.shade50 : Colors.white,
          border: Border.all(
            // Change border color based on active state
            color: isActive ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Display icon if provided
            if (tab.icon != null)
              Icon(
                tab.icon,
                size: 20,
                color: isActive ? Colors.blue : Colors.grey,
              ),
            if (tab.icon != null) const SizedBox(width: 8),
            // Text content column (title and optional subtitle)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tab.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.blue : Colors.black87,
                  ),
                ),
                if (tab.subtitle != null)
                  Text(
                    tab.subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.blue.shade700 : Colors.grey,
                    ),
                  ),
              ],
            ),
            const Spacer(), // Push the arrow icon to the right
            // Show forward arrow only for active tab
            if (isActive)
              const Icon(Icons.arrow_forward, color: Colors.blue, size: 18),
          ],
        ),
      ),
    );
  }
}