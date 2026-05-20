import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/presentation/operate/providers/match_command_provider.dart';

class CorruptedMatchBanner extends ConsumerWidget {
  final String matchId;

  const CorruptedMatchBanner({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade900,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.yellow, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'この試合データは破損している可能性があります',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(matchCommandProvider).rebuildMatchSnapshot(matchId);
            },
            icon: const Icon(Icons.build, size: 16),
            label: const Text('自動復旧 (Replay)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 30),
            ),
          ),
        ],
      ),
    );
  }
}