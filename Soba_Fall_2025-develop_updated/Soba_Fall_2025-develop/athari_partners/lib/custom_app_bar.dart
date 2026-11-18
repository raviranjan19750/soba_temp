import 'package:flutter/material.dart';

/// CustomAppBar is a reusable AppBar widget with:
/// - Optional left icon (usually logo)
/// - Center area for middle widgets (like menu items)
/// - A "Need Help" button on the right
/// - Customizable background color and elevation
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.middleWidgets = const [], // Widgets to display in the center
    this.leftIcon, // Optional left-side icon
    this.helpButtonText = 'Need Help', // Text for the help button
    this.onHelpPressed, // Callback when help button is pressed
    this.backgroundColor = Colors.white, // AppBar background color
    this.elevation = 2, // Shadow/elevation
  });

  final List<Widget> middleWidgets;
  final Widget? leftIcon;
  final String helpButtonText;
  final VoidCallback? onHelpPressed;
  final Color backgroundColor;
  final double elevation;

  /// Required by PreferredSizeWidget
  /// Sets AppBar height to the default toolbar height
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor, // Set the background color
      elevation: elevation, // AppBar shadow
      shadowColor: Colors.black.withOpacity(0.2), // Shadow color with opacity
      child: AppBar(
        backgroundColor: Colors.transparent, // Transparent to show Material's color
        elevation: 0, // No default AppBar shadow
        leading: null, // No default leading widget
        title: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200), // Max width for large screens
            padding: const EdgeInsets.symmetric(horizontal: 24), // Horizontal padding
            child: Row(
              children: [
                // Left icon (optional)
                if (leftIcon != null)
                  SizedBox(height: kToolbarHeight * 0.8, child: leftIcon),
                const SizedBox(width: 16), // Spacing between icon and middle widgets

                // Middle widgets (menu items, etc.)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: middleWidgets,
                  ),
                ),

                // Help button on the right
                ElevatedButton(
                  onPressed: onHelpPressed ??
                          () {
                        // Default behavior if no callback is provided
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Help button pressed')),
                        );
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6), // Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Padding inside button
                  ),
                  child: Text(
                    helpButtonText, // Button label
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600, // Semi-bold text
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: null, // No extra actions on the right; handled by help button
      ),
    );
  }
}
