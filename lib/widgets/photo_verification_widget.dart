import 'package:flutter/material.dart';
import '../config/theme.dart';

class PhotoVerificationWidget extends StatelessWidget {
  final bool? isVerified;
  final String? reason;
  final String? funFact;

  const PhotoVerificationWidget({
    super.key,
    this.isVerified,
    this.reason,
    this.funFact,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Implement verification result display with animations
    if (isVerified == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Icon(
          isVerified! ? Icons.check_circle : Icons.cancel,
          size: 64,
          color: isVerified! ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 8),
        Text(
          isVerified! ? 'Verified!' : 'Not Verified',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (reason != null) ...[
          const SizedBox(height: 8),
          Text(reason!, textAlign: TextAlign.center),
        ],
        if (funFact != null) ...[
          const SizedBox(height: 8),
          Text(funFact!, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }
}
