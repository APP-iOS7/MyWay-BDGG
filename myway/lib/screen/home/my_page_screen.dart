import 'package:contained_tab_bar_view/contained_tab_bar_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/provider/user_provider.dart';
import 'package:myway/screen/home/mycourse_screen.dart';
import 'package:myway/screen/like/favorite_park_screen.dart';
import 'package:provider/provider.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset('assets/images/logo.png', height: 70),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: Text(
              nickname,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: Text(
              '@$email',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: GRAYSCALE_LABEL_500,
              ),
            ),
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
