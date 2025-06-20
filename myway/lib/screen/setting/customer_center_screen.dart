import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/screen/alert/dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../const/colors.dart';

class CustomerCenterScreen extends StatefulWidget {
  const CustomerCenterScreen({super.key});

  @override
  State<CustomerCenterScreen> createState() => _CustomerCenterScreenState();
}

class _CustomerCenterScreenState extends State<CustomerCenterScreen> {
  Future<void> deleteAccount() async {
    if (!mounted) return; // 위젯이 마운트되어 있는지 확인
    
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.delete();
        print('계정이 성공적으로 삭제되었습니다.');
        
        // 위젯이 여전히 마운트되어 있는지 다시 확인
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, 'signIn', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print('로그인 이후에만 삭제할 수 있습니다. 다시 로그인 후 시도하세요.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('다시 로그인 후 시도해주세요.'),
              backgroundColor: RED_DANGER_TEXT_50,
            ),
          );
        }
      } else {
        print('계정 삭제 실패: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('계정 삭제 실패: ${e.message}'),
              backgroundColor: RED_DANGER_TEXT_50,
            ),
          );
        }
      }
    } catch (e) {
      print('예상치 못한 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예상치 못한 오류가 발생했습니다.'),
            backgroundColor: RED_DANGER_TEXT_50,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentContext = context;

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
                    builder: (dialogContext) {
                      return ConfirmationDialog(
                        title: '회원탈퇴',
                        confirmText: '네',
                        cancelText: '아니요',
                        content: '계정을 삭제합니다. \n삭제한 이후에는 되돌릴 수 없습니다.',
                        onConfirm: () async {
                          Navigator.of(dialogContext).pop();
                          // 다이얼로그를 닫은 후 알맞은 시점에 계정 삭제 실행
                          await deleteAccount();
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
