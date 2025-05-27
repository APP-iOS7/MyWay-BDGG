import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/const/colors.dart';

class NicknameChangeScreen extends StatefulWidget {
  const NicknameChangeScreen({super.key});

  @override
  State<NicknameChangeScreen> createState() => _NicknameChangeScreenState();
}

class _NicknameChangeScreenState extends State<NicknameChangeScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  String _enteredNickname = "";
  bool _isNicknameChangeConfirmed = false;
  String _currentNicknameHint = "현재 닉네임: 대장보현(칼바람)";
  String? _currentNickname;
  String initialNickname = '대장보현(칼바람)';
  String validationLabelString = '';

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
    _loadCurrentNickname();
  }

  void _onNicknameChanged(String value) {
    if (mounted) {
      setState(() {
        _enteredNickname = value;
      });
    }
  }

  Future<void> _showConfirmationDialog() async {
    if (_nicknameController.text.isEmpty) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("변경할 닉네임을 입력해주세요."),
      //     backgroundColor: RED_DANGER_TEXT_50,
      //   ),
      // );
      return;
    }
    if (_nicknameController.text ==
            _currentNicknameHint.substring(
              _currentNicknameHint.indexOf(':') + 2,
            ) &&
        _currentNicknameHint.startsWith("현재 닉네임:")) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("현재 닉네임과 동일합니다."),
      //     backgroundColor: YELLOW_INFO_BASE_30,
      //   ),
      // );
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: BACKGROUND_COLOR,
          title: Text('닉네임 변경', style: TextStyle(color: GRAYSCALE_LABEL_950)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  "'${_nicknameController.text}' (으)로 변경하시겠습니까?",
                  style: TextStyle(color: GRAYSCALE_LABEL_800),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소', style: TextStyle(color: GRAYSCALE_LABEL_700)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('확인', style: TextStyle(color: BLUE_SECONDARY_500)),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _isNicknameChangeConfirmed = true;
                    _currentNicknameHint =
                        "현재 닉네임: ${_nicknameController.text}";
                    _enteredNickname = "";
                  });
                }
                print("새 닉네임 확정: ${_nicknameController.text}");
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadCurrentNickname() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final nickname = doc.data()?['nickname'] ?? '닉네임 없음';

    if (mounted) {
      setState(() {
        _currentNickname = nickname;
        _currentNicknameHint = "현재 닉네임: $nickname";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double fieldHeight = 52.0;
    const double horizontalPageMargin = 20.0;
    const double borderRadiusValue = 8.0;

    return Scaffold(
      backgroundColor: WHITE,
      appBar: AppBar(
        backgroundColor: WHITE,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: GRAYSCALE_LABEL_950),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          "닉네임 변경",
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPageMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 40),
            Text(
              "변경하실 닉네임을 입력해주세요",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: GRAYSCALE_LABEL_900,
              ),
            ),
            SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: fieldHeight,
                    child: TextField(
                      controller: _nicknameController,
                      onChanged: _onNicknameChanged,
                      decoration: InputDecoration(
                        hintText: _currentNicknameHint,
                        hintStyle: TextStyle(
                          color: GRAYSCALE_LABEL_500,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: WHITE,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            borderRadiusValue,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            borderRadiusValue,
                          ),
                          borderSide: BorderSide(
                            color: GRAYSCALE_LABEL_400,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            borderRadiusValue,
                          ),
                          borderSide: BorderSide(
                            color: GRAYSCALE_LABEL_700,
                            width: 1.0,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: (fieldHeight - 20) / 2,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: GRAYSCALE_LABEL_950,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                if (!_isNicknameChangeConfirmed)
                  SizedBox(
                    height: fieldHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_enteredNickname.isEmpty ||
                            _nicknameController.text == initialNickname) {
                          ();
                        } else {
                          _showConfirmationDialog();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_enteredNickname.isEmpty ||
                                    _nicknameController.text == initialNickname)
                                ? GRAYSCALE_LABEL_200
                                : ORANGE_PRIMARY_600,
                        foregroundColor: WHITE,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            borderRadiusValue,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        elevation: 0,
                      ),
                      child: Text(
                        "변경하기",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_enteredNickname.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  "변경할 닉네임을 입력해주세요.",
                  style: TextStyle(fontSize: 14, color: GRAYSCALE_LABEL_700),
                ),
              ),
            if (_enteredNickname.isNotEmpty && !_isNicknameChangeConfirmed)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  "변경 전 닉네임: $initialNickname",
                  style: TextStyle(fontSize: 14, color: GRAYSCALE_LABEL_700),
                ),
              ),
            if (_isNicknameChangeConfirmed &&
                _nicknameController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  "닉네임이 '${_currentNicknameHint.substring(_currentNicknameHint.indexOf(':') + 2)}' (으)로 변경되었습니다.",
                  style: TextStyle(
                    fontSize: 14,
                    color: GREEN_SUCCESS_TEXT_50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            SizedBox(height: _isNicknameChangeConfirmed ? 60 : 0),
          ],
        ),
      ),
    );
  }
}
