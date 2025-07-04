import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/screen/home/home_screen.dart';
import 'package:myway/screen/home/my_page_screen.dart';
import 'package:myway/screen/home/park_list_screen.dart';
import 'package:myway/screen/result/activity_log_screen.dart';
import 'package:myway/temp/park_recommend_screen.dart';

class BottomTabBar extends StatefulWidget {
  const BottomTabBar({super.key});

  @override
  State<BottomTabBar> createState() => _BottomTabBarState();
}

class _BottomTabBarState extends State<BottomTabBar> {
  final List<Widget> _tabList = [
    ParkRecommendScreen(), // 추천코스 탭
    ParkListScreen(), // 공원찾기 탭
    HomeScreen(),
    ActivityLogScreen(),
    MyPageScreen(),
  ];
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabList),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  spreadRadius: 1,
                  blurRadius: 7,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: ORANGE_PRIMARY_500,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              items: [
                BottomNavigationBarItem(
                  icon: _buildTabIcon(
                    0,
                    CupertinoIcons.map,
                    CupertinoIcons.map_fill,
                  ),
                  label: '추천코스',
                ),
                BottomNavigationBarItem(
                  icon: _buildTabIcon(
                    1,
                    CupertinoIcons.search,
                    CupertinoIcons.search,
                  ),
                  label: '공원찾기',
                ),
                BottomNavigationBarItem(
                  icon: _buildTabIcon(2, Icons.home, Icons.home_sharp),
                  label: '홈',
                ),
                BottomNavigationBarItem(
                  icon: _buildTabIcon(
                    3,
                    CupertinoIcons.chart_bar_alt_fill,
                    CupertinoIcons.chart_bar_alt_fill,
                  ),
                  label: '활동기록',
                ),
                BottomNavigationBarItem(
                  icon: _buildTabIcon(
                    4,
                    CupertinoIcons.person,
                    CupertinoIcons.person_fill,
                  ),
                  label: '내정보',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabIcon(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
  ) {
    bool isSelected = _selectedIndex == index;
    return Icon(
      isSelected ? selectedIcon : unselectedIcon,
      color: isSelected ? ORANGE_PRIMARY_500 : Colors.grey,
    );
  }
}
