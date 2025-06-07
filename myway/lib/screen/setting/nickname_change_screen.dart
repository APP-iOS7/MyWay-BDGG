import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/screen/alert/dialog.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../provider/user_provider.dart';
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
  String _currentNicknameHint = "현재 닉네임: ";
  String? _currentNickname;
  String initialNickname = '';
  String validationLabelString = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadCurrentNickname();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
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
      return;
    }
    if (_nicknameController.text ==
            _currentNicknameHint.substring(
              _currentNicknameHint.indexOf(':') + 2,
            ) &&
        _currentNicknameHint.startsWith("현재 닉네임:")) {
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: '닉네임 변경',
          content: "'${_nicknameController.text}' (으)로 변경하시겠습니까?",
          onConfirm: nicknameChange,
        );
      },
    );
  }

  void nicknameChange() async {
    try {
      final newNickname = _nicknameController.text.trim();
      await context.read<UserProvider>().updateNickname(newNickname);
      await FirebaseAuth.instance.currentUser?.updateDisplayName(newNickname);
      if (!mounted) return;

      if (mounted) {
        setState(() {
          _isNicknameChangeConfirmed = true;
          _currentNicknameHint = "현재 닉네임: $_currentNickname";
          _enteredNickname = "";
        });
      }
      Navigator.pop(context);
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.flat,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: Duration(seconds: 2),
        title: Text('닉네임이 변경되었습니다.'),
      );
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: Duration(seconds: 2),
          title: Text('닉네임 변경 실패: ${e.toString()}'),
        );
      }
      print("닉네임 변경 실패: $e");
    }
  }

  Future<void> _loadCurrentNickname() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final nickname = doc.data()?['username'] ?? '닉네임 없음';

    if (mounted) {
      setState(() {
        _currentNickname = nickname;
        _currentNicknameHint = "현재 닉네임: $nickname";
      });
    }
    print(nickname);
    initialNickname = nickname;
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
                      cursorColor: ORANGE_PRIMARY_500,
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
                            color: ORANGE_PRIMARY_500,
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
                                ? GRAYSCALE_LABEL_300
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
          ],
        ),
      ),
    );
  }
}
