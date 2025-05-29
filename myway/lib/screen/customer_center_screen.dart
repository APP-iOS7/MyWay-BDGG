import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/screen/alert/dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../const/colors.dart';

class CustomerCenterScreen extends StatelessWidget {
  const CustomerCenterScreen({super.key});

  Future<void> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.delete();
        print('계정이 성공적으로 삭제되었습니다.');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print('로그인 이후에만 삭제할 수 있습니다. 다시 로그인 후 시도하세요.');
      } else {
        print('계정 삭제 실패: ${e.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WHITE,
      appBar: AppBar(
        backgroundColor: WHITE,
        elevation: 0,
        scrolledUnderElevation: 0,

        title: Text(
          '고객센터',
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: GRAYSCALE_LABEL_50,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingItem(
                text: '1:1 문의하기',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return ConfirmationDialog(
                        title: '1:1 문의하기',
                        content: '이메일로 전송됩니다. \n문의 내용을 작성해주세요.',
                        confirmText: '메일 작성',
                        cancelText: '취소',
                        onConfirm: () {
                          sendInquiryEmail(
                            'MyWay 1:1 문의',
                            '안녕하세요, MyWay입니다.\n\n문의 내용을 작성해주세요 :)',
                          );
                        },
                      );
                    },
                  );
                },
              ),
              _buildSettingItem(
                text: '회원탈퇴',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return ConfirmationDialog(
                        title: '회원탈퇴',
                        confirmText: '네',
                        cancelText: '아니요',
                        content: '계정을 삭제합니다. \n삭제한 이후에는 되돌릴 수 없습니다.',
                        onConfirm: () {
                          deleteAccount();
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        padding: const EdgeInsets.only(left: 20, right: 20),
        decoration: BoxDecoration(
          color: GRAYSCALE_LABEL_50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color:
                    text == '회원탈퇴' ? RED_DANGER_TEXT_50 : GRAYSCALE_LABEL_900,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void sendInquiryEmail(String title, String body) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'bhyn9785@naver.com',
      query: Uri.encodeFull('subject=$title&body=$body'),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw '메일 앱을 열 수 없습니다.';
    }
  }
}
