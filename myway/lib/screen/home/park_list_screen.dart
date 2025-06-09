import 'package:flutter/material.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/model/step_model.dart';
import 'package:provider/provider.dart';
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

  // 공원 탭 관련 상태 변수
  List<ParkInfo> _filteredParks = [];
  List<ParkInfo> _parksToDisplayOnPage = [];
  final double _nearbyFilterRadiusKm = 2.0;
  ParkFilterType _currentParkFilter = ParkFilterType.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = "";
  final ScrollController _parkListScrollController = ScrollController();
  final int _parksPerPage = 20;
  int _currentParkPage = 1;
  bool _isFetchingMoreParks = false;

  static const Color orangeIconColor = YELLOW_INFO_BASE_30;

  // 사용자 활동 기록 관련 상태 변수
  List<StepModel> _userRecordsToDisplayOnPage = [];
  final ScrollController _userRecordsScrollController = ScrollController();
  final int _userRecordsPerPage = 20;
  int _currentUserRecordsPage = 1;
  bool _isFetchingMoreUserRecords = false;

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
    _userRecordsScrollController.addListener(_onUserRecordsScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        parkDataProvider.fetchAllDataIfNeeded().then((_) {
          if (mounted) {
            _applyParkFilterAndSearchAndPagination(parkDataProvider);
            _applyUserRecordsPagination(parkDataProvider);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.removeListener(_onParkSearchChanged);
    _searchController.dispose();
    _parkListScrollController.removeListener(_onParkScroll);
    _parkListScrollController.dispose();
    _userRecordsScrollController.removeListener(_onUserRecordsScroll);
    _userRecordsScrollController.dispose();
    super.dispose();
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
            if (_userRecordsScrollController.hasClients) {
              _userRecordsScrollController.jumpTo(0);
            }
            _applyUserRecordsPagination(parkDataProvider);
          }
        });
      }
    }
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

  void _onUserRecordsScroll() {
    if (_tabController.index == 1 &&
        _userRecordsScrollController.hasClients &&
        _userRecordsScrollController.position.pixels >=
            _userRecordsScrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMoreUserRecords) {
      final provider = Provider.of<ParkDataProvider>(context, listen: false);
      if (_userRecordsToDisplayOnPage.length <
          provider.allUserCourseRecords.length) {
        _fetchMoreUserRecordsForPage();
      }
    }
  }

  void _applyParkFilterAndSearchAndPagination(ParkDataProvider provider) {
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
                  .toList();
          tempFilteredList.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        } else {
          tempFilteredList = [];
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
    if (_isFetchingMoreParks) return;
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

  void _applyUserRecordsPagination(ParkDataProvider provider) {
    if (mounted) {
      setState(() {
        _currentUserRecordsPage = 1;
        _loadUserRecordsForCurrentPage(provider);
      });
    }
  }

  void _loadUserRecordsForCurrentPage(ParkDataProvider provider) {
    final allRecords = provider.allUserCourseRecords;
    final int startIndex = (_currentUserRecordsPage - 1) * _userRecordsPerPage;
    int endIndex = startIndex + _userRecordsPerPage;
    if (endIndex > allRecords.length) {
      endIndex = allRecords.length;
    }

    if (mounted) {
      setState(() {
        if (_currentUserRecordsPage == 1) {
          _userRecordsToDisplayOnPage = allRecords.sublist(
            startIndex,
            endIndex,
          );
        } else {
          _userRecordsToDisplayOnPage.addAll(
            allRecords.sublist(startIndex, endIndex),
          );
        }
        _isFetchingMoreUserRecords = false;
      });
    }
  }

  void _fetchMoreUserRecordsForPage() {
    if (_isFetchingMoreUserRecords) return;
    if (mounted) {
      setState(() => _isFetchingMoreUserRecords = true);
    }
    _currentUserRecordsPage++;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final provider = Provider.of<ParkDataProvider>(context, listen: false);
        _loadUserRecordsForCurrentPage(provider);
      }
    });
  }

  Widget _buildParkListItem(ParkInfo park) {
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
                "내 주변 2km",
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

  Widget _buildFilterChip(
    ParkFilterType filterType,
    String label,
    bool isParkTab,
    ParkDataProvider provider,
  ) {
    bool isSelected = isParkTab ? _currentParkFilter == filterType : false;
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "현재 위치를 가져올 수 없어 '내 주변' 필터를 사용할 수 없습니다. 위치 권한을 확인해주세요.",
                    ),
                    backgroundColor: YELLOW_INFO_BASE_30,
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

  Widget buildParkTabContent(ParkDataProvider provider) {
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
                onPressed: () async {
                  await provider.refreshData();
                  if (mounted) {
                    _applyParkFilterAndSearchAndPagination(provider);
                  }
                },
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
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPageMargin),
                child: Text(
                  "제공된 공원 정보가 없습니다.",
                  style: TextStyle(color: GRAYSCALE_LABEL_600, fontSize: 14),
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

  Widget _buildUserRecordCardItem(StepModel record) {
    String formatDuration(String durationStr) {
      final parts = durationStr.split(':');
      if (parts.length == 3) {
        int hours = int.tryParse(parts[0]) ?? 0;
        int minutes = int.tryParse(parts[1]) ?? 0;
        int seconds = int.tryParse(parts[2]) ?? 0;
        String result = "";
        if (hours > 0) result += "${hours}시간 ";
        if (minutes > 0 || hours > 0) result += "${minutes}분 ";
        result += "${seconds}초";
        return result.trim().isEmpty ? "0초" : result.trim();
      }
      return durationStr;
    }

    String formatStopTime(String stopTimeStr) {
      try {
        DateTime dt = DateTime.parse(stopTimeStr);
        return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        return stopTimeStr;
      }
    }

    return Container(
      key: ValueKey('user_record_item_${record.id}'),
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
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12.0),
              ),
              child:
                  record.imageUrl.isNotEmpty
                      ? Image.network(
                        record.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: BLUE_SECONDARY_500,
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: GRAYSCALE_LABEL_400,
                                size: 40,
                              ),
                            ),
                      )
                      : Image.asset(
                        'assets/images/default_course_image.png',
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
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.courseName.isNotEmpty ? record.courseName : "코스 이름 없음",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: GRAYSCALE_LABEL_950,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (record.parkName != null && record.parkName!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    record.parkName!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: GRAYSCALE_LABEL_500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  "거리: ${record.distance.toStringAsFixed(1)}km",
                  style: const TextStyle(
                    fontSize: 12,
                    color: GRAYSCALE_LABEL_700,
                  ),
                ),
                Text(
                  "시간: ${formatDuration(record.duration)}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: GRAYSCALE_LABEL_700,
                  ),
                ),
                Text(
                  "걸음: ${record.steps}보",
                  style: const TextStyle(
                    fontSize: 12,
                    color: GRAYSCALE_LABEL_700,
                  ),
                ),
                Text(
                  formatStopTime(record.stopTime),
                  style: const TextStyle(
                    fontSize: 10,
                    color: GRAYSCALE_LABEL_600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUserRecordsTabContent(ParkDataProvider provider) {
    const double horizontalPageMargin = 20.0;

    if (provider.isLoadingUserRecords &&
        provider.allUserCourseRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: BLUE_SECONDARY_700),
            SizedBox(height: 15),
            Text(
              "사용자 기록을 불러오는 중...",
              style: TextStyle(color: GRAYSCALE_LABEL_700),
            ),
          ],
        ),
      );
    }

    if (provider.userRecordsError.isNotEmpty &&
        provider.allUserCourseRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(horizontalPageMargin),
          child: Text(provider.userRecordsError, textAlign: TextAlign.center),
        ),
      );
    }

    if (provider.allUserCourseRecords.isEmpty &&
        !provider.isLoadingUserRecords) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPageMargin),
          child: Text(
            "사용자 활동 기록이 아직 없습니다.",
            style: TextStyle(color: GRAYSCALE_LABEL_600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: horizontalPageMargin,
        vertical: 12.0,
      ),
      child: GridView.builder(
        controller: _userRecordsScrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 0.68,
        ),
        itemCount:
            _userRecordsToDisplayOnPage.length +
            (_isFetchingMoreUserRecords ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _userRecordsToDisplayOnPage.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: CircularProgressIndicator(color: BLUE_SECONDARY_700),
              ),
            );
          }
          final record = _userRecordsToDisplayOnPage[index];
          return _buildUserRecordCardItem(record);
        },
      ),
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
              "공원 및 활동 기록",
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
              overlayColor: MaterialStateProperty.all(Colors.transparent),
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
              buildParkTabContent(parkDataProvider),
              buildUserRecordsTabContent(parkDataProvider),
            ],
          ),
        );
      },
    );
  }
}
