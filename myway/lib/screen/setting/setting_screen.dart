import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/screen/alert/dialog.dart';

import '../notice/notice_list_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: WHITE,
        title: Text(
          '설정',
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: GRAYSCALE_LABEL_50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    text: '닉네임 변경',
                    onTap: () => Navigator.pushNamed(context, 'changeNickname'),
                  ),

                  _buildSettingItem(
                    text: '비밀번호 변경',
                    onTap: () => Navigator.pushNamed(context, 'changePassword'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            Container(
              width: double.infinity,
              height: 60,
              padding: EdgeInsets.only(left: 20, right: 20),
              decoration: BoxDecoration(
                color: GRAYSCALE_LABEL_50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('버전', style: TextStyle(fontSize: 16)),
                  Text('1.0.0', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: GRAYSCALE_LABEL_50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    text: '공지사항',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return const NoticeListScreen();
                            },
                          ),
                        ),
                  ),
                  _buildSettingItem(
                    text: '고객센터',
                    onTap: () => Navigator.pushNamed(context, 'customerCenter'),
                  ),
                  _buildSettingItem(text: '개인정보 처리방침', onTap: () {}),
                  _buildSettingItem(
                    showArrow: false,
                    text: '로그아웃',
                    textColor: RED_DANGER_TEXT_50,
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder:
                            (context) => ConfirmationDialog(
                              title: '로그아웃',
                              content: '로그아웃 하시겠습니까?',
                              onConfirm: () async {
                                // 로그아웃 처리
                                await FirebaseAuth.instance.signOut();
                                // 로그인 화면으로 이동
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  'signIn',
                                  (route) => false,
                                );
                              },
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String text,
    required VoidCallback onTap,
    Color textColor = Colors.black,
    bool showArrow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        padding: EdgeInsets.only(left: 20, right: 20),
        alignment: Alignment.centerLeft,

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: TextStyle(fontSize: 16, color: textColor)),
            if (showArrow)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
