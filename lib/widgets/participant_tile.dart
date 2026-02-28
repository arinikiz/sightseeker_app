import 'package:flutter/material.dart';
import '../models/participant.dart';

class ParticipantTile extends StatelessWidget {
  final Participant participant;

  const ParticipantTile({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement participant tile with avatar, name, status, planned time
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(participant.name),
      subtitle: Text(participant.status),
      trailing: participant.plannedTime != null
          ? Chip(label: Text(participant.plannedTime!))
          : null,
    );
  }
}
