import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tournament_model.dart';
import '../repositories/tournament_repository.dart';

class CreateTournamentScreen extends ConsumerStatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  ConsumerState<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends ConsumerState<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _currentProgress = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    _pageController.dispose(); 
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      locale: const Locale('ja'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _openMap() async {
    if (_venueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('会場名または住所を入力してください')),
      );
      return;
    }

    final Uri url = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': _venueController.text,
    });

    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        // 成功
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('マップアプリを起動できませんでした')),
        );
      }
    }
  }

  // ★ 修正：没入型AppBarのアイコンを「右上の✕」から「左上の＜」へ統一！
  Widget _buildImmersiveAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 8, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.grey.shade800, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final t = (_currentProgress / 1).clamp(0.0, 1.0); 
        
        // iOS Native: ダークモード時は彩度を抑えた深みのあるTealへ
        final color1 = isDark ? Colors.teal.shade800 : Colors.teal.shade400;
        final color2 = isDark ? Colors.teal.shade900 : Colors.teal.shade700;
        final endColor = isDark ? Colors.teal.shade800 : Colors.teal.shade300;
        final gradientColor = Color.lerp(color1, color2, t)!;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('大会を新規作成', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Text('魔法のウィザードに従って、\n2つのステップで設定を完了しましょう', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: (_currentProgress + 1) / 2, 
                backgroundColor: Colors.white.withValues(alpha: 0.3), 
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: bgColor, 
      body: Stack(
        children: [
          Column(
            children: [
              _buildImmersiveAppBar(context),
              _buildDynamicHeader(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), 
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _buildPage1(),
                      _buildPage2(),
                    ],
                  ),
                ),
              ),
              _buildStickyBottomAction(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inputBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color hintColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade400;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('大会の名前と日付を\n教えてください', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4, color: textColor)),
        const SizedBox(height: 32),
        TextFormField(
          controller: _nameController,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: '大会名',
            labelStyle: const TextStyle(color: Colors.grey),
            hintText: '例：第50回 道上剣友会大会',
            hintStyle: TextStyle(color: hintColor, fontSize: 13),
            prefixIcon: const Icon(Icons.emoji_events, color: Colors.amber),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade200, width: 1.0) // iOS Border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: Colors.teal.shade500, width: 2.0)
            ),
            filled: true,
            fillColor: inputBgColor,
          ),
          validator: (v) => v == null || v.isEmpty ? '大会名を入力してください' : null,
        ),
        const SizedBox(height: 24),
        ListTile(
          title: const Text('開催年月日', style: TextStyle(color: Colors.grey, fontSize: 12)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              DateFormat('yyyy年MM月dd日').format(_selectedDate),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          trailing: const Icon(Icons.calendar_today, color: Colors.teal),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade200, width: 1.0),
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: inputBgColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: _pickDate,
        ),
      ],
    );
  }

  Widget _buildPage2() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inputBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color hintColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade400;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('開催場所とメモを\n入力してください', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4, color: textColor)),
        const SizedBox(height: 32),
        TextFormField(
          controller: _venueController,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: '会場・住所',
            labelStyle: const TextStyle(color: Colors.grey),
            hintText: '例：広島県立体育館',
            hintStyle: TextStyle(color: hintColor, fontSize: 13),
            prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map, color: Colors.blue),
              onPressed: _openMap,
              tooltip: '地図で場所を確認',
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade200, width: 1.0)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: Colors.teal.shade500, width: 2.0)
            ),
            filled: true,
            fillColor: inputBgColor,
          ),
          validator: (v) => v == null || v.isEmpty ? '会場を入力してください' : null,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: '大会メモ（任意）',
            labelStyle: const TextStyle(color: Colors.grey),
            hintText: '例：駐車場は第2駐車場を利用。\n開場は8:30〜。',
            hintStyle: TextStyle(color: hintColor, fontSize: 13),
            prefixIcon: const Icon(Icons.note_alt, color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade200, width: 1.0)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: Colors.teal.shade500, width: 2.0)
            ),
            filled: true,
            fillColor: inputBgColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyBottomAction() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = _currentPage == 1;
    final Color bottomBarColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color separatorColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bottomBarColor,
        // iOS Native: 影の代わりに上部に細いBorderを引くのがモダンiOS風
        border: Border(top: BorderSide(color: separatorColor, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16), 
                  shape: const CircleBorder(),
                  side: BorderSide(color: separatorColor),
                ),
                child: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.teal.shade500), // ダークでも見やすいTeal
              ),
            ),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_currentPage == 0) {
                  if (_nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('大会名を入力してください')));
                    return;
                  }
                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                } else {
                  if (_formKey.currentState!.validate()) {
                    final newTournament = TournamentModel(
                      id: '',
                      name: _nameController.text,
                      date: _selectedDate,
                      venue: _venueController.text,
                      categories: const [],
                      notes: _notesController.text.trim(),
                    );
                    
                    final newId = await ref.read(tournamentRepositoryProvider).saveTournament(newTournament);
                    
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('基本情報を保存しました！'))
                    );
                    
                    context.push('/team-registration/$newId');
                  }
                }
              },
              icon: Icon(isLastPage ? Icons.check_circle : Icons.navigate_next, color: Colors.white),
              label: Text(
                isLastPage ? '保存してチーム登録へ' : '次へ進む', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.teal.shade600 : Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // iOS標準の角丸
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}