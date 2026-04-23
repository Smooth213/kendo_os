import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import 'package:go_router/go_router.dart';
import '../repositories/program_repository.dart';
import '../models/program_model.dart';

class ProgramManagementScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const ProgramManagementScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<ProgramManagementScreen> createState() => _ProgramManagementScreenState();
}

class _ProgramManagementScreenState extends ConsumerState<ProgramManagementScreen> {
  // ignore: prefer_final_fields
  bool _isUploading = false;
  // ignore: prefer_final_fields
  bool _isGridView = false; // ★ グリッド/リストの切り替えスイッチ

  Future<File> _compressImage(File file) async {
    final tempDir = await path_provider.getTemporaryDirectory();
    final targetPath = p.join(tempDir.path, "${DateTime.now().millisecondsSinceEpoch}_compressed.jpg");

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path, targetPath, quality: 80, minWidth: 2000, minHeight: 2000,
    );
    return File(result!.path);
  }

  void _showPickerMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('プログラムの追加', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    );

    if (result == null || result.files.isEmpty) return;

    // ★ 新しいプレビューダイアログを呼び出し
    final dialogResult = await _showTitleAndPreviewDialog(result.files);
    if (dialogResult == null || dialogResult['title'].isEmpty) return;

    final String title = dialogResult['title'];
    final List<PlatformFile> orderedFiles = dialogResult['files']; // 並び替え済みのファイルリスト
    final int fileCount = orderedFiles.length;

    _showLoadingDialog(fileCount);

    try {
      // ★ ユーザーが並び替えた orderedFiles を使ってループ
      for (int i = 0; i < fileCount; i++) {
        final platformFile = orderedFiles[i];
        if (platformFile.path == null) continue;

        File file = File(platformFile.path!);
        final extension = platformFile.extension?.toLowerCase() ?? '';
        final fileType = (isPhoto || extension != 'pdf') ? 'image' : 'pdf';
        
        final displayTitle = fileCount > 1 ? '$title (${i + 1}/$fileCount)' : title;

        if (fileType == 'image') {
          file = await _compressImage(file);
        }

        await ref.read(programRepositoryProvider).uploadProgram(
          tournamentId: widget.tournamentId,
          title: displayTitle,
          file: file,
          fileType: fileType,
          pageCount: 1,
        );
      }

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$fileCount件のプログラムをアップロードしました')));
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
    }
  }

  Future<Map<String, dynamic>?> _showTitleAndPreviewDialog(List<PlatformFile> files) async {
    // ★ 修正1: 初期タイトルをファイル名から取得せず、完全に「空（カラ）」にします
    String title = ''; 
    List<PlatformFile> orderedFiles = List.from(files);
    int selectedIndex = 0; // ★ 同期のための単一の状態
    final PageController previewController = PageController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            title: const Text('順番とタイトルの確認', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SizedBox(
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
                            onPageChanged: (index) => setState(() => selectedIndex = index),
                            itemBuilder: (context, index) {
                              final file = orderedFiles[index];
                              final isPdf = file.extension?.toLowerCase() == 'pdf';
                              return InteractiveViewer(
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Center(
                                  child: isPdf
                                      ? const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.picture_as_pdf, color: Colors.white, size: 64),
                                            SizedBox(height: 8),
                                            Text('PDFプレビュー非対応\n(アップロード後に確認可能)', 
                                                textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          ],
                                        )
                                      : Image.file(File(file.path!), fit: BoxFit.contain),
                                ),
                              );
                            },
                          ),
                          // 左右のナビゲーション補助
                          if (orderedFiles.length > 1) ...[
                            Positioned(
                              left: 8, top: 0, bottom: 0,
                              child: Icon(Icons.chevron_left, color: Colors.white.withValues(alpha: 0.5), size: 32),
                            ),
                            Positioned(
                              right: 8, top: 0, bottom: 0,
                              child: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5), size: 32),
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
                        const Text('📝 プログラム名（ベースタイトル）', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: title,
                          // ★ 修正2: オートフォーカスを解除し、キーボードの自動立ち上げを防ぐ
                          autofocus: false, 
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            // ★ 初期値が空になるため、このヒントテキストが薄いグレーで表示されます
                            hintText: '例：1日目 進行表', 
                            hintStyle: TextStyle(color: Colors.grey.shade400), // ★ 追加：文字色を薄いグレーにする
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.indigo.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.indigo.shade200),
                            ),
                          ),
                          onChanged: (value) => title = value,
                        ),
                        // ★ 失われていた親切なガイド文を復活！
                        if (orderedFiles.length > 1) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.indigo.shade700),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '下のリストをドラッグして順番を入れ替えられます。\n保存時、「タイトル (1/${orderedFiles.length})」のように自動で連番が付きます。',
                                  style: TextStyle(fontSize: 11, color: Colors.indigo.shade900, height: 1.3),
                                ),
                              ),
                            ],
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
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
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
                          key: ValueKey(file.path ?? file.name),
                          selected: isSelected,
                          selectedTileColor: Colors.indigo.shade50,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: isSelected ? Colors.indigo : Colors.grey,
                            child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                          title: Text(file.name, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          trailing: const Icon(Icons.drag_handle, size: 20),
                          onTap: () {
                            setState(() => selectedIndex = index);
                            previewController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {'title': title, 'files': orderedFiles}),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: const Text('アップロード開始'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showLoadingDialog(int fileCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text("$fileCount件をアップロード中...\n少々お待ちください", style: const TextStyle(fontSize: 14)),
              ],
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(programRepositoryProvider).deleteProgram(program);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(programRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プログラム管理'),
        actions: [
          // ★ グリッド/リストの切り替えボタンを追加
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'リスト表示にする' : 'グリッド表示にする',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ProgramModel>>(
        stream: repository.watchPrograms(widget.tournamentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          
          final programs = snapshot.data ?? [];
          if (programs.isEmpty) {
            return const Center(child: Text('登録されたプログラムはありません。\n右下のボタンから追加してください。', textAlign: TextAlign.center));
          }

          // ★ グリッド表示モード
          if (_isGridView) {
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.8,
              ),
              itemCount: programs.length,
              itemBuilder: (context, index) {
                final program = programs[index];
                return InkWell(
                  // ★ タップ時、リスト全体と「タップした画像のインデックス」を渡す
                  onTap: () => context.push('/program-viewer', extra: {'programs': programs, 'index': index}),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // サムネイル表示
                        program.fileType == 'pdf'
                            ? Container(color: Colors.grey.shade200, child: const Icon(Icons.picture_as_pdf, size: 64, color: Colors.redAccent))
                            : Image.network(program.fileUrl, fit: BoxFit.cover),
                        // タイトルと削除ボタンのオーバーレイ
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(program.title, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                GestureDetector(
                                  onTap: () => _confirmDelete(program),
                                  child: const Icon(Icons.delete, color: Colors.white70, size: 18),
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

          // ★ リスト表示モード (従来通りだが、サムネイルを追加)
          return ListView.builder(
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48, height: 48, color: Colors.grey.shade200,
                    child: program.fileType == 'pdf'
                        ? const Icon(Icons.picture_as_pdf, color: Colors.redAccent)
                        : Image.network(program.fileUrl, fit: BoxFit.cover),
                  ),
                ),
                title: Text(program.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(program.fileType.toUpperCase()),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(program)),
                // ★ タップ時、リスト全体とインデックスを渡す
                onTap: () => context.push('/program-viewer', extra: {'programs': programs, 'index': index}),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _showPickerMenu,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('プログラムを追加'),
      ),
    );
  }
}