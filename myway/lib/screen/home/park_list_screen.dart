import 'package:flutter/material.dart';
import 'package:myway/model/park_info.dart';
import 'package:provider/provider.dart';
import '../../provider/park_data_provider.dart';
import '../../const/colors.dart';
import 'park_detail.dart';

enum ParkFilterType { all, nearby, favorites }

class ParkListScreen extends StatefulWidget {
  const ParkListScreen({super.key});

  @override
  State<ParkListScreen> createState() => _ParkListScreenState();
}

class _ParkListScreenState extends State<ParkListScreen> {
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
  bool _isInitialLoading = true;
  bool _isSearching = false;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onParkSearchChanged);
    _parkListScrollController.addListener(_onParkScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      final provider = Provider.of<ParkDataProvider>(context, listen: false);
      print('park_list_screen 초기화 시작');
      print('현재 공원 데이터 개수: ${provider.allParks.length}');

      // CSV 데이터가 없으면 로드
      if (provider.allParks.isEmpty && !provider.csvLoaded) {
        print('공원리스트에서 CSV 데이터 로드 시작');
        await provider.loadParksFromCsv();
        print('공원리스트에서 CSV 데이터 로드 완료: ${provider.allParks.length}개');
      }

      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
        _applyParkFilterAndSearchAndPagination(provider);
      }
    } catch (e) {
      print('공원리스트 초기화 실패: $e');
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onParkSearchChanged);
    _searchController.dispose();
    _parkListScrollController.removeListener(_onParkScroll);
    _parkListScrollController.dispose();
    super.dispose();
  }

  void _onParkSearchChanged() {
    if (mounted) {
      final provider = Provider.of<ParkDataProvider>(context, listen: false);
      setState(() {
        _searchTerm = _searchController.text;
        _isSearching = true;
      });

      // 검색 디바운싱
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
          _applyParkFilterAndSearchAndPagination(provider);
        }
      });
    }
  }

  void _onParkScroll() {
    if (_parkListScrollController.hasClients &&
        _parkListScrollController.position.pixels >=
            _parkListScrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMoreParks &&
        _parksToDisplayOnPage.length < _filteredParks.length) {
      _fetchMoreParksForPage();
    }
  }

  void _applyParkFilterAndSearchAndPagination(ParkDataProvider provider) {
    if (!provider.isLoading) {
      List<ParkInfo> tempFilteredList = List.from(provider.allParks);

      if (_currentParkFilter == ParkFilterType.favorites) {
        tempFilteredList =
            tempFilteredList
                .where((park) => provider.isFavorite(park.id))
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
        tempFilteredList.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
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
    if (mounted) {
      setState(() {
        _parksToDisplayOnPage = List.from(_filteredParks);
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

  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: ORANGE_PRIMARY_500),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: GRAYSCALE_LABEL_600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.park_outlined, size: 64, color: GRAYSCALE_LABEL_400),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: GRAYSCALE_LABEL_600),
            textAlign: TextAlign.center,
          ),
        ],
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
              cursorColor: ORANGE_PRIMARY_500,
              decoration: InputDecoration(
                hintText: "공원 이름 또는 주소 검색",
                prefixIcon: const Icon(
                  Icons.search,
                  color: GRAYSCALE_LABEL_500,
                  size: 20,
                ),
                filled: true,
                fillColor: GRAYSCALE_LABEL_100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(color: GRAYSCALE_LABEL_300),
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
              _buildFilterChip(ParkFilterType.all, "전체", provider),
              const SizedBox(width: 8),
              _buildFilterChip(ParkFilterType.nearby, "내 주변 2km", provider),
              const SizedBox(width: 8),
              _buildFilterChip(ParkFilterType.favorites, "찜 목록", provider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ParkFilterType filterType,
    String label,
    ParkDataProvider provider,
  ) {
    bool isSelected = _currentParkFilter == filterType;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) async {
        if (!selected) return;

        if (filterType == ParkFilterType.nearby &&
            provider.currentPosition == null &&
            !provider.isLoadingLocation) {
          setState(() {
            _isLocationLoading = true;
          });
          await provider.fetchCurrentLocationAndCalculateDistance();
          setState(() {
            _isLocationLoading = false;
          });
        }

        if (filterType == ParkFilterType.favorites &&
            provider.favoriteParkIds.isEmpty) {
          await provider.loadFavoritesFromFirestore();
        }

        if (mounted) {
          setState(() {
            _currentParkFilter = filterType;
            _applyParkFilterAndSearchAndPagination(provider);
          });
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
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      showCheckmark: false,
    );
  }

  Widget _buildParkListItem(ParkInfo park) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: GRAYSCALE_LABEL_50,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
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
              const Icon(
                Icons.location_on,
                size: 22,
                color: YELLOW_INFO_BASE_30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      park.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      park.address.isNotEmpty ? park.address : "주소 정보 없음",
                      style: const TextStyle(
                        fontSize: 13,
                        color: GRAYSCALE_LABEL_700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                "${park.distanceKm.toStringAsFixed(1)} km",
                style: const TextStyle(
                  fontSize: 13,
                  color: BLUE_SECONDARY_500,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  Widget _buildBody(ParkDataProvider provider) {
    // 초기 로딩
    if (_isInitialLoading) {
      return _buildLoadingWidget('공원 정보를 불러오는 중...');
    }

    // 위치 정보 로딩
    if (_isLocationLoading) {
      return _buildLoadingWidget('위치 정보를 가져오는 중...');
    }

    // 검색 중
    if (_isSearching) {
      return _buildLoadingWidget('검색 중...');
    }

    // 데이터 로딩 중
    if (provider.isLoading) {
      return _buildLoadingWidget('데이터를 불러오는 중...');
    }

    // 공원 데이터가 없음
    if (provider.allParks.isEmpty) {
      return _buildEmptyWidget('공원 정보를 불러올 수 없습니다.\n잠시 후 다시 시도해주세요.');
    }

    // 필터링된 결과가 없음
    if (_filteredParks.isEmpty) {
      String emptyMessage = '검색 결과가 없습니다.';

      if (_currentParkFilter == ParkFilterType.nearby) {
        emptyMessage = '주변 2km 이내에 공원이 없습니다.';
      } else if (_currentParkFilter == ParkFilterType.favorites) {
        emptyMessage = '찜한 공원이 없습니다.';
      } else if (_searchTerm.isNotEmpty) {
        emptyMessage = '"$_searchTerm"에 대한 검색 결과가 없습니다.';
      }

      return _buildEmptyWidget(emptyMessage);
    }

    // 정상적인 공원 리스트
    return ListView.builder(
      controller: _parkListScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: _parksToDisplayOnPage.length + (_isFetchingMoreParks ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _parksToDisplayOnPage.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(color: BLUE_SECONDARY_500),
            ),
          );
        }
        return _buildParkListItem(_parksToDisplayOnPage[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkDataProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: BACKGROUND_COLOR,
          appBar: AppBar(
            backgroundColor: BACKGROUND_COLOR,
            elevation: 0,
            title: const Text(
              "공원 리스트",
              style: TextStyle(
                color: GRAYSCALE_LABEL_950,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildParkSearchBarAndFilters(provider),
              ),
              Expanded(child: _buildBody(provider)),
            ],
          ),
        );
      },
    );
  }
}
