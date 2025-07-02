import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:toastification/toastification.dart';

import '../../const/custome_button.dart';
import 'course_detail_screen.dart';

class MyCourseScreen extends StatefulWidget {
  const MyCourseScreen({super.key});

  @override
  State<MyCourseScreen> createState() => _MyCourseScreenState();
}

class _MyCourseScreenState extends State<MyCourseScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isEditing = false;
  final ValueNotifier<List<bool>> _selectedNotifier = ValueNotifier([]);

  void toggleEditing(int count) {
    setState(() {
      isEditing = !isEditing;
      _selectedNotifier.value = List<bool>.filled(count, false);
    });
  }

  Future<void> deleteSelected(List<dynamic> trackingResult) async {
    final docRef = _firestore
        .collection('trackingResult')
        .doc(_auth.currentUser?.uid);

    final current = _selectedNotifier.value;
    final newList = <dynamic>[];
    int deletedCount = 0;
    for (int i = 0; i < trackingResult.length; i++) {
      if (!current[i]) {
        newList.add(trackingResult[i]);
      } else {
        deletedCount++;
      }
    }

    await docRef.update({'TrackingResult': newList});
    setState(() {
      isEditing = false;
    });

    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: Duration(seconds: 2),
      title: Text('$deletedCount개의 코스 삭제완료.'),
    );
  }

  @override
  void dispose() {
    _selectedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final availableHeight = screenSize.height - padding.top - padding.bottom;

    return StreamBuilder<DocumentSnapshot>(
      stream:
          _firestore
              .collection('trackingResult')
              .doc(_auth.currentUser?.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildScaffoldWithBody(
            const Center(child: Text('에러가 발생했습니다.')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildScaffoldWithBody(
            const Center(
              child: CircularProgressIndicator(color: ORANGE_PRIMARY_500),
            ),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final trackingResult = List<Map<String, dynamic>>.from(
          data['TrackingResult'] ?? [],
        );

        if (!snapshot.hasData ||
            !snapshot.data!.exists ||
            trackingResult.isEmpty) {
          return _buildScaffoldWithBody(
            Padding(
              padding: EdgeInsets.only(top: availableHeight * 0.1),
              child: Column(
                children: [
                  Icon(Icons.directions_walk, size: availableHeight * 0.05),
                  SizedBox(height: availableHeight * 0.02),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      '저장된 기록이 없습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: GRAYSCALE_LABEL_800,
                        fontWeight: FontWeight.bold,
                        fontSize: screenSize.width * 0.05,
                      ),
                    ),
                  ),
                  Text(
                    '산책을 시작해서 나만의 코스를 만들어보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GRAYSCALE_LABEL_600,
                      fontWeight: FontWeight.w500,
                      fontSize: screenSize.width * 0.04,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (_selectedNotifier.value.length != trackingResult.length) {
          _selectedNotifier.value = List<bool>.filled(
            trackingResult.length,
            false,
          );
        }

        trackingResult.sort(
          (a, b) =>
              DateTime.parse(b['종료시간']).compareTo(DateTime.parse(a['종료시간'])),
        );

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                    child: Text(
                      '나의 코스',
                      style: TextStyle(
                        color: GRAYSCALE_LABEL_950,
                        fontSize: screenSize.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  isEditing
                      ? Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () => deleteSelected(trackingResult),
                              style: customTextButtonStyle(),
                              child: Text(
                                '삭제',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: screenSize.width * 0.035,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  () => setState(() => isEditing = false),
                              style: customTextButtonStyle(),
                              child: Text(
                                '취소',
                                style: TextStyle(
                                  color: GRAYSCALE_LABEL_900,
                                  fontWeight: FontWeight.w500,
                                  fontSize: screenSize.width * 0.035,
                                ),
                              ),
                            ),
                            ValueListenableBuilder(
                              valueListenable: _selectedNotifier,
                              builder: (context, selected, _) {
                                return Text(
                                  '${selected.where((e) => e).length}개 선택',
                                  style: TextStyle(
                                    color: GRAYSCALE_LABEL_900,
                                    fontWeight: FontWeight.w500,
                                    fontSize: screenSize.width * 0.035,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                      : TextButton(
                        onPressed: () => toggleEditing(trackingResult.length),
                        style: customTextButtonStyle(),
                        child: Text(
                          '편집',
                          style: TextStyle(
                            color: GRAYSCALE_LABEL_900,
                            fontWeight: FontWeight.w500,
                            fontSize: screenSize.width * 0.035,
                          ),
                        ),
                      ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.05,
                  ),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      childAspectRatio: 0.85,
                      crossAxisCount: 2,
                      crossAxisSpacing: screenSize.width * 0.02,
                      mainAxisSpacing: screenSize.width * 0.02,
                    ),
                    itemCount: trackingResult.length,
                    itemBuilder: (context, index) {
                      final result = trackingResult[index];
                      final imageUrl = result['이미지 Url'] ?? '';

                      return InkWell(
                        focusColor: WHITE,
                        hoverColor: WHITE,
                        highlightColor: WHITE,
                        onTap:
                            isEditing
                                ? null
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              CourseDetailScreen(data: result),
                                    ),
                                  );
                                },
                        child: Stack(
                          children: [
                            Card(
                              color: WHITE,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child:
                                        imageUrl.isNotEmpty
                                            ? ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(12),
                                                  ),
                                              child: Image.network(
                                                imageUrl,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                            : Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(12),
                                                    ),
                                              ),
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: screenSize.width * 0.1,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        screenSize.width * 0.025,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              result['코스이름'] ?? '',
                                              style: TextStyle(
                                                fontSize:
                                                    screenSize.width * 0.035,
                                                fontWeight: FontWeight.w600,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              maxLines: 1,
                                            ),
                                          ),
                                          SizedBox(
                                            height: screenSize.width * 0.01,
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: screenSize.width * 0.03,
                                                color: BLUE_SECONDARY_700,
                                              ),
                                              SizedBox(
                                                width: screenSize.width * 0.01,
                                              ),
                                              Flexible(
                                                child: Text(
                                                  result['종료시간'] ?? '',
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenSize.width *
                                                        0.035,
                                                    color: GRAYSCALE_LABEL_800,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isEditing)
                              Positioned(
                                top: 1,
                                right: 1,
                                child: ValueListenableBuilder<List<bool>>(
                                  valueListenable: _selectedNotifier,
                                  builder: (context, selected, _) {
                                    return Checkbox(
                                      activeColor: ORANGE_PRIMARY_500,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      checkColor: Colors.white,
                                      overlayColor: WidgetStateProperty.all(
                                        Colors.transparent,
                                      ),
                                      value: selected[index],
                                      onChanged: (val) {
                                        final copy = List<bool>.from(selected);
                                        copy[index] = val!;
                                        _selectedNotifier.value = copy;
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Scaffold _buildScaffoldWithBody(Widget bodyContent) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: WHITE,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          '나의 코스',
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: screenSize.width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: bodyContent,
    );
  }
}
