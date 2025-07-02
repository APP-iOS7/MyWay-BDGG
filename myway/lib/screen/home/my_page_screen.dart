import 'package:contained_tab_bar_view/contained_tab_bar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/provider/profile_provider.dart';
import 'package:myway/provider/user_provider.dart';
import 'package:myway/screen/home/mycourse_screen.dart';
import 'package:myway/screen/like/favorite_park_screen.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 프로필 이미지 로드
      Future.microtask(
        () => Provider.of<ProfileProvider>(
          context,
          listen: false,
        ).loadProfileImage(user.uid),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    final userProvider = context.watch<UserProvider>();
    final nickname =
        userProvider.nickname ?? userProvider.currentUser?.displayName ?? '사용자';
    final email =
        userProvider.email ?? userProvider.currentUser?.email ?? '이메일';
    return Scaffold(
      backgroundColor: GRAYSCALE_LABEL_50,
      appBar: AppBar(
        backgroundColor: GRAYSCALE_LABEL_50,
        elevation: 0,
        title: Text(
          '내 정보',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, 'setting');
            },
            icon: const Icon(CupertinoIcons.bars, size: 30),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 20.0,
                      left: 20.0,
                      right: 20.0,
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          profileProvider.image != null
                              ? FileImage(profileProvider.image!)
                              : (profileProvider.imageUrl != null
                                  ? NetworkImage(profileProvider.imageUrl!)
                                  : null),
                      child:
                          (profileProvider.image == null &&
                                  profileProvider.imageUrl == null)
                              ? Icon(
                                Icons.person,
                                size: 40,
                                color: GRAYSCALE_LABEL_500,
                              )
                              : null,
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          await profileProvider.pickImage();
                          if (user != null && profileProvider.image != null) {
                            await profileProvider.uploadImage(user.uid);
                            toastification.show(
                              context: context,
                              type: ToastificationType.success,
                              alignment: Alignment.bottomCenter,
                              autoCloseDuration: const Duration(seconds: 2),
                              title: Text('프로필 이미지 업로드 완료'),
                            );
                          } else {
                            toastification.show(
                              context: context,
                              type: ToastificationType.error,
                              alignment: Alignment.bottomCenter,
                              autoCloseDuration: const Duration(seconds: 2),
                              title: Text('프로필 이미지를 먼저 선택해주세요.'),
                            );
                          }
                        } catch (e) {
                          toastification.show(
                            context: context,
                            type: ToastificationType.error,
                            alignment: Alignment.bottomCenter,
                            autoCloseDuration: const Duration(seconds: 2),
                            title: Text('프로필 이미지 업로드 실패: $e'),
                          );
                        }
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit, size: 20),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(
                  top: 10.0,
                  left: 20.0,
                  right: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '@$email',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: GRAYSCALE_LABEL_500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Container(
              color: Colors.white,
              width: double.infinity,
              child: ContainedTabBarView(
                tabs: [Text('나의 코스'), Text('찜한 공원')],
                views: [MyCourseScreen(), FavoriteParkScreen()],
                onChange: (index) => print(index),
                tabBarProperties: TabBarProperties(
                  indicatorColor: ORANGE_PRIMARY_500,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: ORANGE_PRIMARY_500,
                  unselectedLabelColor: GRAYSCALE_LABEL_500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
