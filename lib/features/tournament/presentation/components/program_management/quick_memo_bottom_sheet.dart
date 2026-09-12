import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_screen.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_storage_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_text_view.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 🥋 クイックメモ ボトムシート（ドックから即座に起動＆全画面拡大対応）
class QuickMemoBottomSheet extends StatefulWidget {
  final String tournamentId;

  const QuickMemoBottomSheet({super.key, required this.tournamentId});

  static Future<void> show(
    BuildContext context, {
    required String tournamentId,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: AppKendoColors.transparent,
      builder: (context) => QuickMemoBottomSheet(tournamentId: tournamentId),
    );
  }

  @override
  State<QuickMemoBottomSheet> createState() => _QuickMemoBottomSheetState();
}

class _QuickMemoBottomSheetState extends State<QuickMemoBottomSheet> {
  QuickMemoMode _mode = QuickMemoMode.drawing;

  final List<MemoStroke> _strokes = [];
  final List<MemoStroke> _undoStack = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = AppKendoColors.redAccent;
  double _selectedWidth = 3.5;
  bool _isEraser = false;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  StreamSubscription<QuickMemoData>? _memoSubscription;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _subscribeCloudUpdates();
  }

  @override
  void didUpdateWidget(QuickMemoBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournamentId != widget.tournamentId) {
      _saveData();
      _memoSubscription?.cancel();
      _loadSavedData();
      _subscribeCloudUpdates();
    }
  }

  Future<void> _loadSavedData() async {
    final data = await QuickMemoStorageService.instance.loadMemo(
      widget.tournamentId,
      forceCloudRefresh: true,
    );
    if (!mounted) return;
    setState(() {
      _strokes.clear();
      _strokes.addAll(data.strokes);
      _textController.text = data.text;
      if (data.modeName == 'text') {
        _mode = QuickMemoMode.text;
      }
    });
  }

  void _subscribeCloudUpdates() {
    _memoSubscription = QuickMemoStorageService.instance
        .watchMemo(widget.tournamentId)
        .listen((cloudData) {
          if (!mounted) return;
          // 操作中でない場合に最新データをUIへ安全にマージ
          if (!_textFocusNode.hasFocus && _currentPoints.isEmpty) {
            if (_textController.text != cloudData.text ||
                _strokes.length != cloudData.strokes.length) {
              setState(() {
                _strokes.clear();
                _strokes.addAll(cloudData.strokes);
                _textController.text = cloudData.text;
                if (cloudData.modeName == 'text') {
                  _mode = QuickMemoMode.text;
                }
              });
            }
          }
        });
  }

  void _saveData() {
    QuickMemoStorageService.instance.saveMemo(
      tournamentId: widget.tournamentId,
      text: _textController.text,
      strokes: _strokes,
      modeName: _mode.name,
    );
  }

  @override
  void dispose() {
    _memoSubscription?.cancel();
    _saveData();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    final localPos = details.localPosition;
    if (_isEraser) {
      _eraseNear(localPos);
      return;
    }
    setState(() {
      _currentPoints = [localPos];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final localPos = details.localPosition;
    if (_isEraser) {
      _eraseNear(localPos);
      return;
    }
    setState(() {
      _currentPoints.add(localPos);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isEraser) return;
    if (_currentPoints.isNotEmpty) {
      setState(() {
        _strokes.add(
          MemoStroke(
            points: List.from(_currentPoints),
            color: _selectedColor,
            strokeWidth: _selectedWidth,
          ),
        );
        _currentPoints = [];
        _undoStack.clear();
      });
      _saveData();
    }
  }

  void _eraseNear(Offset pos) {
    const double threshold = 20.0;
    final beforeCount = _strokes.length;
    _strokes.removeWhere((stroke) {
      return stroke.points.any((pt) => (pt - pos).distance <= threshold);
    });
    if (_strokes.length != beforeCount) {
      AppHaptics.light();
      setState(() {});
      _saveData();
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      AppHaptics.selection();
      setState(() {
        _undoStack.add(_strokes.removeLast());
      });
      _saveData();
    }
  }

  void _redo() {
    if (_undoStack.isNotEmpty) {
      AppHaptics.selection();
      setState(() {
        _strokes.add(_undoStack.removeLast());
      });
      _saveData();
    }
  }

  void _insertTimestamp() {
    AppHaptics.selection();
    final now = DateFormat('HH:mm').format(DateTime.now());
    final currentText = _textController.text;
    final cursor = _textController.selection.baseOffset;
    final insertText = '[$now] ';
    if (cursor >= 0 && cursor <= currentText.length) {
      final newText = currentText.replaceRange(cursor, cursor, insertText);
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + insertText.length),
      );
    } else {
      _textController.text = '$currentText$insertText';
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
    }
    setState(() {});
    _saveData();
    _textFocusNode.requestFocus();
  }

  void _copyText() {
    if (_textController.text.trim().isEmpty) return;
    AppHaptics.medium();
    Clipboard.setData(ClipboardData(text: _textController.text));
    AppSnackBar.showSuccess(context, 'テキストをクリップボードにコピーしました');
  }

  void _clearAll() {
    final isText = _mode == QuickMemoMode.text;
    if (isText && _textController.text.isEmpty) return;
    if (!isText && _strokes.isEmpty) return;

    AppHaptics.medium();
    showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: isText ? 'テキストを消去' : '手書きを消去',
        content: Text(isText ? '入力中のテキストメモをすべて消去しますか？' : '手書きメモをすべて消去しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppKendoColors.redAccent,
            ),
            child: const Text('消去'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        setState(() {
          if (isText) {
            _textController.clear();
          } else {
            _strokes.clear();
            _undoStack.clear();
          }
        });
        _saveData();
      }
    });
  }

  void _openFullScreen() {
    _saveData();
    if (FloatingDockSheetManager.isOpen) {
      FloatingDockSheetManager.close(immediate: true);
    } else {
      Navigator.of(context).pop();
    }
    QuickMemoScreen.show(context, tournamentId: widget.tournamentId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return DockDraggableSheet(
      backgroundColor: isDark
          ? const Color(0xFF131A24)
          : const Color(0xFFF9FAFB),
      builder: (context, scrollController) => Column(
        children: [
          // 統一ヘッダー（ドラッグハンドル、タイトル、全画面ボタン、閉じるボタン）
          DockBottomSheetHeader(
            title: 'クイックメモ',
            icon: Icons.brush_rounded,
            iconColor: AppKendoColors.pink,
            onFullScreen: _openFullScreen,
            extraActions: [
              IconButton(
                icon: const Icon(Icons.sync_rounded, size: 18),
                tooltip: 'クラウドから最新メモを同期',
                color: themeColors.textColor,
                onPressed: () async {
                  AppHaptics.selection();
                  await _loadSavedData();
                  if (context.mounted) {
                    final strokeCount = _strokes.length;
                    final textLength = _textController.text.trim().length;
                    final detail = strokeCount > 0 && textLength > 0
                        ? '（手書き: $strokeCount本、文字: $textLength字）'
                        : strokeCount > 0
                        ? '（手書き: $strokeCount本）'
                        : textLength > 0
                        ? '（文字: $textLength字）'
                        : '（メモは空です）';
                    AppSnackBar.showSuccess(context, '最新のメモを同期しました $detail');
                  }
                },
              ),
              if (_mode == QuickMemoMode.drawing) ...[
                IconButton(
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  tooltip: '1つ戻す',
                  color: themeColors.textColor,
                  onPressed: _strokes.isNotEmpty ? _undo : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded, size: 18),
                  tooltip: 'やり直す',
                  color: themeColors.textColor,
                  onPressed: _undoStack.isNotEmpty ? _redo : null,
                ),
              ],
            ],
          ),
          // モード切り替えタブ
          QuickMemoTabBar(
            currentMode: _mode,
            themeColors: themeColors,
            onModeChanged: (mode) {
              setState(() => _mode = mode);
              _saveData();
              if (mode == QuickMemoMode.text) {
                _textFocusNode.requestFocus();
              } else {
                _textFocusNode.unfocus();
              }
            },
          ),
          // メモ用紙コンテンツ
          Expanded(
            child: Stack(
              children: [
                if (_mode == QuickMemoMode.drawing)
                  QuickMemoDrawingCanvas(
                    strokes: _strokes,
                    currentPoints: _currentPoints,
                    selectedColor: _selectedColor,
                    selectedWidth: _selectedWidth,
                    isEraser: _isEraser,
                    isDark: isDark,
                    themeColors: themeColors,
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onColorChanged: (color) {
                      setState(() {
                        _selectedColor = color;
                        _isEraser = false;
                      });
                    },
                    onToggleWidth: () {
                      setState(() {
                        _isEraser = false;
                        if (_selectedWidth == 2.0) {
                          _selectedWidth = 4.0;
                        } else if (_selectedWidth == 4.0) {
                          _selectedWidth = 8.0;
                        } else {
                          _selectedWidth = 2.0;
                        }
                      });
                    },
                    onToggleEraser: () {
                      setState(() => _isEraser = !_isEraser);
                    },
                  ),
                if (_mode == QuickMemoMode.text)
                  QuickMemoTextView(
                    controller: _textController,
                    focusNode: _textFocusNode,
                    themeColors: themeColors,
                    isDark: isDark,
                    onChanged: _saveData,
                    onInsertTimestamp: _insertTimestamp,
                    onCopy: _copyText,
                    onClear: _clearAll,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
