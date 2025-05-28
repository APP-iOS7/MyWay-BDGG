import 'package:flutter/material.dart';
import '../../const/colors.dart';

class NoticeViewScreen extends StatelessWidget {
  final String title;
  final String content;
  final String date;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const NoticeViewScreen({
    super.key,
    required this.title,
    required this.content,
    required this.date,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title.isNotEmpty ? title : "제목 없음",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GRAYSCALE_LABEL_950,
                        ),
                      ),
                      // 관리자만 메뉴 버튼 표시
                      if (onEdit != null || onDelete != null)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: GRAYSCALE_LABEL_950,
                          ),
                          color: BACKGROUND_COLOR,
                          onSelected: (String result) {
                            if (result == 'edit' && onEdit != null) {
                              onEdit!();
                            } else if (result == 'delete' && onDelete != null) {
                              onDelete!();
                            }
                          },
                          itemBuilder:
                              (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                    if (onEdit != null)
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Text(
                                          '수정',
                                          style: TextStyle(
                                            color: GRAYSCALE_LABEL_800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    if (onDelete != null)
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text(
                                          '삭제',
                                          style: TextStyle(
                                            color: RED_DANGER_TEXT_50,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                        ),
                    ],
                  ),

                  SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: GRAYSCALE_LABEL_600),
                  ),
                ],
              ),
            ),
            Divider(color: GRAYSCALE_LABEL_200, height: 1, thickness: 1),
            SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  content.isNotEmpty ? content : "작성된 내용이 없습니다.",
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        content.isNotEmpty
                            ? GRAYSCALE_LABEL_800
                            : GRAYSCALE_LABEL_500,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
