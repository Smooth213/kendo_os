import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_delete_dialog_helper.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_management_content_views.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_title_preview_dialog.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/utils/image_compressor.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import '../helpers/clipboard_program_helper.dart';
import '../providers/permission_provider.dart';
import '../providers/program_list_provider.dart';
export '../providers/program_list_provider.dart';

class ProgramManagementScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const ProgramManagementScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<ProgramManagementScreen> createState() =>
      _ProgramManagementScreenState();
}

class _ProgramManagementScreenState
    extends ConsumerState<ProgramManagementScreen> {
  bool _isUploading = false;
  bool _isGridView = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedProgramIds = {};
  final int _sessionBuster = DateTime.now().millisecondsSinceEpoch;

  void _startSelection(ProgramModel program) {
    HapticFeedback.heavyImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedProgramIds.add(program.id);
    });
  }

  void _toggleSelection(ProgramModel program) {
    setState(() {
      if (_selectedProgramIds.contains(program.id)) {
        _selectedProgramIds.remove(program.id);
        if (_selectedProgramIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedProgramIds.add(program.id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedProgramIds.clear();
    });
  }

  void _confirmBulkDelete() {
    final allPrograms =
        ref.read(programListProvider(widget.tournamentId)).valueOrNull ?? [];
    ProgramDeleteDialogHelper.confirmBulkDelete(
      context: context,
      ref: ref,
      allPrograms: allPrograms,
      selectedProgramIds: _selectedProgramIds,
      onDeleted: _clearSelection,
    );
  }

  String _getSafeUrl(String url) {
    if (!kIsWeb || url.isEmpty || !url.startsWith('http')) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}_cb=$_sessionBuster';
  }

  void _showPickerMenu() {
    showAppBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'プログラムの追加',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.subhead,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppKendoColors.blue,
                  ),
                  title: const Text('写真ライブラリから選ぶ (複数可)'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUpload(isPhoto: true);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf,
                    color: AppKendoColors.red,
                  ),
                  title: const Text('ファイルから選ぶ (複数可)'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUpload(isPhoto: false);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.content_paste_go,
                    color: AppKendoColors.greenAccent,
                  ),
                  title: const Text('クリップボードから貼り付け'),
                  subtitle: const Text('コピーした画像やURLから追加'),
                  onTap: () {
                    Navigator.pop(context);
                    _pasteAndUpload();
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload({required bool isPhoto}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: isPhoto ? FileType.image : FileType.custom,
        allowedExtensions: isPhoto ? null : ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty || !mounted) return;
      await _confirmAndUploadFiles(result.files);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'ファイル選択エラー: $e');
      }
    }
  }

  Future<void> _pasteAndUpload() async {
    try {
      final helper = ClipboardProgramHelper();
      final platformFile = await helper.getPlatformFileFromClipboard();

      if (!mounted) return;

      if (platformFile == null) {
        AppSnackBar.show(context, 'クリップボードにコピーされた画像またはURLが見つかりませんでした');
        return;
      }

      await _confirmAndUploadFiles([platformFile]);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'クリップボード読込エラー: $e');
      }
    }
  }

  Future<void> _confirmAndUploadFiles(List<PlatformFile> files) async {
    try {
      final dialogResult = await ProgramTitlePreviewDialog.show(
        context: context,
        files: files,
      );

      if (dialogResult == null || !mounted) return;

      final String baseTitle = dialogResult['title'] as String;
      final List<PlatformFile> orderedFiles =
          dialogResult['files'] as List<PlatformFile>;

      setState(() => _isUploading = true);

      final messageNotifier = ValueNotifier<String>('準備中...');
      if (mounted) _showLoadingDialog(messageNotifier);

      final fileCount = orderedFiles.length;
      for (int i = 0; i < fileCount; i++) {
        final platformFile = orderedFiles[i];
        final fileType = platformFile.extension?.toLowerCase() == 'pdf'
            ? 'pdf'
            : 'image';
        final finalTitle = fileCount > 1
            ? '$baseTitle (${i + 1}/$fileCount)'
            : baseTitle;

        messageNotifier.value =
            'アップロード中 (${i + 1}/$fileCount)\n${platformFile.name}';

        if (fileType == 'image') {
          Uint8List? imageBytes;
          if (kIsWeb) {
            imageBytes = platformFile.bytes;
          } else if (platformFile.path != null) {
            imageBytes = await File(platformFile.path!).readAsBytes();
          }

          if (imageBytes != null) {
            final compressedBytes = await ImageCompressor.compress(
              bytes: imageBytes,
            );
            await ref
                .read(programRepositoryProvider)
                .uploadProgram(
                  tournamentId: widget.tournamentId,
                  title: finalTitle,
                  bytes: compressedBytes ?? imageBytes,
                  fileType: fileType,
                  pageCount: 1,
                );
          }
        } else {
          File? fileToUpload;
          Uint8List? pdfBytes = platformFile.bytes;
          if (!kIsWeb && platformFile.path != null) {
            fileToUpload = File(platformFile.path!);
            pdfBytes ??= await fileToUpload.readAsBytes();
          }
          await ref
              .read(programRepositoryProvider)
              .uploadProgram(
                tournamentId: widget.tournamentId,
                title: finalTitle,
                file: fileToUpload,
                bytes: pdfBytes,
                fileType: fileType,
                pageCount: 1,
              );
        }
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        AppSnackBar.showSuccess(context, '$fileCount件のプログラムをアップロードしました');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        AppSnackBar.showError(context, 'エラーが発生しました: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showLoadingDialog(ValueNotifier<String> messageNotifier) {
    showAppDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AppDialog(
            content: ValueListenableBuilder<String>(
              valueListenable: messageNotifier,
              builder: (context, message, child) {
                return Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(fontSize: AppFontSize.body),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(ProgramModel program) {
    ProgramDeleteDialogHelper.confirmSingleDelete(
      context: context,
      ref: ref,
      program: program,
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionProvider);

    final isViewerMode =
        permissions.isReadOnly ||
        (() {
          try {
            return GoRouterState.of(context).uri.queryParameters['role'] ==
                'viewer';
          } catch (_) {
            return false;
          }
        }());

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                )
              : null,
          title: _isSelectionMode
              ? '${_selectedProgramIds.length}件選択中'
              : (isViewerMode ? '大会プログラム' : 'プログラム管理'),
          actions: _isSelectionMode
              ? [
                  if (!isViewerMode)
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppKendoColors.red),
                      tooltip: '選択したプログラムを削除',
                      onPressed: _selectedProgramIds.isEmpty
                          ? null
                          : _confirmBulkDelete,
                    ),
                  const SizedBox(width: AppSpacing.sm),
                ]
              : [
                  IconButton(
                    icon: Icon(
                      _isGridView
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                    ),
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                  ),
                ],
        ),
        body: () {
          final programAsync = ref.watch(
            programListProvider(widget.tournamentId),
          );

          return programAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) {
              debugPrint('🔥 Local Projection Error: $err');
              return const Center(child: Text('プログラムデータの読み込みに失敗しました。'));
            },
            data: (programs) {
              if (programs.isEmpty) {
                return Center(
                  child: Text(
                    isViewerMode ? 'プログラムはありません。' : 'プログラムを追加してください。',
                  ),
                );
              }
              return _isGridView
                  ? ProgramManagementContentViews.buildGridView(
                      context: context,
                      programs: programs,
                      getSafeUrl: _getSafeUrl,
                      onDelete: _confirmDelete,
                      isViewerMode: isViewerMode,
                      isSelectionMode: _isSelectionMode,
                      selectedProgramIds: _selectedProgramIds,
                      onToggleSelection: _toggleSelection,
                      onLongPress: _startSelection,
                    )
                  : ProgramManagementContentViews.buildListView(
                      context: context,
                      programs: programs,
                      getSafeUrl: _getSafeUrl,
                      onDelete: _confirmDelete,
                      isViewerMode: isViewerMode,
                      isSelectionMode: _isSelectionMode,
                      selectedProgramIds: _selectedProgramIds,
                      onToggleSelection: _toggleSelection,
                      onLongPress: _startSelection,
                    );
            },
          );
        }(),
        floatingActionButton: (isViewerMode || _isSelectionMode)
            ? null
            : FloatingActionButton.extended(
                onPressed: _isUploading ? null : _showPickerMenu,
                label: const Text('プログラムを追加'),
                icon: const Icon(Icons.add),
              ),
      ),
    );
  }
}
