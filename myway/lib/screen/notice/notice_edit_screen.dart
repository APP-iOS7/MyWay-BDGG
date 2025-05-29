import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';

class NoticeEditScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final String? noticeId;
  final bool isAdmin;

  const NoticeEditScreen({
    super.key,
    this.initialTitle,
    this.initialContent,
    this.noticeId,
    this.isAdmin = false,
  });

  @override
  State<NoticeEditScreen> createState() => _NoticeEditScreenState();
}

class _NoticeEditScreenState extends State<NoticeEditScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _contentController.text = widget.initialContent ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _completeWriting() {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("제목과 내용을 모두 입력해주세요."),
          backgroundColor: RED_DANGER_TEXT_50,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'title': _titleController.text,
      'content': _contentController.text,
      'noticeId': widget.noticeId,
      'updatedAt': DateTime.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "제목",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GRAYSCALE_LABEL_900,
              ),
            ),
            SizedBox(height: 5),
            TextField(
              cursorColor: ORANGE_PRIMARY_500,
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "제목을 입력하세요",
                hintStyle: TextStyle(color: GRAYSCALE_LABEL_400, fontSize: 14),
                filled: true,
                fillColor: BACKGROUND_COLOR,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: GRAYSCALE_LABEL_300,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: BLUE_SECONDARY_700, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
              ),
              style: TextStyle(fontSize: 14, color: GRAYSCALE_LABEL_950),
            ),
            SizedBox(height: 20),
            Text(
              "내용",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GRAYSCALE_LABEL_900,
              ),
            ),
            SizedBox(height: 5),
            Expanded(
              child: TextField(
                cursorColor: ORANGE_PRIMARY_500,
                controller: _contentController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "내용을 입력하세요",
                  hintStyle: TextStyle(
                    color: GRAYSCALE_LABEL_400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: BACKGROUND_COLOR,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: GRAYSCALE_LABEL_300,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: BLUE_SECONDARY_700,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(16.0),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: GRAYSCALE_LABEL_950,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52.0,
              child: ElevatedButton(
                onPressed: _completeWriting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: YELLOW_INFO_BASE_30,
                  foregroundColor: GRAYSCALE_LABEL_950,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  elevation: 0,
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text("작성 완료"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
