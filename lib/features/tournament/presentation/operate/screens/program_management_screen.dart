import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import '../providers/permission_provider.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/utils/image_compressor.dart';

// =========================================================================
// 🛡️ Phase 0 - STEP 0-1 要件：UIからFirestoreを完全隔離する抽象化プロバイダー
// 将来的にここを Isar Projection の監視ストリームに1行で差し替えます
// =========================================================================
final programListProvider = StreamProvider.family<List<ProgramModel>, String>((
  ref,
  tournamentId,
) {
  final repository = ref.watch(programRepositoryProvider);
  return repository.watchPrograms(tournamentId);
});

class ProgramManagementScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const ProgramManagementScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<ProgramManagementScreen> createState() =>
      _ProgramManagementScreenState();
}

class _ProgramManagementScreenState
    extends ConsumerState<ProgramManagementScreen> {
  // ignore: prefer_final_fields
  bool _isUploading = false;
  // ignore: prefer_final_fields
  bool _isGridView = false; // ★ グリッド/リストの切り替えスイッチ

  // ★ 追加: setStateの度にURLが変わり全画像が再レンダリングされるのを防ぐための固定セッションID
  final int _sessionBuster = DateTime.now().millisecondsSinceEpoch;

  // ★ 追加: Web特有のCORSエラーキャッシュを回避するURLジェネレーター
  String _getSafeUrl(String url) {
    if (!kIsWeb || url.isEmpty || !url.startsWith('http')) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}_cb=$_sessionBuster';
  }

  void _showPickerMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'プログラムの追加',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('写真ライブラリから選ぶ (複数可)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpload(isPhoto: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('ファイルから選ぶ (複数可)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpload(isPhoto: false);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload({required bool isPhoto}) async {
    final result = await FilePicker.platform.pickFiles(
      type: isPhoto ? FileType.image : FileType.custom,
      allowedExtensions: isPhoto ? null : ['pdf'],
      allowMultiple: true,
      withData: kIsWeb, // ★ Webはバイナリデータを取得する必要がある
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    // ★ 新しいプレビューダイアログを呼び出し
    final dialogResult = await _showTitleAndPreviewDialog(result.files);
    if (dialogResult == null || dialogResult['title'].isEmpty) {
      return;
    }

    final String title = dialogResult['title'];
    final List<PlatformFile> orderedFiles =
        dialogResult['files']; // 並び替え済みのファイルリスト
    final int fileCount = orderedFiles.length;

    final messageNotifier = ValueNotifier<String>('準備中...');
    _showLoadingDialog(messageNotifier);

    try {
      // ★ ユーザーが並び替えた orderedFiles を使ってループ
      for (int i = 0; i < orderedFiles.length; i++) {
        final platformFile = orderedFiles[i];
        final extension = platformFile.extension?.toLowerCase() ?? '';
        final fileType = (isPhoto || extension != 'pdf') ? 'image' : 'pdf';

        final displayTitle = orderedFiles.length > 1
            ? '$title (${i + 1}/${orderedFiles.length})'
            : title;

        if (fileType == 'image') {
          messageNotifier.value = "画像を圧縮中... (${i + 1}/${orderedFiles.length})";

          // 原寸バイトデータの取得（メモリ効率を考慮しループ内で随時ロード）
          Uint8List? originalBytes;
          if (kIsWeb) {
            originalBytes = platformFile.bytes;
          } else if (platformFile.path != null) {
            originalBytes = await File(platformFile.path!).readAsBytes();
          }

          if (originalBytes == null || originalBytes.isEmpty) {
            throw Exception('ファイルデータの読み込みに失敗しました。');
          }

          // 🛡️ メモリ爆発ガード（OOM防止）：20MBを超える画像はエラーとする
          if (originalBytes.length > 20 * 1024 * 1024) {
            throw Exception('画像ファイルが大きすぎます（最大20MB）。事前にリサイズしてアップロードしてください。');
          }

          // 画像の自動圧縮実行（別スレッド compute にて実行）
          final compressedBytes = await ImageCompressor.compress(
            bytes: originalBytes,
            maxWidth: 2000,
            maxHeight: 2000,
            quality: 80,
          );

          // 圧縮が成功した場合はそれを使用、デコード不能（HEIC等）ならオリジナルをそのまま流すフォールバック
          final uploadBytes = compressedBytes ?? originalBytes;

          messageNotifier.value =
              "アップロード中... (${i + 1}/${orderedFiles.length})";

          await ref
              .read(programRepositoryProvider)
              .uploadProgram(
                tournamentId: widget.tournamentId,
                title: displayTitle,
                file: null, // bytes経由でのアップロードに統一
                bytes: uploadBytes,
                fileType: fileType,
                pageCount: 1,
              );
        } else {
          // PDF等の場合はそのままアップロード
          messageNotifier.value =
              "アップロード中... (${i + 1}/${orderedFiles.length})";

          await ref
              .read(programRepositoryProvider)
              .uploadProgram(
                tournamentId: widget.tournamentId,
                title: displayTitle,
                file: kIsWeb || platformFile.path == null
                    ? null
                    : File(platformFile.path!),
                bytes: platformFile.bytes,
                fileType: fileType,
                pageCount: 1,
              );
        }
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$fileCount件のプログラムをアップロードしました')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
    }
  }

  Future<Map<String, dynamic>?> _showTitleAndPreviewDialog(
    List<PlatformFile> files,
  ) async {
    // ★ 修正1: 初期タイトルをファイル名から取得せず、完全に「空（カラ）」にします
    String title = '';
    List<PlatformFile> orderedFiles = List.from(files);
    int selectedIndex = 0; // ★ 同期のための単一の状態
    final PageController previewController = PageController();
    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 20,
            ),
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            title: const Text(
              '順番とタイトルの確認',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    // --- 上半分：大型プレビューエリア (40%) ---
                    Expanded(
                      flex: 4,
                      child: Container(
                        color: Colors.black,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: previewController,
                              itemCount: orderedFiles.length,
                              onPageChanged: (index) =>
                                  setState(() => selectedIndex = index),
                              itemBuilder: (context, index) {
                                final file = orderedFiles[index];
                                final isPdf =
                                    file.extension?.toLowerCase() == 'pdf';
                                return InteractiveViewer(
                                  minScale: 1.0,
                                  maxScale: 4.0,
                                  child: Center(
                                    child: isPdf
                                        ? const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.picture_as_pdf,
                                                color: Colors.white,
                                                size: 64,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'PDFプレビュー非対応\n(アップロード後に確認可能)',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          )
                                        : kIsWeb
                                        ? (file.bytes != null
                                              ? Image.memory(
                                                  file.bytes!,
                                                  fit: BoxFit.contain,
                                                )
                                              : const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white,
                                                  size: 64,
                                                ))
                                        : (file.path != null
                                              ? Image.file(
                                                  File(file.path!),
                                                  fit: BoxFit.contain,
                                                )
                                              : const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white,
                                                  size: 64,
                                                )),
                                  ),
                                );
                              },
                            ),
                            // 左右のナビゲーション補助
                            if (orderedFiles.length > 1) ...[
                              Positioned(
                                left: 8,
                                top: 0,
                                bottom: 0,
                                child: Icon(
                                  Icons.chevron_left,
                                  color: Colors.white.withAlpha(128),
                                  size: 32,
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 0,
                                bottom: 0,
                                child: Icon(
                                  Icons.chevron_right,
                                  color: Colors.white.withAlpha(128),
                                  size: 32,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // --- 中間：タイトル入力＆説明エリア ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.indigo.shade50, // ★ 背景色をつけて視覚的に目立たせる
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📝 プログラム名（ベースタイトル）',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: title,
                            // ★ 修正2: オートフォーカスを解除し、キーボードの自動立ち上げを防ぐ
                            autofocus: false,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              // ★ 初期値が空になるため、このヒントテキストが薄いグレーで表示されます
                              hintText: '例：1日目 進行表',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                              ), // ★ 追加：文字色を薄いグレーにする
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.indigo.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.indigo.shade200,
                                ),
                              ),
                              errorStyle: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onChanged: (value) => title = value,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'プログラムのタイトルを入力してください';
                              }
                              return null;
                            },
                          ),
                          // ★ 複数ファイル選択時のインフォメーションカードをリデザイン
                          if (orderedFiles.length > 1) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50.withAlpha(200),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.indigo.shade100,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.indigo.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '複数アップロードのガイド：\n'
                                      '• 下のリストをドラッグして並び順を変更できます。\n'
                                      '• 保存時、自動的に「[入力タイトル] (1/${orderedFiles.length})」のように連番が付与されて保存されます。',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.indigo.shade900,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // --- 下半分：並び替えリストエリア (60%) ---
                    Expanded(
                      flex: 6,
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: orderedFiles.length,
                        onReorderItem: (oldIndex, newIndex) {
                          setState(() {
                            final item = orderedFiles.removeAt(oldIndex);
                            orderedFiles.insert(newIndex, item);
                            // 順番が変わっても、今見ていた画像が迷子にならないようにインデックスを調整
                            selectedIndex = orderedFiles.indexOf(item);
                            previewController.jumpToPage(selectedIndex);
                          });
                        },
                        itemBuilder: (context, index) {
                          final file = orderedFiles[index];
                          final isSelected = selectedIndex == index;
                          return ListTile(
                            // Web環境で path にアクセスすると例外が飛ぶため、安全な fallback に変更
                            key: ValueKey(
                              kIsWeb ? file.name : (file.path ?? file.name),
                            ),
                            selected: isSelected,
                            selectedTileColor: Colors.indigo.shade50,
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: isSelected
                                  ? Colors.indigo
                                  : Colors.grey,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            title: Text(
                              file.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: const Icon(Icons.drag_handle, size: 20),
                            onTap: () {
                              setState(() => selectedIndex = index);
                              previewController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'title': title.trim(),
                      'files': orderedFiles,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text('アップロード開始'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLoadingDialog(ValueNotifier<String> messageNotifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
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
                        style: const TextStyle(fontSize: 14),
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

  Future<void> _confirmDelete(ProgramModel program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プログラムの削除'),
        content: Text('「${program.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(programRepositoryProvider).deleteProgram(program);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ 監査指摘：UIがリポジトリ(Firestore)を直読していた watch(programRepositoryProvider) を物理排除
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('プログラム管理'),
          actions: [
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              ),
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
          ],
        ),
        // =========================================================================
        // 🛡️ Phase 0 - STEP 0-1 要件：Firestore依存UIの全排除
        // UIは新設されたプロバイダー層のみを凝視し、内部実装がFirestoreかIsarかを感知しない
        // =========================================================================
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
                  ? _buildGridView(programs)
                  : _buildListView(programs);
            },
          );
        }(),
        floatingActionButton: isViewerMode
            ? null
            : FloatingActionButton.extended(
                onPressed: _isUploading ? null : _showPickerMenu,
                label: const Text('プログラムを追加'),
                icon: const Icon(Icons.add),
              ),
      ),
    );
  }

  Widget _buildGridView(List<ProgramModel> programs) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        final isUploading = program.fileUrl.contains('placehold.co');

        return InkWell(
          // ★ 修正: アップロード中の場合はタップを無効化し、Viewer画面での無限クルクルを防ぐ
          onTap: isUploading
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('アップロード中です。完了するまでお待ちください。')),
                )
              : () => context.push(
                  '/program-viewer',
                  extra: {'programs': programs, 'index': index},
                ),
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // サムネイル表示
                program.fileType == 'pdf'
                    ? Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.picture_as_pdf,
                          size: 64,
                          color: Colors.redAccent,
                        ),
                      )
                    : Image.network(
                        _getSafeUrl(program.fileUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                // タイトルと削除ボタンのオーバーレイ
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withAlpha(153),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            program.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _confirmDelete(program),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<ProgramModel> programs) {
    return ListView.builder(
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        final isUploading = program.fileUrl.contains('placehold.co');

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: Colors.grey.shade200,
              child: program.fileType == 'pdf'
                  ? const Icon(Icons.picture_as_pdf, color: Colors.redAccent)
                  : Image.network(
                      _getSafeUrl(program.fileUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                    ),
            ),
          ),
          title: Text(
            program.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(program.fileType.toUpperCase()),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(program),
          ),
          // ★ 修正: アップロード中の場合はタップを無効化し、Viewer画面での無限クルクルを防ぐ
          onTap: isUploading
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('アップロード中です。完了するまでお待ちください。')),
                )
              : () => context.push(
                  '/program-viewer',
                  extra: {'programs': programs, 'index': index},
                ),
        );
      },
    );
  }
}
