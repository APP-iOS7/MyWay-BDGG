import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../const/colors.dart';

enum NoticeMode { view, edit }

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  NoticeMode _currentMode = NoticeMode.edit;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String _savedTitle = "";
  String _savedContent = "";
  String _noticeDate = "";

  bool get _isViewing => _currentMode == NoticeMode.view;
  bool get _isEditing => _currentMode == NoticeMode.edit;

  @override
  void initState() {
    super.initState();
    _noticeDate = DateFormat('yyyy.MM.dd').format(DateTime.now());
    // 예시 데이터: 만약 초기 데이터로 보기 모드를 시작하고 싶다면
    // _savedTitle = "[공지] 마이웨이 버전 업데이트 안내";
    // _savedContent = "Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of \"de Finibus Bonorum et Malorum\" (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum, \"Lorem ipsum dolor sit amet..\", comes from a line in section 1.10.32.\n\nThe standard chunk of Lorem Ipsum used since the 1500s is reproduced below for those interested. Sections 1.10.32 and 1.10.33 from \"de Finibus Bonorum et Malorum\" by Cicero are also reproduced in their exact original form, accompanied by English versions from the 1914 translation by H. Rackham.";
    // if (_savedTitle.isNotEmpty) {
    //   _currentMode = NoticeMode.view;
    // }
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
    if (mounted) {
      setState(() {
        _savedTitle = _titleController.text;
        _savedContent = _contentController.text;
        _noticeDate = DateFormat('yyyy.MM.dd').format(DateTime.now());
        _currentMode = NoticeMode.view;
      });
    }
  }

  void _switchToEditMode() {
    if (mounted) {
      setState(() {
        _titleController.text = _savedTitle;
        _contentController.text = _savedContent;
        _currentMode = NoticeMode.edit;
      });
    }
  }

  void _deleteNotice() {
    if (mounted) {
      setState(() {
        _savedTitle = "";
        _savedContent = "";
        _titleController.clear();
        _contentController.clear();
        _noticeDate = DateFormat('yyyy.MM.dd').format(DateTime.now());
        _currentMode = NoticeMode.edit;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("공지사항이 삭제되었습니다."),
          backgroundColor: GREEN_SUCCESS_TEXT_50,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: BACKGROUND_COLOR,
          title: Text(
            '삭제 확인',
            style: TextStyle(
              color: GRAYSCALE_LABEL_950,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '정말로 이 공지사항을 삭제하시겠습니까?',
            style: TextStyle(color: GRAYSCALE_LABEL_800),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소', style: TextStyle(color: GRAYSCALE_LABEL_700)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '삭제',
                style: TextStyle(
                  color: RED_DANGER_TEXT_50,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteNotice();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitleSection() {
    if (_isEditing) {
      return Column(
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
            controller: _titleController,
            decoration: InputDecoration(
              hintText: "제목을 입력하세요",
              hintStyle: TextStyle(color: GRAYSCALE_LABEL_400, fontSize: 14),
              filled: true,
              fillColor: BACKGROUND_COLOR,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: GRAYSCALE_LABEL_300, width: 1.0),
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
        ],
      );
    } else {
      // 보기 모드
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: GRAYSCALE_LABEL_200, height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _savedTitle.isNotEmpty ? _savedTitle : "제목 없음",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: GRAYSCALE_LABEL_950,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _noticeDate,
                  style: TextStyle(fontSize: 12, color: GRAYSCALE_LABEL_600),
                ),
              ],
            ),
          ),
          Divider(color: GRAYSCALE_LABEL_200, height: 1, thickness: 1),
        ],
      );
    }
  }

  Widget _buildContentSection() {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              controller: _contentController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: "내용을 입력하세요",
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
                contentPadding: EdgeInsets.all(16.0),
              ),
              style: TextStyle(
                fontSize: 14,
                color: GRAYSCALE_LABEL_950,
                height: 1.5,
              ),
            ),
          ),
        ],
      );
    } else {
      return Expanded(
        child: SizedBox(
          width: double.infinity,
          // 보기 모드에서는 내용에 대한 별도의 박스나 테두리 없이 바로 텍스트 표시
          // 패딩은 SingleChildScrollView 또는 부모 Column에서 관리
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // 내용 위아래 약간의 패딩
            child: Text(
              _savedContent.isNotEmpty ? _savedContent : "작성된 내용이 없습니다.",
              style: TextStyle(
                fontSize: 14,
                color:
                    _savedContent.isNotEmpty
                        ? GRAYSCALE_LABEL_800
                        : GRAYSCALE_LABEL_500,
                height: 1.6,
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPageMargin = 20.0;
    const double fieldHeight = 52.0;

    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: BACKGROUND_COLOR,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: GRAYSCALE_LABEL_950),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
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
        actions: [
          if (_isViewing && _savedTitle.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: GRAYSCALE_LABEL_950),
              color: BACKGROUND_COLOR,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              onSelected: (String result) {
                if (result == 'edit') {
                  _switchToEditMode();
                } else if (result == 'delete') {
                  _showDeleteConfirmationDialog();
                }
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            horizontalPageMargin,
            0,
            horizontalPageMargin,
            horizontalPageMargin,
          ), // 상단 패딩 제거
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: _isEditing ? 0 : 16), // 보기 모드일 때만 제목 위 구분선과의 간격
              _buildTitleSection(),
              SizedBox(height: _isEditing ? 20 : 12),
              Expanded(child: _buildContentSection()),
              if (_isEditing) SizedBox(height: 10), // 내용과 버튼 사이 간격 (편집 모드에서만)
              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  height: fieldHeight,
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
      ),
    );
  }
}
