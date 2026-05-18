import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/domain/entities/tournament_model.dart';
import 'package:kendo_os/infrastructure/repository/tournament_repository.dart';
import '../../providers/permission_provider.dart';

class TournamentHeaderCard extends ConsumerWidget {
  final TournamentModel tournament;

  const TournamentHeaderCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade700;
    final iconBgColor = isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade50;
    final popupIconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final noteBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor, width: isDark ? 0.5 : 1.0)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(tournament.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                ),
                if (ref.watch(permissionProvider).canManageTournament)
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: popupIconColor, size: 28),
                    onPressed: () => _showTournamentMenuBottomSheet(context, ref, tournament, cardColor, textColor, subTextColor, borderColor),
                  ),
              ],
            ),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: borderColor)),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade500, size: 16),
                const SizedBox(width: 8),
                Text(DateFormat('yyyy年MM月dd日').format(tournament.date), style: TextStyle(color: subTextColor, fontSize: 13)),
                const SizedBox(width: 16),
                Icon(Icons.location_on, color: Colors.grey.shade500, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(tournament.venue, style: TextStyle(color: subTextColor, fontSize: 13), overflow: TextOverflow.ellipsis)),
              ],
            ),
            if (tournament.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: noteBgColor, borderRadius: BorderRadius.circular(8)),
                child: Text(tournament.notes, style: TextStyle(color: textColor, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTournamentMenuBottomSheet(BuildContext context, WidgetRef ref, TournamentModel tournament, Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: 16, bottom: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.indigo.withValues(alpha: 0.1), child: const Icon(Icons.edit, color: Colors.indigo)),
              title: Text('大会情報の編集', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              subtitle: const Text('大会名や会場、日付を変更します', style: TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () {
                Navigator.pop(ctx);
                _openEditTournamentDialog(context, ref, tournament, cardColor, textColor, subTextColor, borderColor);
              },
            ),
            if (ref.read(permissionProvider).canDeleteData) ...[
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: borderColor)),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.red.withValues(alpha: 0.1), child: const Icon(Icons.delete, color: Colors.red)),
                title: const Text('この大会を削除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                subtitle: const Text('関連するすべての試合も完全に削除されます', style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteTournament(context, ref, tournament, cardColor, textColor);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openEditTournamentDialog(BuildContext context, WidgetRef ref, TournamentModel tournament, Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    final nameController = TextEditingController(text: tournament.name);
    final venueController = TextEditingController(text: tournament.venue);
    final notesController = TextEditingController(text: tournament.notes);
    DateTime selectedDate = tournament.date;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( 
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: cardColor,
            title: Text('大会情報の編集', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: SingleChildScrollView( 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: '大会名', labelStyle: TextStyle(color: subTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)))),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Colors.indigo, onPrimary: Colors.white, onSurface: isDark ? Colors.white : Colors.black), dialogTheme: DialogThemeData(backgroundColor: cardColor)),
                          child: child!,
                        ),
                      );
                      if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: '開催年月日', labelStyle: TextStyle(color: subTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('yyyy年MM月dd日').format(selectedDate), style: TextStyle(color: textColor)),
                          Icon(Icons.calendar_today, size: 20, color: isDark ? Colors.indigo.shade400 : Colors.indigo.shade600),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: venueController, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: '会場・住所', labelStyle: TextStyle(color: subTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)))),
                  const SizedBox(height: 12),
                  TextField(controller: notesController, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: '大会メモ（任意）', labelStyle: TextStyle(color: subTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor))), maxLines: 3),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade600, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  await ref.read(tournamentRepositoryProvider).updateTournamentDetails(
                    tournament.id, name: nameController.text, venue: venueController.text, notes: notesController.text, date: selectedDate,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _confirmDeleteTournament(BuildContext context, WidgetRef ref, TournamentModel tournament, Color cardColor, Color textColor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('大会の削除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
        content: Text('この大会を削除しますか？\n（取り消しはできません）', style: TextStyle(color: textColor, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('削除する', style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(tournamentRepositoryProvider).deleteTournament(tournament.id);
      if (context.mounted) context.go('/');
    }
  }
}