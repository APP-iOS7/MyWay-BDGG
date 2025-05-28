import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? cancelText;
  final String? confirmText;
  final VoidCallback onConfirm;
  final Color confirmColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.cancelText,
    this.confirmText,
    this.confirmColor = ORANGE_PRIMARY_500,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(
        title,
        style: const TextStyle(
          color: GRAYSCALE_LABEL_900,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          color: GRAYSCALE_LABEL_700,
          fontWeight: FontWeight.w500,
        ),
      ),
      actionsPadding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
      actions: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: GRAYSCALE_LABEL_100,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  cancelText ?? '아니요',
                  style: TextStyle(color: GRAYSCALE_LABEL_950),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: confirmColor,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  onConfirm();
                  Navigator.pop(context);
                },
                child: Text(
                  confirmText ?? '네',
                  style: TextStyle(color: GRAYSCALE_LABEL_950),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
