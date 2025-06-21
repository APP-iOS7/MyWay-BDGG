import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WHITE,
      appBar: AppBar(
        title: const Text(
          '개인정보 처리방침',
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
              title: '제1조 (총칙)',
              content:
                  'MyWay(이하 "회사")는 이용자의 개인정보를 중요시하며, "정보통신망 이용촉진 및 정보보호"에 관한 법률을 준수하고 있습니다. 회사는 개인정보처리방침을 통하여 이용자가 제공하는 개인정보가 어떠한 용도와 방식으로 이용되고 있으며, 개인정보보호를 위해 어떠한 조치가 취해지고 있는지 알려드립니다.',
            ),
            _PolicySection(
              title: '제2조 (개인정보의 수집 및 이용 목적)',
              content:
                  '''회사는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.
1. 회원 가입 및 관리: 회원 식별, 회원자격 유지·관리, 서비스 부정이용 방지, 각종 고지·통지
2. 서비스 제공: 경로 기록, 걸음 수 측정, 맞춤형 서비스 제공
3. 서비스 개선 및 신규 서비스 개발: 인구통계학적 특성에 따른 서비스 제공, 접속 빈도 파악 또는 회원의 서비스 이용에 대한 통계''',
            ),
            _PolicySection(
              title: '제3조 (수집하는 개인정보의 항목 및 수집방법)',
              content: '''1. 수집 항목
  - 필수항목: 이메일 주소, 비밀번호, 닉네임
  - 선택항목(서비스 이용 과정에서 자동 생성): 위치 정보, 신체 활동 정보(걸음 수), 기기 정보(OS, 기기 모델명)
2. 수집 방법
  - 회원가입 및 서비스 이용 과정에서 이용자가 개인정보 수집에 대해 동의를 하고 직접 정보를 입력하는 경우
  - 서비스 이용 과정에서 자동으로 수집되는 경우''',
            ),
            _PolicySection(
              title: '제4조 (개인정보의 보유 및 이용기간)',
              content:
                  '회사는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의 받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다. 원칙적으로, 개인정보 수집 및 이용목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다. 단, 관계법령의 규정에 의하여 보존할 필요가 있는 경우 회사는 아래와 같이 관계법령에서 정한 일정한 기간 동안 회원정보를 보관합니다.\n\n- 계약 또는 청약철회 등에 관한 기록: 5년 (전자상거래 등에서의 소비자보호에 관한 법률)\n- 대금결제 및 재화 등의 공급에 관한 기록: 5년 (전자상거래 등에서의 소비자보호에 관한 법률)\n- 소비자의 불만 또는 분쟁처리에 관한 기록: 3년 (전자상거래 등에서의 소비자보호에 관한 법률)\n- 통신비밀보호법에 따른 통신사실확인자료: 3개월',
            ),
            _PolicySection(
              title: '제5조 (개인정보의 파기절차 및 방법)',
              content:
                  '회사는 원칙적으로 개인정보 수집 및 이용목적이 달성된 후에는 해당 정보를 지체없이 파기합니다. 파기절차 및 방법은 다음과 같습니다.\n\n1. 파기절차: 이용자가 회원가입 등을 위해 입력한 정보는 목적이 달성된 후 별도의 DB로 옮겨져(종이의 경우 별도의 서류함) 내부 방침 및 기타 관련 법령에 의한 정보보호 사유에 따라(보유 및 이용기간 참조) 일정 기간 저장된 후 파기됩니다. 별도 DB로 옮겨진 개인정보는 법률에 의한 경우가 아니고서는 보유되는 이외의 다른 목적으로 이용되지 않습니다.\n2. 파기방법: 전자적 파일형태로 저장된 개인정보는 기록을 재생할 수 없는 기술적 방법을 사용하여 삭제합니다.',
            ),
            _PolicySection(
              title: '제6조 (이용자의 권리와 그 행사방법)',
              content:
                  '이용자는 언제든지 등록되어 있는 자신의 개인정보를 조회하거나 수정할 수 있으며 가입해지를 요청할 수도 있습니다. 이용자의 개인정보 조회, 수정을 위해서는 \n개인정보변경 (또는 "회원정보" 수정 등)을, 가입해지(동의철회)를 위해서는 "회원탈퇴" 를 클릭하여 본인 확인 절차를 거치신 후 직접 열람, 정정 또는 탈퇴가 가능합니다.',
            ),
            _PolicySection(
              title: '제7조 (개인정보 보호책임자)',
              content:
                  '회사는 이용자의 개인정보를 보호하고 개인정보와 관련한 불만을 처리하기 위하여 아래와 같이 관련 부서 및 개인정보 보호책임자를 지정하고 있습니다.\n\n- 개인정보 보호책임자: [김덕원]\n- 이메일: [khjs7878@naver.com]\n\n이용자는 회사의 서비스를 이용하시며 발생하는 모든 개인정보보호 관련 민원을 개인정보관리책임자 혹은 담당부서로 신고하실 수 있습니다. 회사는 이용자들의 신고사항에 대해 신속하게 충분한 답변을 드릴 것입니다.',
            ),
            _PolicySection(
              title: '제8조 (고지의 의무)',
              content:
                  '현 개인정보처리방침 내용 추가, 삭제 및 수정이 있을 시에는 개정 최소 7일전부터 서비스 내 "공지사항"을 통해 고지할 것입니다.',
            ),
            SizedBox(height: 20),
            Text(
              '본 방침은 2025년 6월 21일부터 시행됩니다.',
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
