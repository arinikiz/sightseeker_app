import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/participant.dart';

class ParticipantTile extends StatelessWidget {
  final Participant participant;

  const ParticipantTile({super.key, required this.participant});

  Color _statusColor() {
    switch (participant.status) {
      case 'completed':
        return Colors.green;
      case 'going':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (participant.status) {
      case 'completed':
        return 'Completed';
      case 'going':
        return 'Going';
      default:
        return participant.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.secondaryColor.withAlpha(30),
        backgroundImage: participant.avatarUrl != null &&
                participant.avatarUrl!.isNotEmpty
            ? CachedNetworkImageProvider(participant.avatarUrl!)
            : null,
        child: participant.avatarUrl == null || participant.avatarUrl!.isEmpty
            ? Text(
                participant.name.isNotEmpty
                    ? participant.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        participant.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: participant.plannedTime != null
          ? Text('Plans to visit: ${participant.plannedTime}')
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor().withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _statusLabel(),
          style: TextStyle(
            fontSize: 12,
            color: _statusColor(),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
