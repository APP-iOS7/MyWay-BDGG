import 'package:flutter/material.dart';

import '../const/colors.dart';

class CustomerCenterScreen extends StatelessWidget {
  const CustomerCenterScreen({super.key});

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
              _buildSettingItem(text: '1:1 문의하기', onTap: () {}),
              _buildSettingItem(text: '회원탈퇴', onTap: () {}),
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
            Text(text, style: const TextStyle(fontSize: 16)),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
