import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final List<Map<String, dynamic>> _announcements = [
    {
      'title': '공지사항 1',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'title': '공지사항 2',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'title': '공지사항 3',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'title': '공지사항 4',
      'timestamp': DateTime.now().subtract(const Duration(days: 4)),
    },
  ];

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항'),
        centerTitle: true,
        foregroundColor: Colors.black,
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})],
      ),
      body:
          _announcements.isEmpty
              ? const Center(child: Text('작성된 공지사항이 없습니다.'))
              : ListView.builder(
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final item = _announcements[index];
                  return ListTile(
                    leading: Text('[공지]'),
                    title: Text(item['title']),
                    subtitle: Text(_formatDateTime(item['timestamp'])),
                    onTap: () {
                      // 공지사항 클릭 시 상세 페이지로 이동
                    },
                  );
                },
              ),
    );
  }
}
