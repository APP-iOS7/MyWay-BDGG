import 'package:flutter/material.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../provider/park_data_provider.dart';
import '../../const/colors.dart';
import 'park_detail.dart';

enum ParkFilterType { all, nearby, favorites }

class ParkListScreen extends StatefulWidget {
  final int initialTabIndex;
  const ParkListScreen({super.key, this.initialTabIndex = 0});
  @override
  State<ParkListScreen> createState() => _ParkListScreenState();
}

class _ParkListScreenState extends State<ParkListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<ParkInfo> _filteredParks = [];
  List<ParkInfo> _parksToDisplayOnPage = [];
  final double _nearbyFilterRadiusKm = 5.0; // 반경 5키로 변수 선언
  ParkFilterType _currentParkFilter = ParkFilterType.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = "";
  final ScrollController _parkListScrollController = ScrollController();
  final int _parksPerPage = 20;
  int _currentParkPage = 1;
  bool _isFetchingMoreParks = false;

  static const Color orangeIconColor = YELLOW_INFO_BASE_30;

  List<ParkCourseInfo> _filteredRecommendedCourses = [];
  List<ParkCourseInfo> _recommendedCoursesToDisplayOnPage = [];
  final ScrollController _recommendedCourseScrollController =
      ScrollController();
  final int _coursesPerPage = 20;
  int _currentRecommendedCoursePage = 1;
  bool _isFetchingMoreRecommendedCourses = false;
  ParkFilterType _currentCourseFilter = ParkFilterType.all;

  @override
  void initState() {
    super.initState();
    final parkDataProvider = Provider.of<ParkDataProvider>(
      context,
      listen: false,
    );
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_handleTabSelection);

    _searchController.addListener(_onParkSearchChanged);
    _parkListScrollController.addListener(_onParkScroll);
    _recommendedCourseScrollController.addListener(_onRecommendedCourseScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        parkDataProvider.fetchAllDataIfNeeded().then((_) {
          if (mounted) {
            _applyParkFilterAndSearchAndPagination(parkDataProvider);
            _applyRecommendedCourseFilterAndPagination(parkDataProvider);
          }
        });
      }
    });
  }

  void _handleTabSelection() {
    if (mounted) {
      final parkDataProvider = Provider.of<ParkDataProvider>(
        context,
        listen: false,
      );
      if (_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) {
            if (_parkListScrollController.hasClients) {
              _parkListScrollController.jumpTo(0);
            }
            _applyParkFilterAndSearchAndPagination(parkDataProvider);
          } else if (_tabController.index == 1) {
            if (_recommendedCourseScrollController.hasClients) {
              _recommendedCourseScrollController.jumpTo(0);
            }
            _applyRecommendedCourseFilterAndPagination(parkDataProvider);
            if (parkDataProvider.allGeneratedRecommendedCourses.isEmpty &&
                !parkDataProvider.isLoadingRecommendedCourses &&
                !parkDataProvider.isLoadingParks) {
              parkDataProvider.fetchAllDataIfNeeded().then((_) {
                if (mounted) {
                  _applyRecommendedCourseFilterAndPagination(parkDataProvider);
                }
              });
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.removeListener(_onParkSearchChanged);
    _searchController.dispose();
    _parkListScrollController.removeListener(_onParkScroll);
    _parkListScrollController.dispose();
    _recommendedCourseScrollController.removeListener(
      _onRecommendedCourseScroll,
    );
    _recommendedCourseScrollController.dispose();
    super.dispose();
  }

  void _onParkSearchChanged() {
    if (mounted) {
      final parkDataProvider = Provider.of<ParkDataProvider>(
        context,
        listen: false,
      );
      setState(() {
        _searchTerm = _searchController.text;
        _applyParkFilterAndSearchAndPagination(parkDataProvider);
      });
    }
  }

  void _onParkScroll() {
    if (_tabController.index == 0 &&
        _parkListScrollController.hasClients &&
        _parkListScrollController.position.pixels >=
            _parkListScrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMoreParks &&
        _parksToDisplayOnPage.length < _filteredParks.length) {
      _fetchMoreParksForPage();
    }
  }

  void _onRecommendedCourseScroll() {
    if (_tabController.index == 1 &&
        _recommendedCourseScrollController.hasClients &&
        _recommendedCourseScrollController.position.pixels >=
            _recommendedCourseScrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMoreRecommendedCourses &&
        _recommendedCoursesToDisplayOnPage.length <
            _filteredRecommendedCourses.length) {
      _fetchMoreRecommendedCoursesForPage();
    }
  }

  void _applyParkFilterAndSearchAndPagination(ParkDataProvider provider) {
    // 반경 5키로 지정 메소드
    if (!provider.isLoadingParks) {
      List<ParkInfo> tempFilteredList = List.from(provider.allFetchedParks);
      if (_currentParkFilter == ParkFilterType.favorites) {
        tempFilteredList =
            tempFilteredList
                .where((park) => provider.isParkFavorite(park.id))
                .toList();
      } else if (_currentParkFilter == ParkFilterType.nearby) {
        if (provider.currentPosition != null) {
          tempFilteredList =
              tempFilteredList
                  .where((park) => park.distanceKm < _nearbyFilterRadiusKm)
                  .toList(); //
          tempFilteredList.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        } else {
          tempFilteredList = [];
          if (mounted && !provider.isLoadingLocation) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                toastification.show(
                  context: context,
                  type: ToastificationType.error,
                  style: ToastificationStyle.flat,
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: Duration(seconds: 2),
                  title: Text("현재 위치를 가져올 수 없어 '내 주변' 필터를 사용할 수 없습니다."),
                );
              }
            });
          }
        }
      } else {
        tempFilteredList.sort((a, b) => a.name.compareTo(b.name));
      }
      if (_searchTerm.isNotEmpty) {
        tempFilteredList =
            tempFilteredList
                .where(
                  (park) =>
                      park.name.toLowerCase().contains(
                        _searchTerm.toLowerCase(),
                      ) ||
                      (park.address.isNotEmpty &&
                          park.address.toLowerCase().contains(
                            _searchTerm.toLowerCase(),
                          )),
                )
                .toList();
      }
      if (mounted) {
        setState(() {
          _filteredParks = tempFilteredList;
          _currentParkPage = 1;
          _loadParksForCurrentPage();
        });
      }
    }
  }

  void _loadParksForCurrentPage() {
    final int startIndex = (_currentParkPage - 1) * _parksPerPage;
    int endIndex = startIndex + _parksPerPage;
    if (endIndex > _filteredParks.length) {
      endIndex = _filteredParks.length;
    }
    if (mounted) {
      setState(() {
        if (_currentParkPage == 1) {
          _parksToDisplayOnPage = _filteredParks.sublist(startIndex, endIndex);
        } else {
          _parksToDisplayOnPage.addAll(
            _filteredParks.sublist(startIndex, endIndex),
          );
        }
        _isFetchingMoreParks = false;
      });
    }
  }

  void _fetchMoreParksForPage() {
    /* 이전과 동일 */
    if (_isFetchingMoreParks) {
      return;
    }
    if (mounted) {
      setState(() => _isFetchingMoreParks = true);
    }
    _currentParkPage++;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadParksForCurrentPage();
      }
    });
  }

  void _applyRecommendedCourseFilterAndPagination(ParkDataProvider provider) {
    /* 이전과 동일 */
    if (!provider.isLoadingRecommendedCourses) {
      List<ParkCourseInfo> tempFilteredList = List.from(
        provider.allGeneratedRecommendedCourses,
      );
      if (_currentCourseFilter == ParkFilterType.favorites) {
        tempFilteredList =
            tempFilteredList
                .where((course) => provider.isCourseFavorite(course.details.id))
                .toList();
      } else {
        /* 정렬 로직 */
      }
      if (mounted) {
        setState(() {
          _filteredRecommendedCourses = tempFilteredList;
          _currentRecommendedCoursePage = 1;
          _loadRecommendedCoursesForCurrentPage();
        });
      }
    }
  }

  void _loadRecommendedCoursesForCurrentPage() {
    /* 이전과 동일 */
    final int startIndex =
        (_currentRecommendedCoursePage - 1) * _coursesPerPage;
    int endIndex = startIndex + _coursesPerPage;
    if (endIndex > _filteredRecommendedCourses.length) {
      endIndex = _filteredRecommendedCourses.length;
    }
    if (mounted) {
      setState(() {
        if (_currentRecommendedCoursePage == 1) {
          _recommendedCoursesToDisplayOnPage = _filteredRecommendedCourses
              .sublist(startIndex, endIndex);
        } else {
          _recommendedCoursesToDisplayOnPage.addAll(
            _filteredRecommendedCourses.sublist(startIndex, endIndex),
          );
        }
        _isFetchingMoreRecommendedCourses = false;
      });
    }
  }

  void _fetchMoreRecommendedCoursesForPage() {
    /* 이전과 동일 */
    if (_isFetchingMoreRecommendedCourses) {
      return;
    }
    if (mounted) {
      setState(() => _isFetchingMoreRecommendedCourses = true);
    }
    _currentRecommendedCoursePage++;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadRecommendedCoursesForCurrentPage();
      }
    });
  }

  Widget _buildParkListItem(ParkInfo park) {
    /* 이전과 동일 */
    String displayAddress = park.address.isNotEmpty ? park.address : "주소 정보 없음";
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: GRAYSCALE_LABEL_50,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(32, 32, 32, 0.05),
            spreadRadius: 0.5,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ParkDetailScreen(park: park),
              ),
            ),
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 22, color: orangeIconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            park.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: GRAYSCALE_LABEL_950,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          park.type.isNotEmpty ? park.type : "정보 없음",
                          style: const TextStyle(
                            fontSize: 13,
                            color: GRAYSCALE_LABEL_600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayAddress,
                      style: const TextStyle(
                        fontSize: 13,
                        color: GRAYSCALE_LABEL_700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: GRAYSCALE_LABEL_400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParkSearchBarAndFilters(ParkDataProvider provider) {
    /* 이전과 동일 */
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _onParkSearchChanged(),

              cursorColor: ORANGE_PRIMARY_500,
              decoration: InputDecoration(
                hintText: "공원 이름 또는 주소 검색",
                hintStyle: const TextStyle(
                  color: GRAYSCALE_LABEL_400,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: GRAYSCALE_LABEL_500,
                  size: 20,
                ),
                filled: true,
                fillColor: GRAYSCALE_LABEL_100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(
                    color: GRAYSCALE_LABEL_300,
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(
                    color: GRAYSCALE_LABEL_300,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(
                    color: BLUE_SECONDARY_500,
                    width: 1.5,
                  ),
                ),
                suffixIcon:
                    _searchTerm.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: GRAYSCALE_LABEL_500,
                            size: 20,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                        : null,
              ),
              style: const TextStyle(fontSize: 14, color: GRAYSCALE_LABEL_950),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFilterChip(ParkFilterType.all, "전체", true, provider),
              const SizedBox(width: 8),
              _buildFilterChip(
                ParkFilterType.nearby,
                "내 주변 5km",
                true,
                provider,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                ParkFilterType.favorites,
                "찜 목록",
                true,
                provider,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseFilterChips(ParkDataProvider provider) {
    /* 이전과 동일 */
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Row(
        children: [
          _buildFilterChip(ParkFilterType.all, "전체", false, provider),
          const SizedBox(width: 8),
          _buildFilterChip(ParkFilterType.favorites, "찜 목록", false, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ParkFilterType filterType,
    String label,
    bool isParkTab,
    ParkDataProvider provider,
  ) {
    /* 이전과 동일 */
    bool isSelected;
    if (isParkTab) {
      isSelected = _currentParkFilter == filterType;
    } else {
      isSelected = _currentCourseFilter == filterType;
    }
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          if (isParkTab) {
            if (filterType == ParkFilterType.nearby &&
                provider.currentPosition == null &&
                !provider.isLoadingLocation) {
              if (mounted) {
                toastification.show(
                  context: context,
                  type: ToastificationType.error,
                  style: ToastificationStyle.flat,
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: Duration(seconds: 2),
                  title: Text(
                    "현재 위치를 가져올 수 없어 '내 주변' 필터를 사용할 수 없습니다. 위치 권한을 확인해주세요.",
                  ),
                );
              }
              return;
            }
            if (mounted) {
              setState(() {
                _currentParkFilter = filterType;
                _applyParkFilterAndSearchAndPagination(provider);
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _currentCourseFilter = filterType;
                _applyRecommendedCourseFilterAndPagination(provider);
              });
            }
          }
        }
      },
      backgroundColor: isSelected ? BLUE_SECONDARY_500 : GRAYSCALE_LABEL_100,
      selectedColor: BLUE_SECONDARY_500,
      labelStyle: TextStyle(
        color: isSelected ? BACKGROUND_COLOR : GRAYSCALE_LABEL_700,
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: isSelected ? BLUE_SECONDARY_500 : GRAYSCALE_LABEL_300,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      showCheckmark: false,
    );
  }

  Widget _buildParkTabContent(ParkDataProvider provider) {
    /* 이전과 동일 */
    const double horizontalPageMargin = 20.0;
    if (provider.isLoadingLocation &&
        provider.allFetchedParks.isEmpty &&
        provider.isLoadingParks) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: BLUE_SECONDARY_500),
            SizedBox(height: 15),
            Text(
              "위치 및 공원 정보를 가져오는 중...",
              style: TextStyle(color: GRAYSCALE_LABEL_700),
            ),
          ],
        ),
      );
    }
    if (provider.isLoadingParks && provider.allFetchedParks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: BLUE_SECONDARY_500),
            SizedBox(height: 15),
            Text(
              "공원 정보를 불러오는 중...",
              style: TextStyle(color: GRAYSCALE_LABEL_700),
            ),
          ],
        ),
      );
    }
    if (provider.apiError.isNotEmpty && provider.allFetchedParks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(horizontalPageMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: RED_DANGER_TEXT_50,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                "오류 발생",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GRAYSCALE_LABEL_900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.apiError,
                style: const TextStyle(
                  color: GRAYSCALE_LABEL_700,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: BACKGROUND_COLOR),
                label: const Text(
                  "다시 시도",
                  style: TextStyle(color: BACKGROUND_COLOR),
                ),
                onPressed:
                    () => provider.refreshData().then(
                      (_) => _applyParkFilterAndSearchAndPagination(provider),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BLUE_SECONDARY_500,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.allFetchedParks.isEmpty && !provider.isLoadingParks) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPageMargin,
            ),
            child: _buildParkSearchBarAndFilters(provider),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPageMargin,
                ),
                child: Text(
                  "제공된 공원 정보가 없습니다.",
                  style: const TextStyle(
                    color: GRAYSCALE_LABEL_600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_parksToDisplayOnPage.isEmpty &&
        !provider.isLoadingParks &&
        (_searchTerm.isNotEmpty || _currentParkFilter != ParkFilterType.all)) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPageMargin,
            ),
            child: _buildParkSearchBarAndFilters(provider),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPageMargin,
                ),
                child: Text(
                  _searchTerm.isNotEmpty
                      ? "'$_searchTerm' 검색 결과가 없습니다."
                      : "선택한 조건에 맞는 공원이 없습니다.",
                  style: const TextStyle(
                    color: GRAYSCALE_LABEL_600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPageMargin),
          child: _buildParkSearchBarAndFilters(provider),
        ),
        Expanded(
          child: ListView.builder(
            controller: _parkListScrollController,
            padding: const EdgeInsets.fromLTRB(
              horizontalPageMargin,
              0,
              horizontalPageMargin,
              horizontalPageMargin,
            ),
            itemCount:
                _parksToDisplayOnPage.length + (_isFetchingMoreParks ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _parksToDisplayOnPage.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: CircularProgressIndicator(color: BLUE_SECONDARY_500),
                  ),
                );
              }
              return _buildParkListItem(_parksToDisplayOnPage[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedCourseCardItem(
    ParkCourseInfo course,
    ParkDataProvider provider,
  ) {
    bool isFavoriteNow = provider.isCourseFavorite(course.details.id);
    // print("List Screen Build Card: ${course.title} (ID: ${course.id}), isFavorite: $isFavoriteNow");

    return Container(
      // 카드 전체를 감싸는 Container에 Key를 부여합니다.
      key: ValueKey(course.details.id),
      decoration: BoxDecoration(
        color: BACKGROUND_COLOR,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(32, 32, 32, 0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12.0),
                    ),
                    child: Image.asset(
                      course.details.imageUrl.isNotEmpty
                          ? course.details.imageUrl
                          : 'assets/images/default_course_image.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: GRAYSCALE_LABEL_400,
                              size: 40,
                            ),
                          ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey(course.details.id), // Key 고유성 확보
                      onTap: () {
                        provider.toggleCourseFavorite(course.details.id);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          isFavoriteNow
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              isFavoriteNow ? HEART_FILL : GRAYSCALE_LABEL_600,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.details.parkName ?? '정보 없음',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: GRAYSCALE_LABEL_950,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (course.details.parkName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    course.details.parkName!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: GRAYSCALE_LABEL_500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  course.details.distance.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    color: GRAYSCALE_LABEL_700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCoursesTabContent(ParkDataProvider provider) {
    /* 이전과 동일 */
    const double horizontalPageMargin = 20.0;
    if (provider.isLoadingRecommendedCourses || provider.isLoadingParks) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: BLUE_SECONDARY_700),
            SizedBox(height: 15),
            Text(
              "추천 코스를 불러오는 중...",
              style: TextStyle(color: GRAYSCALE_LABEL_700),
            ),
          ],
        ),
      );
    }
    if (provider.apiError.isNotEmpty &&
        provider.allGeneratedRecommendedCourses.isEmpty &&
        provider.allFetchedParks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(horizontalPageMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: RED_DANGER_TEXT_50,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                "오류 발생",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GRAYSCALE_LABEL_900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "코스 정보를 불러오는데 실패했습니다.\n${provider.apiError}",
                style: const TextStyle(
                  color: GRAYSCALE_LABEL_700,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: BACKGROUND_COLOR),
                label: const Text(
                  "다시 시도",
                  style: TextStyle(color: BACKGROUND_COLOR),
                ),
                onPressed:
                    () => provider.refreshData().then(
                      (_) =>
                          _applyRecommendedCourseFilterAndPagination(provider),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BLUE_SECONDARY_500,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_recommendedCoursesToDisplayOnPage.isEmpty &&
        !provider.isLoadingRecommendedCourses &&
        _currentCourseFilter != ParkFilterType.all) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPageMargin,
            ),
            child: _buildCourseFilterChips(provider),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPageMargin,
                ),
                child: Text(
                  "선택한 조건에 맞는 추천 코스가 없습니다.",
                  style: const TextStyle(
                    color: GRAYSCALE_LABEL_600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (provider.allGeneratedRecommendedCourses.isEmpty &&
        !provider.isLoadingRecommendedCourses) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPageMargin,
            ),
            child: _buildCourseFilterChips(provider),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPageMargin,
                ),
                child: Text(
                  "추천 코스가 아직 없습니다.",
                  style: const TextStyle(
                    color: GRAYSCALE_LABEL_600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPageMargin),
          child: _buildCourseFilterChips(provider),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPageMargin,
            ),
            child: GridView.builder(
              controller: _recommendedCourseScrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.70,
              ),
              itemCount:
                  _recommendedCoursesToDisplayOnPage.length +
                  (_isFetchingMoreRecommendedCourses ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _recommendedCoursesToDisplayOnPage.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: BLUE_SECONDARY_700,
                      ),
                    ),
                  );
                }
                final course = _recommendedCoursesToDisplayOnPage[index];
                // GridView.builder의 itemBuilder에서 반환하는 각 카드 아이템에 ValueKey를 부여합니다.
                return _buildRecommendedCourseCardItem(course, provider);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkDataProvider>(
      builder: (context, parkDataProvider, child) {
        return Scaffold(
          backgroundColor: BACKGROUND_COLOR,
          appBar: AppBar(
            backgroundColor: BACKGROUND_COLOR,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: GRAYSCALE_LABEL_950,
                size: 20,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            title: const Text(
              "공원 및 코스 추천",
              style: TextStyle(
                color: GRAYSCALE_LABEL_950,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              labelColor: BLUE_SECONDARY_700,
              unselectedLabelColor: GRAYSCALE_LABEL_500,
              indicatorColor: BLUE_SECONDARY_700,
              indicatorWeight: 3.0,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [Tab(text: "공원"), Tab(text: "추천 코스")],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildParkTabContent(parkDataProvider),
              _buildRecommendedCoursesTabContent(parkDataProvider),
            ],
          ),
        );
      },
    );
  }
}
