import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../const/colors.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final List<Map<String, dynamic>> _announcements = [
    {
      'type': '공지',
      'title': '공지사항 1',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'type': '공지',
      'title': '공지사항 제목이 길어지면 어떻게 할까나요 어떻게 해야하는거지',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'type': '공지',
      'title': '공지사항 3',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'type': '알림',
      'title': '공지사항 4',
      'timestamp': DateTime.now().subtract(const Duration(days: 4)),
    },
  ];

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WHITE,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: WHITE,
        title: const Text(
          '공지사항',
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '[${item['type']}]',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: GRAYSCALE_LABEL_900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item['title'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              Text(
                                _formatDateTime(item['timestamp']),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: GRAYSCALE_LABEL_700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        color: GRAYSCALE_LABEL_200,
                        thickness: 1,
                        height: 20,
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
