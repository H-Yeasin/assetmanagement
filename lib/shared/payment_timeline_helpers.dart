import 'package:flutter/material.dart';

const int rollingTimelineFutureMonths = 12;

const String timelineInfoNoteLabel =
    'Future payments are shown for the next 12 months and update automatically.';
const String upcomingPaymentsInfoNoteLabel =
    'Upcoming payments update automatically as your loan, housing, and insurance records change.';
const String upcomingRemindersInfoNoteLabel =
    'Upcoming reminders update automatically as your scheduled reminders change.';
const String upcomingActionsInfoNoteLabel =
    'Upcoming actions update automatically as your payment and renewal schedules change.';

class TimelineInfoNote extends StatelessWidget {
  final String label;

  const TimelineInfoNote({
    super.key,
    this.label = timelineInfoNoteLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
