import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/model/step_model.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:myway/screen/result/tracking_result_screen.dart';
import 'package:provider/provider.dart';

class CourceNameScreen extends StatefulWidget {
  final StepModel stepModel;
  const CourceNameScreen({super.key, required this.stepModel});

  @override
  State<CourceNameScreen> createState() => _CourceNameScreenState();
}

class _CourceNameScreenState extends State<CourceNameScreen> {
  final TextEditingController courseNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final stepProvider = Provider.of<StepProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '산책 완료',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
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
                padding: EdgeInsets.only(bottom: 362),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    stepProvider.formattedStopTime,
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  SizedBox(width: 20),
                  Text(
                    '중앙공원',
                    style: TextStyle(
                      color: Colors.black,
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
                  Text(
                    '제목',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: courseNameController,
                    cursorColor: ORANGE_PRIMARY_500,
                    decoration: InputDecoration(
                      labelText: '코스 이름을 설정해주세요',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: GRAYSCALE_LABEL_400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: GRAYSCALE_LABEL_400),
                      ),
                    ),
                  ),
                  SizedBox(height: 150),
                  GestureDetector(
                    onTap: () async {
                      // 현재 인증된 사용자 확인
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
                          'login',
                          (route) => false,
                        );
                        return;
                      }
                      try {
                        await _firestore
                            .collection('trackingResult')
                            .doc(currentUser.uid)
                            .set({
                              'TrackingResult': FieldValue.arrayUnion([
                                widget.stepModel.toJson(),
                              ]),
                            }, SetOptions(merge: true));
                        print('산책결과가 FireStore에 저장되었습니다.');
                      } catch (firestoreError) {
                        print('Firestore 저장 오류: $firestoreError');
                      }
                      final courseName = courseNameController.text;
                      final result = widget.stepModel;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => TrackingResultScreen(
                                result: result,
                                courseName: courseName,
                              ),
                        ),
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: ORANGE_PRIMARY_500,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '다음',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
