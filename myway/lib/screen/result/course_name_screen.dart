import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/model/step_model.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:myway/screen/result/tracking_result_screen.dart';
import 'package:provider/provider.dart';

class CourseNameScreen extends StatefulWidget {
  final StepModel stepModel;
  final Uint8List courseImage;
  const CourseNameScreen({
    super.key,
    required this.courseImage,
    required this.stepModel,
  });

  @override
  State<CourseNameScreen> createState() => _CourseNameScreenState();
}

class _CourseNameScreenState extends State<CourseNameScreen> {
  final TextEditingController courseNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final repaintBoundary = GlobalKey();
  late Uint8List imageBytes;

  @override
  void initState() {
    super.initState();
  }

  Future<String?> imageUpload() async {
    try {
      // Storage업로드
      final fileName =
          'walk_result_map${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = FirebaseStorage.instance.ref().child('walk_result/$fileName');

      final uploadTask = await ref.putData(widget.courseImage);

      // 업로드 완료 후 URL 얻기
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('업로드 및 저장 실패: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = Provider.of<StepProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
            stepProvider.resetTracking();
          },
          icon: Icon(Icons.close_rounded, color: GRAYSCALE_LABEL_950),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          '산책 완료',
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.only(bottom: 25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: GRAYSCALE_LABEL_300,
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: repaintBoundary,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.memory(
                          widget.courseImage,
                          gaplessPlayback: true,
                          width: double.infinity,
                          height: 364,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Text('이미지를 불러올 수 없습니다'),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '제목',
                                style: TextStyle(
                                  color: GRAYSCALE_LABEL_950,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                stepProvider.formattedStopTime,
                                style: TextStyle(color: GRAYSCALE_LABEL_950),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: stepProvider.courseName,
                            cursorColor: ORANGE_PRIMARY_500,
                            decoration: InputDecoration(
                              labelText: '코스 이름을 설정해주세요',
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: ORANGE_PRIMARY_500,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: ORANGE_PRIMARY_500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                '중앙공원',
                                style: TextStyle(
                                  color: GRAYSCALE_LABEL_950,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.stepModel.distance,
                                    style: TextStyle(
                                      color: GRAYSCALE_LABEL_950,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'km',
                                    style: TextStyle(
                                      color: GRAYSCALE_LABEL_950,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '거리',
                                style: TextStyle(
                                  color: GRAYSCALE_LABEL_500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.stepModel.duration,
                                    style: TextStyle(
                                      color: GRAYSCALE_LABEL_950,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '시간',
                                    style: TextStyle(
                                      color: GRAYSCALE_LABEL_500,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.stepModel.steps}',
                                    style: TextStyle(
                                      color: GRAYSCALE_LABEL_950,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '걸음수',
                                    style: TextStyle(
                                      color: GRAYSCALE_LABEL_500,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap:
                    stepProvider.isCourseNameValid
                        ? () async {
                          User? currentUser = _auth.currentUser;
                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '코스이름을 지정하기 위해선 로그인이 필요합니다.',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              'signIn',
                              (route) => false,
                            );
                            return;
                          }

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            barrierColor: GRAYSCALE_LABEL_950.withValues(
                              alpha: 0.5,
                            ),
                            builder: (context) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: ORANGE_PRIMARY_500,
                                ),
                              );
                            },
                          );

                          try {
                            final imageUrl = await imageUpload();

                            final result = stepProvider.createStepModel(
                              imageUrl: imageUrl ?? '',
                            );

                            await _firestore
                                .collection('trackingResult')
                                .doc(currentUser.uid)
                                .set({
                                  'TrackingResult': FieldValue.arrayUnion([
                                    result.toJson(),
                                  ]),
                                }, SetOptions(merge: true));

                            print('산책결과가 FireStore에 저장되었습니다.');

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TrackingResultScreen(
                                        result: result,
                                        courseName: result.courseName,
                                        courseImage: widget.courseImage,
                                      ),
                                ),
                              );
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '산책 결과가 저장되었습니다.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          } catch (e) {
                            print('Firestore 저장 오류: $e');

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '오류가 발생했습니다. 다시 시도해주세요.',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                        : null,

                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        stepProvider.isCourseNameValid
                            ? ORANGE_PRIMARY_500
                            : GRAYSCALE_LABEL_300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '저장 및 공유',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: GRAYSCALE_LABEL_950.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
