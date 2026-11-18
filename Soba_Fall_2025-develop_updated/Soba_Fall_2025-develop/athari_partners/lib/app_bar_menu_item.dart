import 'package:flutter/material.dart';

/// AppBarMenuItem represents a single clickable menu item in a custom AppBar.
/// It supports active state (highlighted) and hover effects for desktop/web.
class AppBarMenuItem extends StatefulWidget {
  const AppBarMenuItem({
    super.key,
    required this.label, // Text displayed on the menu item
    required this.isActive, // Whether this menu item is currently active/selected
    required this.onPressed, // Callback when the menu item is clicked
  });

  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  State<AppBarMenuItem> createState() => _AppBarMenuItemState();
}

class _AppBarMenuItemState extends State<AppBarMenuItem> {
  // Tracks whether the mouse is hovering over this menu item
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    //TODO: REMOVE THE EXPANDED ADD IN ACTUAL ROW OR COLUMN
    return Expanded(
      // Expanded allows the menu item to take equal horizontal space
      child: MouseRegion(
        // Detects mouse enter and exit events for hover effect
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          // Makes the menu item clickable
          onTap: widget.onPressed,
          splashColor: Colors.transparent, // Disable splash effect
          highlightColor: Colors.transparent, // Disable highlight
          hoverColor: Colors.transparent, // Disable default hover color
          child: SizedBox(
            height: kToolbarHeight, // Match the AppBar height
            child: Column(
              children: [
                // Main label area
                Expanded(
                  child: Center(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: widget.isActive
                            ? FontWeight.bold
                            : FontWeight.normal, // Bold if active
                        color: widget.isActive ? Colors.black : Colors.grey, // Black if active, grey otherwise
                      ),
                    ),
                  ),
                ),
                // Bottom indicator line
                Container(
                  height: 2, // Height of the underline
                  width: double.infinity, // Full width of the menu item
                  color: widget.isActive
                      ? Colors.blue // Blue underline if active
                      : (_isHovered ? Colors.grey : Colors.transparent), // Grey on hover, invisible otherwise
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
