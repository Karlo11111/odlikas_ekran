import 'package:flutter/material.dart';

// klasa koja drzi widget za prikaz dana u kalendaru
class DayCell extends StatelessWidget {
  final DateTime date;
  final bool isWithinCurrentMonth;
  final bool isHoliday, isTest;
  final VoidCallback? onTap;

  const DayCell({
    required this.date,
    required this.isWithinCurrentMonth,
    required this.isTest,
    required this.onTap,
    required this.isHoliday,
  });

  @override
  Widget build(BuildContext context) {
    DateTime today = DateTime.now();
    bool isToday = today.year == date.year &&
        today.month == date.month &&
        today.day == date.day;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 10,
        margin: EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: isTest
              ? const Color.fromRGBO(236, 145, 32, 1)
              : (isHoliday
                  ? const Color.fromRGBO(23, 148, 210, 1)
                  : Colors.white),
          border: Border.all(
            color: isToday
                ? Colors.black // Highlight today's date with a black border
                : (isHoliday || isTest
                    ? Colors.white
                    : Color.fromRGBO(113, 113, 113, 0.2)),
            width:
                isToday ? 2.5 : 1, // Make today's border thicker for emphasis
          ),
          borderRadius: BorderRadius.circular(5), // Optional: round the corners
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "${date.day}",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isHoliday || isTest
                  ? Colors.white
                  : (isWithinCurrentMonth
                      ? Colors.black
                      : Color.fromRGBO(113, 113, 113, 1)),
            ),
          ),
        ),
      ),
    );
  }
}
