/// 易青岚高级课笔记
/// 40课时笔记目录与内容展示，需解锁后使用
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class CourseNotesScreen extends StatefulWidget {
  const CourseNotesScreen({super.key});

  @override
  State<CourseNotesScreen> createState() => _CourseNotesScreenState();
}

class _CourseNotesScreenState extends State<CourseNotesScreen> {
  List<Map<String, String>> _lessons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/course_notes.json');
      final list = jsonDecode(jsonStr) as List;
      _lessons = list.map((e) => {
        'title': e['title'] as String,
        'content': e['content'] as String,
      }).toList();
    } catch (e) {
      // 加载失败
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('易青岚高级课笔记'),
        actions: [
          if (_lessons.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (section) {
                // 滚动到对应课程
              },
              itemBuilder: (context) => _lessons.map((l) =>
                PopupMenuItem(value: l['title'], child: Text(l['title']!.length > 20
                    ? '${l['title']!.substring(0, 20)}...'
                    : l['title']!))
              ).toList(),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lessons.isEmpty
              ? const Center(child: Text('加载课程失败'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _lessons.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final lesson = _lessons[index];
                    return _LessonTile(
                      index: index + 1,
                      title: lesson['title']!,
                      onTap: () => _openLesson(lesson['title']!, lesson['content']!),
                    );
                  },
                ),
    );
  }

  void _openLesson(String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _LessonDetailScreen(title: title, content: content),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final int index;
  final String title;
  final VoidCallback onTap;

  const _LessonTile({required this.index, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFF5D4037),
        child: Text('$index', style: const TextStyle(fontSize: 12, color: Colors.white)),
      ),
      title: Text(
        title.replaceAll('☯', ''),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}

class _LessonDetailScreen extends StatelessWidget {
  final String title;
  final String content;

  const _LessonDetailScreen({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title.replaceAll('☯', ''), style: const TextStyle(fontSize: 15)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          content,
          style: const TextStyle(fontSize: 15, height: 1.8),
        ),
      ),
    );
  }
}
