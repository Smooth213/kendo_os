import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_app_bar_actions.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_storage_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_tab_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_text_toolbar.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

export 'quick_memo_canvas_painter.dart';
export 'quick_memo_tab_bar.dart';

/// 🥋 クイックメモ全画面（手書き・テキスト両対応＆自動保存）
class QuickMemoScreen extends StatefulWidget {
  final String tournamentId;

  const QuickMemoScreen({super.key, required this.tournamentId});

  static Future<void> show(
    BuildContext context, {
    required String tournamentId,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuickMemoScreen(tournamentId: tournamentId),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<QuickMemoScreen> createState() => _QuickMemoScreenState();
}

class _QuickMemoScreenState extends State<QuickMemoScreen> {
  QuickMemoMode _mode = QuickMemoMode.drawing;

  // 手書き関連
  final List<MemoStroke> _strokes = [];
  final List<MemoStroke> _undoStack = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = AppKendoColors.redAccent;
  double _selectedWidth = 3.5;
  bool _isEraser = false;

  // テキスト関連
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final data = await QuickMemoStorageService.instance.loadMemo(
      widget.tournamentId,
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

  void _onModeChanged(QuickMemoMode mode) {
    setState(() {
      _mode = mode;
    });
    _saveData();
    if (mode == QuickMemoMode.text) {
      _textFocusNode.requestFocus();
    } else {
      _textFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131A24)
          : const Color(0xFFF9FAFB),
      appBar: AppHeader(
        title: 'クイックメモ',
        actions: [
          QuickMemoAppBarActions(
            mode: _mode,
            hasStrokes: _strokes.isNotEmpty,
            hasUndo: _undoStack.isNotEmpty,
            hasText: _textController.text.isNotEmpty,
            onUndo: _undo,
            onRedo: _redo,
            onInsertTimestamp: _insertTimestamp,
            onCopyText: _copyText,
            onClearAll: _clearAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // モード切り替えタブ（手書き ⇄ テキスト）
          QuickMemoTabBar(
            currentMode: _mode,
            themeColors: themeColors,
            onModeChanged: _onModeChanged,
          ),
          // メインコンテンツ
          Expanded(
            child: Stack(
              children: [
                // 方眼背景
                Positioned.fill(
                  child: CustomPaint(
                    painter: MemoGridBackgroundPainter(
                      isDark: isDark,
                      gridColor: isDark
                          ? AppKendoColors.pureWhite.withValues(alpha: 0.04)
                          : AppKendoColors.pureBlack.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // 手書きモード
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
                      setState(() {
                        _isEraser = !_isEraser;
                      });
                    },
                  ),
                // テキストモード
                if (_mode == QuickMemoMode.text) ...[
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        80, // 下部ツールバーの余白
                      ),
                      child: AppTextField(
                        controller: _textController,
                        focusNode: _textFocusNode,
                        maxLines: null,
                        expands: true,
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          color: themeColors.textColor,
                          height: 1.6,
                        ),
                        hintText: 'ここに試合メモ・連絡事項・確認事項を入力できます...',
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) {
                          setState(() {});
                          _saveData();
                        },
                      ),
                    ),
                  ),
                  // 下部クイックアクションバー（テキスト用: 時刻挿入・コピー・全消去・文字数）
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: MediaQuery.of(context).viewInsets.bottom > 0
                        ? MediaQuery.of(context).viewInsets.bottom +
                              AppSpacing.sm
                        : MediaQuery.of(context).padding.bottom + AppSpacing.md,
                    child: Center(
                      child: QuickMemoTextToolbar(
                        themeColors: themeColors,
                        isDark: isDark,
                        charCount: _textController.text.length,
                        onInsertTimestamp: _insertTimestamp,
                        onCopy: _textController.text.isNotEmpty
                            ? _copyText
                            : null,
                        onClear: _textController.text.isNotEmpty
                            ? _clearAll
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
