import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/screen/home/home_screen.dart';
import 'package:myway/screen/home/my_page_screen.dart';
import 'package:myway/screen/home/park_list_screen.dart';
import 'package:myway/screen/home/park_recommend_screen.dart';
import 'package:myway/screen/result/activity_log_screen.dart';

class CustomBottomTabBar extends StatefulWidget {
  const CustomBottomTabBar({super.key});

  @override
  State<CustomBottomTabBar> createState() => _CustomBottomTabBarState();
}

class _CustomBottomTabBarState extends State<CustomBottomTabBar> {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    ParkRecommendScreen(), // 추천코스 탭
    ParkListScreen(), // 공원찾기 탭
    HomeScreen(),
    ActivityLogScreen(),
    MyPageScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(5),
          boxShadow: [
            BoxShadow(
              color: GRAYSCALE_LABEL_500,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          height: 70,
          color: Colors.white,
          shape: CircularNotchedRectangle(),
          notchMargin: 10,
          child: Row(
            children: [
              // 왼쪽 2개
              _buildNavItem(
                CupertinoIcons.map,
                CupertinoIcons.map_fill,
                '추천코스',
                0,
              ),
              _buildNavItem(
                CupertinoIcons.search,
                CupertinoIcons.search,
                '공원찾기',
                1,
              ),

              // 가운데 Spacer (간격 조절)
              Spacer(flex: 2), // 또는 SizedBox(width: 원하는 값)
              // 가운데 텍스트
              Padding(
                padding: const EdgeInsets.only(top: 25.0),
                child: Text(
                  '산책시작',
                  style: TextStyle(
                    color:
                        _selectedIndex == 2
                            ? ORANGE_PRIMARY_500
                            : GRAYSCALE_LABEL_500,
                    fontSize: 12,
                    fontWeight:
                        _selectedIndex == 2
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              ),

              // 가운데 Spacer (간격 조절)
              Spacer(flex: 2), // 또는 SizedBox(width: 원하는 값)
              // 오른쪽 2개
              _buildNavItem(
                CupertinoIcons.chart_bar_alt_fill,
                CupertinoIcons.chart_bar_alt_fill,
                '활동기록',
                3,
              ),

              _buildNavItem(
                CupertinoIcons.person,
                CupertinoIcons.person_fill,
                '내정보',
                4,
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 6,
        onPressed: () => _onItemTapped(2),
        child: CircleAvatar(
          radius: 32,
          backgroundColor: ORANGE_PRIMARY_500,
          child: Icon(Icons.add, size: 40, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData unSelectedIcon,
    IconData selectedIcon,
    String label,
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        height: 60,
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unSelectedIcon,
              color: isSelected ? ORANGE_PRIMARY_500 : GRAYSCALE_LABEL_500,
            ),

            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? ORANGE_PRIMARY_500 : GRAYSCALE_LABEL_500,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
