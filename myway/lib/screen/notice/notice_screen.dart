import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myway/screen/notice/notice_edit_screen.dart';
import '../../const/colors.dart';
import 'notice_view_screen.dart';

class NoticeScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final String? noticeId;
  final bool isAdmin;

  const NoticeScreen({
    super.key,
    this.initialTitle,
    this.initialContent,
    this.noticeId,
    this.isAdmin = false,
  });

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  bool _isEditing = true;
  String _savedTitle = "";
  String _savedContent = "";
  String _noticeDate = "";

  @override
  void initState() {
    super.initState();
    _noticeDate = DateFormat('yyyy.MM.dd').format(DateTime.now());

    if (widget.initialTitle != null) {
      _savedTitle = widget.initialTitle!;
      _savedContent = widget.initialContent!;
      _isEditing = false; // 초기값이 있으면 보기 모드로 시작
    }
  }

  void _switchToEditMode() {
    setState(() {
      _isEditing = true;
    });
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: BACKGROUND_COLOR,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            '공지사항 삭제',
            style: TextStyle(
              color: GRAYSCALE_LABEL_900,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            '공지사항을 삭제 하시겠습니까?',
            style: TextStyle(
              fontSize: 16,
              color: GRAYSCALE_LABEL_700,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.only(
            bottom: 12,
            left: 12,
            right: 12,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: GRAYSCALE_LABEL_100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: GRAYSCALE_LABEL_900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pop(context, {'delete': true});
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ORANGE_PRIMARY_500,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '삭제',
                        style: TextStyle(
                          color: BACKGROUND_COLOR,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: BACKGROUND_COLOR,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: GRAYSCALE_LABEL_950),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "공지사항",
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body:
          _isEditing
              ? NoticeEditScreen(
                initialTitle: _savedTitle,
                initialContent: _savedContent,
                noticeId: widget.noticeId,
                isAdmin: widget.isAdmin,
              )
              : NoticeViewScreen(
                title: _savedTitle,
                content: _savedContent,
                date: _noticeDate,
                onEdit: widget.isAdmin ? _switchToEditMode : null,
                onDelete: widget.isAdmin ? _showDeleteConfirmationDialog : null,
              ),
    );
  }
}
