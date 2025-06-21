import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WHITE,
      appBar: AppBar(
        title: const Text(
          '이용약관',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: WHITE,
        centerTitle: true,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PolicySection(
              title: '제1조 (목적)',
              content:
                  '이 약관은 MyWay(이하 "회사")가 제공하는 MyWay 및 관련 제반 서비스(이하 "서비스")의 이용과 관련하여 회사와 회원과의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.',
            ),
            _PolicySection(
              title: '제2조 (정의)',
              content:
                  '1. "서비스"라 함은 회사가 제공하는 위치 기반 산책 기록 및 관련 제반 기능을 의미합니다.\n2. "회원"이라 함은 회사의 서비스에 접속하여 이 약관에 따라 회사와 이용계약을 체결하고 회사가 제공하는 서비스를 이용하는 고객을 말합니다.\n3. "계정"이라 함은 회원의 식별과 서비스 이용을 위하여 회원이 정하고 회사가 승인하는 이메일 주소를 의미합니다.',
            ),
            _PolicySection(
              title: '제3조 (약관의 게시와 개정)',
              content:
                  '1. 회사는 이 약관의 내용을 회원이 쉽게 알 수 있도록 서비스 초기 화면에 게시합니다.\n2. 회사는 "약관의 규제에 관한 법률", "정보통신망 이용촉진 및 정보보호 등에 관한 법률(이하 "정보통신망법")" 등 관련법을 위배하지 않는 범위에서 이 약관을 개정할 수 있습니다.\n3. 회사가 약관을 개정할 경우에는 적용일자 및 개정사유를 명시하여 현행약관과 함께 제1항의 방식에 따라 그 개정약관의 적용일자 7일 전부터 적용일자 전일까지 공지합니다.',
            ),
            _PolicySection(
              title: '제4조 (회원의 의무)',
              content:
                  '1. 회원은 다음 행위를 하여서는 안 됩니다.\n  - 신청 또는 변경 시 허위내용의 등록\n  - 타인의 정보도용\n  - 회사가 게시한 정보의 변경\n  - 다른 회원의 개인정보를 무단으로 수집하는 행위\n  - 회사의 동의 없이 영리를 목적으로 서비스를 사용하는 행위\n  - 기타 불법적이거나 부당한 행위',
            ),
            _PolicySection(
              title: '제5조 (서비스의 제공 및 변경)',
              content:
                  '1. 회사는 회원에게 아래와 같은 서비스를 제공합니다.\n  - 위치 기반 산책 경로 기록 서비스\n  - 걸음 수 측정 및 통계 서비스\n  - 기타 회사가 추가 개발하거나 다른 회사와의 제휴계약 등을 통해 회원에게 제공하는 일체의 서비스\n2. 회사는 상당한 이유가 있는 경우에 운영상, 기술상의 필요에 따라 제공하고 있는 전부 또는 일부 서비스를 변경할 수 있습니다.',
            ),
            _PolicySection(
              title: '제6조 (책임제한)',
              content:
                  '1. 회사는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임이 면제됩니다.\n2. 회사는 회원의 귀책사유로 인한 서비스 이용의 장애에 대하여는 책임을 지지 않습니다.\n3. 회사는 서비스용 설비의 보수, 교체, 정기점검, 공사 등 부득이한 사유로 발생한 손해에 대한 책임이 면제됩니다.\n4. 회사는 위치정보의 정확성, 완전성, 신뢰성 등에 대하여 어떠한 보증도 하지 않으며, 회원이 서비스에 게재한 정보, 자료, 사실의 신뢰도, 정확성 등의 내용에 관하여는 책임을 지지 않습니다.',
            ),
            _PolicySection(
              title: '제7조 (준거법 및 재판관할)',
              content:
                  '1. 회사와 회원 간에 발생한 분쟁에 대하여는 대한민국법을 준거법으로 합니다.\n2. 회사와 회원 간 발생한 분쟁에 관한 소송은 민사소송법 상의 관할법원에 제소합니다.',
            ),
            SizedBox(height: 20),
            Text(
              '본 약관은 2025년 6월 21일부터 시행됩니다.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: GRAYSCALE_LABEL_950,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: GRAYSCALE_LABEL_800,
            ),
          ),
        ],
      ),
    );
  }
}
