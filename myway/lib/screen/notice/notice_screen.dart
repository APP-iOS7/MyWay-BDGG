import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myway/screen/notice/notice_edit_screen.dart';
import '../../const/colors.dart';
import 'notice_view_screen.dart';

class NoticeScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final String? noticeId;
  const NoticeScreen({
    super.key,
    this.initialTitle,
    this.initialContent,
    this.noticeId,
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
    }

    if (widget.initialContent != null) {
      _savedContent = widget.initialContent!;
    }
  }

  void _switchToViewMode(String title, String content) {
    setState(() {
      _savedTitle = title;
      _savedContent = content;
      _noticeDate = DateFormat('yyyy.MM.dd').format(DateTime.now());
      _isEditing = false;
    });
  }

  void _switchToEditMode() {
    setState(() {
      _isEditing = true;
    });
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
              ? NoticeEditScreen(onComplete: _switchToViewMode)
              : NoticeViewScreen(
                title: _savedTitle,
                content: _savedContent,
                date: _noticeDate,
                onEdit: _switchToEditMode,
              ),
    );
  }
}
