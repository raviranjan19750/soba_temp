import 'package:athari_partners/company_identity_page.dart';
import 'package:athari_partners/strategic_planning_page.dart';
import 'package:athari_partners/year_one_plan_page.dart';
import 'package:athari_partners/landing_page.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'execute_and_monitor_page.dart';

/// Main application screen that serves as the container for different strategic planning sections.
///
/// This screen provides a navigation framework with a custom app bar and displays
/// different content pages based on the user's selection in the navigation menu.
class IndexScreen extends StatefulWidget {
  /// Creates an IndexScreen.
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

/// State for [IndexScreen] that manages the current active page and navigation.
class _IndexScreenState extends State<IndexScreen> {
  /// The currently active page in the main application navigation
  IndexScreenPage _currentPage = IndexScreenPage.companyIdentity;

  // Logout method
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate explicitly to landing page
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AthariLandingPage()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message if logout fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leftIcon: Image.asset('assets/logos/athari_logo.png', height: 100),
        middleWidgets: [
          AppBarMenuItem(
            label: "Company Identity",
            isActive: _currentPage == IndexScreenPage.companyIdentity,
            onPressed: () {
              setState(() {
                _currentPage = IndexScreenPage.companyIdentity;
              });
            },
          ),
          AppBarMenuItem(
            label: "Strategic Planning",
            isActive: _currentPage == IndexScreenPage.strategicPlanning,
            onPressed: () {
              setState(() {
                _currentPage = IndexScreenPage.strategicPlanning;
              });
            },
          ),
          AppBarMenuItem(
            label: "Year 1 Plan",
            isActive: _currentPage == IndexScreenPage.yearOnePlan,
            onPressed: () {
              setState(() {
                _currentPage = IndexScreenPage.yearOnePlan;
              });
            },
          ),
          AppBarMenuItem(
            label: "Execute & Monitor",
            isActive: _currentPage == IndexScreenPage.executeAndMonitor,
            onPressed: () {
              setState(() {
                _currentPage = IndexScreenPage.executeAndMonitor;
              });
            },
          ),
        ],
        onLogoutPressed: _logout, // Use the logout method
        logoutButtonText: 'Log Out', // Change button text
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
        child: SingleChildScrollView(child: _buildPage()),
      ),
    );
  }

  /// Builds the content widget for the currently active page.
  ///
  /// Returns a widget corresponding to the current [_currentPage] value.
  /// Uses a switch expression to determine which page content to display.
  /// Returns a placeholder text for unimplemented pages.
  Widget _buildPage() {
    return switch (_currentPage) {
      IndexScreenPage.companyIdentity => CompanyIdentityPage(),
      IndexScreenPage.strategicPlanning => StrategicPlanningPage(),
      IndexScreenPage.yearOnePlan => YearOnePlanPage(),
      IndexScreenPage.executeAndMonitor => ExecuteAndMonitorPage(),
      _ => Text("Not Implemented"), // Fallback for any unimplemented pages
    };
  }
}

/// Enum representing the different main pages available in the application.
///
/// This enum defines the primary sections of the strategic planning application:
/// - companyIdentity: For defining company brand and identity
/// - strategicPlanning: For high-level strategic planning activities
/// - yearOnePlan: For detailed first-year implementation planning (not yet implemented)
/// - executeAndMonitor: For strategy execution and performance monitoring
enum IndexScreenPage {
  /// Company Identity page for brand and organizational identity definition
  companyIdentity,

  /// Strategic Planning page for high-level strategy development
  strategicPlanning,

  /// Year One Plan page for detailed first-year implementation planning
  yearOnePlan,

  /// Execute & Monitor page for strategy implementation and performance tracking
  executeAndMonitor,
}

/// A custom app bar widget that provides flexible navigation and branding.
///
/// This widget implements [PreferredSizeWidget] to be used as an AppBar replacement
/// with customizable left icon, middle navigation items, and logout button.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a CustomAppBar.
  ///
  /// [middleWidgets]: List of widgets to display in the center (typically navigation items)
  /// [onLogoutPressed]: Callback when logout button is pressed
  /// [onIconPressed]: Callback when left icon is pressed
  /// [leftIcon]: Widget to display on the left (typically a logo)
  /// [logoutButtonText]: Text to display on the logout button
  /// [backgroundColor]: Background color of the app bar
  /// [elevation]: Elevation/shadow of the app bar
  const CustomAppBar({
    super.key,
    this.middleWidgets = const [],
    this.onLogoutPressed,
    this.onIconPressed,
    this.leftIcon,
    this.logoutButtonText = 'Log Out',
    this.backgroundColor = Colors.white,
    this.elevation = 0,
  });

  /// Navigation items displayed in the center of the app bar
  final List<Widget> middleWidgets;

  /// Callback function when logout button is pressed
  final VoidCallback? onLogoutPressed;

  /// Callback function when left icon is pressed
  final VoidCallback? onIconPressed;

  /// Widget displayed on the left side (typically a logo)
  final Widget? leftIcon;

  /// Text displayed on the logout button
  final String logoutButtonText;

  /// Background color of the app bar
  final Color backgroundColor;

  /// Elevation level for shadow effect
  final double elevation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      leading: leftIcon,
      leadingWidth: 100,
      title: middleWidgets.isNotEmpty
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: middleWidgets,
            )
          : null,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextButton(
            onPressed:
                onLogoutPressed ??
                () {
                  // Default logout behavior - show a snackbar when no custom callback provided
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logout button pressed')),
                  );
                },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red, // Red color for logout
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout, size: 16),
                const SizedBox(width: 4),
                Text(
                  logoutButtonText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A navigation menu item widget for use in the custom app bar.
///
/// This widget represents a single navigation item that can be active or inactive
/// and triggers a callback when pressed.
class AppBarMenuItem extends StatelessWidget {
  /// Creates an AppBarMenuItem.
  ///
  /// [label]: The text to display on the menu item
  /// [isActive]: Whether this item is currently active/selected
  /// [onPressed]: Callback function when the item is pressed
  const AppBarMenuItem({
    super.key,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  /// The text label displayed on the menu item
  final String label;

  /// Whether this menu item is currently active/selected
  final bool isActive;

  /// Callback function when the menu item is pressed
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => onPressed(),
      style: TextButton.styleFrom(
        foregroundColor: isActive ? Colors.black : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
