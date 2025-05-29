import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/const/colors.dart';

class FindPasswordScreen extends StatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  State<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool isValid = false;
  String label = '';

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();

    RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      if (mounted) {
        setState(() {
          label = "유효하지 않은 이메일 형식입니다.";
        });
      }
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("비밀번호 재설정 이메일이 전송되었습니다.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("이메일 전송 실패: ${e.toString()}")));
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPageMargin = 20.0;
    const double fieldHeight = 52.0;
    const double borderRadiusValue = 8.0;

    return Scaffold(
      backgroundColor: WHITE,
      appBar: AppBar(
        backgroundColor: WHITE,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: GRAYSCALE_LABEL_950),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          "비밀번호 찾기",
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 30),
              Text(
                "이메일 입력",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: GRAYSCALE_LABEL_900,
                ),
              ),
              SizedBox(height: 5),
              SizedBox(
                height: fieldHeight,
                child: TextField(
                  cursorColor: ORANGE_PRIMARY_500,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() {
                      isValid = value.trim().isNotEmpty;
                      label = '';
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "비밀번호 재설정 링크를 받을 이메일을 입력하세요",
                    hintStyle: TextStyle(
                      color: GRAYSCALE_LABEL_500,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: WHITE,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusValue),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusValue),
                      borderSide: BorderSide(
                        color: GRAYSCALE_LABEL_400,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusValue),
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
                  style: TextStyle(fontSize: 14, color: GRAYSCALE_LABEL_950),
                ),
              ),
              Text(
                label,
                style: TextStyle(color: GRAYSCALE_LABEL_800, fontSize: 14),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: fieldHeight,
                child: ElevatedButton(
                  onPressed: () {
                    isValid ? _sendPasswordResetEmail() : null;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isValid ? ORANGE_PRIMARY_500 : GRAYSCALE_LABEL_300,
                    foregroundColor: GRAYSCALE_LABEL_950,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadiusValue),
                    ),
                    elevation: 0,
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text("이메일 전송", style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
