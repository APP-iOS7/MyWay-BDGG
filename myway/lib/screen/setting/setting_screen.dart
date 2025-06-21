import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/screen/alert/dialog.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WHITE,
      appBar: AppBar(
        backgroundColor: WHITE,
        centerTitle: true,
        title: Text(
          '설정',
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                height: 129,
                decoration: BoxDecoration(
                  color: GRAYSCALE_LABEL_50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'changeNickname');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '닉네임 변경',
                              style: TextStyle(
                                color: GRAYSCALE_LABEL_950,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(context, 'changeNickname');
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: GRAYSCALE_LABEL_950,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'changePassword');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '비밀번호 변경',
                              style: TextStyle(
                                color: GRAYSCALE_LABEL_950,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(context, 'changePassword');
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: GRAYSCALE_LABEL_950,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: GRAYSCALE_LABEL_50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 30.0, right: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '버전',
                      style: TextStyle(
                        color: GRAYSCALE_LABEL_950,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '1.0.0',
                      style: TextStyle(
                        color: GRAYSCALE_LABEL_950,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                height: 309,
                decoration: BoxDecoration(
                  color: GRAYSCALE_LABEL_50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'noticeList');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '공지사항',
                              style: TextStyle(
                                color: GRAYSCALE_LABEL_950,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(context, 'noticeList');
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: GRAYSCALE_LABEL_950,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'customerCenter');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '고객센터',
                              style: TextStyle(
                                color: GRAYSCALE_LABEL_950,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(context, 'customerCenter');
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: GRAYSCALE_LABEL_950,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'terms');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '이용약관',
                              style: TextStyle(
                                color: GRAYSCALE_LABEL_950,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(context, 'terms');
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: GRAYSCALE_LABEL_950,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'policy');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '개인정보 처리방침',
                              style: TextStyle(
                                color: GRAYSCALE_LABEL_950,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(context, 'policy');
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: GRAYSCALE_LABEL_950,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '로그아웃',
                              style: TextStyle(
                                color: RED_DANGER_TEXT_50,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
