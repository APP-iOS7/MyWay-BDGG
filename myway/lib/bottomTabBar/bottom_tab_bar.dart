import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/screen/home/home_screen.dart';
import 'package:myway/screen/home/my_page_screen.dart';
import 'package:myway/screen/home/park_list_screen.dart';
import 'package:myway/screen/result/activity_log_screen.dart';
import 'package:myway/screen/home/park_recommend_screen.dart';
import 'package:provider/provider.dart';
import 'package:myway/provider/park_data_provider.dart';

class BottomTabBar extends StatefulWidget {
  const BottomTabBar({super.key});

  @override
  State<BottomTabBar> createState() => _BottomTabBarState();
}

class _BottomTabBarState extends State<BottomTabBar> {
  int _selectedIndex = 2;
  final PageController _pageController = PageController(initialPage: 2);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final parkProvider = context.read<ParkDataProvider>();

      print('BottomTabBar 초기화 시작');
      print('현재 공원 데이터 개수: ${parkProvider.allParks.length}');
      print('CSV 로드 상태: ${parkProvider.csvLoaded}');
      print('현재 사용자 레코드 개수: ${parkProvider.allUserCourseRecords.length}');

      // CSV 데이터와 사용자 레코드를 병렬로 처리
      final futures = <Future>[];

      // CSV 데이터가 없으면 로드
      if (!parkProvider.csvLoaded && parkProvider.allParks.isEmpty) {
        print('BottomTabBar에서 CSV 데이터 로드 시작');
        futures.add(parkProvider.loadParksFromCsv());
      } else {
        print('CSV 데이터가 이미 로드되어 있음: ${parkProvider.allParks.length}개');
      }

      // 사용자 레코드가 없으면 로드
      if (parkProvider.allUserCourseRecords.isEmpty &&
          !parkProvider.isLoadingUserRecords) {
        print('BottomTabBar에서 사용자 레코드 로드 시작');
        futures.add(parkProvider.initializeUserRecords());
      } else {
        print(
          '사용자 레코드가 이미 로드되어 있음: ${parkProvider.allUserCourseRecords.length}개',
        );
      }

      // 병렬로 처리
      if (futures.isNotEmpty) {
        await Future.wait(futures);
        print('BottomTabBar 초기화 완료');
        print('최종 공원 데이터 개수: ${parkProvider.allParks.length}개');
        print('최종 사용자 레코드 개수: ${parkProvider.allUserCourseRecords.length}개');
      }
    } catch (e) {
      print('BottomTabBar 초기화 실패: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragStart: (details) {
          // 수평 스와이프 제스처 무시
        },
        onHorizontalDragUpdate: (details) {
          // 수평 스와이프 제스처 무시
        },
        onHorizontalDragEnd: (details) {
          // 수평 스와이프 제스처 무시
        },
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // 스와이프 비활성화
          allowImplicitScrolling: false, // 암시적 스크롤 비활성화
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: [
            ParkRecommendScreen(), // 추천코스 탭
            ParkListScreen(), // 공원찾기 탭
            HomeScreen(),
            ActivityLogScreen(),
            MyPageScreen(),
          ],
        ),
      ),
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
