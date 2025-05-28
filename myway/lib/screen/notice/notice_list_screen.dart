import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myway/screen/notice/notice_screen.dart';

import '../../const/colors.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _noticesCollection = FirebaseFirestore.instance
      .collection('notices');

  String _formatDateTime(DateTime datetime) {
    return DateFormat('yyyy-MM-dd').format(datetime);
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

        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NoticeScreen()),
              );

              if (result != null) {
                // 공지사항 작성으로 이동 > 작성완료 후 돌아오면 Firestroe에 데이터 저장
                await _noticesCollection.add({
                  'title': result['title'],
                  'content': result['content'],
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _noticesCollection
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '오류가 발생했습니다.',
                style: TextStyle(color: RED_DANGER_TEXT_50, fontSize: 16),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: ORANGE_PRIMARY_500),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                '작성된 공지사항이 없습니다.',
                style: TextStyle(color: GRAYSCALE_LABEL_600, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder:
                (context, index) => Divider(
                  color: GRAYSCALE_LABEL_200,
                  height: 1,
                  thickness: 1,
                ),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['createdAt'] as Timestamp?;

              return InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => NoticeScreen(
                            initialTitle: data['title'],
                            initialContent: data['content'],
                            noticeId: doc.id,
                          ),
                    ),
                  );
                  if (result != null) {
                    // Firestore에 공지사항 수정 반영
                    await _noticesCollection.doc(doc.id).update({
                      'title': result['title'],
                      'content': result['content'],
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? '제목 없음',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: GRAYSCALE_LABEL_950,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        timestamp != null
                            ? _formatDateTime(timestamp.toDate())
                            : '날짜 없음',
                        style: TextStyle(
                          fontSize: 12,
                          color: GRAYSCALE_LABEL_600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
