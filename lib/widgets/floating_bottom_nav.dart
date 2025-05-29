import 'package:flutter/material.dart';

class FloatingBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const FloatingBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          // More distinct blue color with stronger opacity
          color: const Color(0xFF1E88E5).withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF1565C0).withOpacity(0.8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E88E5).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.location_on, 1),
            _buildNavItem(Icons.notifications, 2),
            _buildNavItem(Icons.person, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isSelected ? 28 : 24,
        ),
      ),
    );
  }
}