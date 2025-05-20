import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('설정'), centerTitle: true),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _buildSettingItem(
              text: '닉네임 변경',
              onTap: () => Navigator.pushNamed(context, 'changeNickname'),
            ),

            _buildSettingItem(
              text: '비밀번호 변경',
              onTap: () => Navigator.pushNamed(context, 'changePassword'),
            ),
            SizedBox(height: 40),

            Container(
              width: double.infinity,
              height: 60,
              padding: EdgeInsets.only(left: 20, right: 20),
              decoration: BoxDecoration(
                color: Color(0xffF0FaFC),
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

            SizedBox(height: 40),
            _buildSettingItem(
              text: '공지사항',
              onTap: () {
                // 공지사항 이동
              },
            ),
            _buildSettingItem(
              text: '고객센터',
              onTap: () => Navigator.pushNamed(context, 'customerCenter'),
            ),
            _buildSettingItem(text: '개인정보 처리방침', onTap: () {}),
            _buildSettingItem(
              text: '로그아웃',
              textColor: Colors.red,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('로그아웃'),
                        content: Text('정말 로그아웃 하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('로그아웃'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('취소'),
                          ),
                        ],
                      ),
                );

                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    'signIn',
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String text,
    required VoidCallback onTap,
    Color backgroundColor = const Color(0xffF0FaFC),
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
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
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
