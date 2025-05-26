import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/model/recommended_course_info.dart';
import 'package:myway/services/park_api_service.dart';

import '../const/colors.dart';

enum ParkFilterType { all, nearby }

class RecommendedCourseScreen extends StatefulWidget {
  const RecommendedCourseScreen({super.key});

  @override
  State<RecommendedCourseScreen> createState() =>
      _RecommendedCourseScreenState();
}

class _RecommendedCourseScreenState extends State<RecommendedCourseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditMode = false;

  List<ParkInfo> _allFetchedParks = [];
  List<ParkInfo> _parksToDisplayInParkTab = [];
  bool _isLoadingLocation = true;
  bool _isLoadingParks = true;
  String _apiError = '';
  Position? _currentPosition;

  final ParkApiService _parkApiService = ParkApiService();
  ParkInfo? _representativeParkForCourseTab;
  List<RecommendedCourseInfo> _allLocalCourses = [];
  List<RecommendedCourseInfo> _displayedCoursesOnCourseTab = [];

  final double _nearbyFilterRadiusKm = 5.0;
  ParkFilterType _currentParkFilter = ParkFilterType.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = "";
  bool _representativeParkIsFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchTerm = _searchController.text;
          _applyParkFilterAndSearch();
        });
      }
    });
    _initializeDataWithLocation();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<RecommendedCourseInfo> _getCoursesForPark(String parkId) {
    return _allLocalCourses.where((course) => course.parkId == parkId).toList();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging ||
        (!_tabController.indexIsChanging &&
            _tabController.previousIndex != _tabController.index)) {
      if (mounted) {
        setState(() {
          _isEditMode = false;
          _clearSelections();
          if (_tabController.index == 0) {
            _currentParkFilter = ParkFilterType.all;
            _searchController.clear();
            _searchTerm = "";
            _applyParkFilterAndSearch();
          } else if (_tabController.index == 1 &&
              _parksToDisplayInParkTab.isNotEmpty &&
              (_representativeParkForCourseTab == null ||
                  _representativeParkForCourseTab!.id == 'no_nearby_park' ||
                  _representativeParkForCourseTab!.id == 'initial_loading' ||
                  _representativeParkForCourseTab!.id.startsWith('error_'))) {
            _representativeParkForCourseTab = _parksToDisplayInParkTab[0];
            _generateExampleCoursesBasedOnParks();
          } else if (_tabController.index == 1 &&
              _parksToDisplayInParkTab.isEmpty &&
              _allFetchedParks.isNotEmpty &&
              _representativeParkForCourseTab == null) {
            _representativeParkForCourseTab = _allFetchedParks[0];
            _generateExampleCoursesBasedOnParks();
          }
        });
      }
    }
  }

  Future<void> _initializeDataWithLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _apiError = '';
    });

    try {
      _currentPosition = await _determinePosition();
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiError =
              e.toString().contains("Exception: ")
                  ? e.toString().split("Exception: ")[1]
                  : e.toString();
          _isLoadingLocation = false;
        });
      }
    }
    await _fetchAndProcessParksData();
    // _generateExampleCoursesBasedOnParks(); // _fetchAndProcessParksData 또는 _applyParkFilterAndSearch 에서 호출
    // _applyParkFilterAndSearch(); // _fetchAndProcessParksData 에서 호출
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('위치 권한이 거부되었습니다. 앱을 사용하려면 권한이 필요합니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 직접 권한을 허용해주세요.');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _fetchAndProcessParksData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingParks = true;
    });

    try {
      _allFetchedParks = await _parkApiService.fetchParks(numOfRows: 200);

      if (_allFetchedParks.isNotEmpty && _currentPosition != null) {
        for (var park in _allFetchedParks) {
          if (park.latitude != null &&
              park.longitude != null &&
              park.latitude!.isNotEmpty &&
              park.longitude!.isNotEmpty) {
            try {
              double parkLat = double.parse(park.latitude!);
              double parkLon = double.parse(park.longitude!);
              park.distanceKm =
                  Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    parkLat,
                    parkLon,
                  ) /
                  1000;
            } catch (e) {
              park.distanceKm = 99999.0;
            }
          } else {
            park.distanceKm = 99999.0;
          }
        }
        _allFetchedParks.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      }

      if (mounted) {
        setState(() {
          if (_allFetchedParks.isNotEmpty) {
            if (_representativeParkForCourseTab == null ||
                _representativeParkForCourseTab!.id == 'initial_loading' ||
                _representativeParkForCourseTab!.id.startsWith('error_') ||
                _representativeParkForCourseTab!.id == 'no_park_data') {
              _representativeParkForCourseTab = _allFetchedParks[0];
            }
          } else {
            _representativeParkForCourseTab = ParkInfo(
              id: 'no_park_data',
              name: "공원 정보 없음",
              type: "",
              address: "표시할 공원 데이터가 없습니다.",
            );
          }
          _isLoadingParks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          String errorMessage =
              e.toString().contains("Exception: ")
                  ? e.toString().split("Exception: ")[1]
                  : e.toString();
          if (_apiError.isEmpty) _apiError = "공원 정보 로딩 실패: $errorMessage";
          _representativeParkForCourseTab = ParkInfo(
            id: 'error_api_rep_park',
            name: "데이터 로딩 오류",
            type: "",
            address: _apiError,
          );
          _isLoadingParks = false;
          _allFetchedParks = [];
        });
      }
    }
    _applyParkFilterAndSearch();
    _generateExampleCoursesBasedOnParks();
  }

  void _applyParkFilterAndSearch() {
    List<ParkInfo> filteredList = [];
    if (_currentParkFilter == ParkFilterType.all) {
      filteredList = List.from(_allFetchedParks);
    } else if (_currentParkFilter == ParkFilterType.nearby) {
      if (_currentPosition != null) {
        filteredList =
            _allFetchedParks
                .where((park) => park.distanceKm < _nearbyFilterRadiusKm)
                .toList();
      } else {
        filteredList = [];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "현재 위치를 가져올 수 없어 '내 주변' 필터를 사용할 수 없습니다. 위치 권한을 확인해주세요.",
              ),
              backgroundColor: YELLOW_INFO_BASE_30,
            ),
          );
        }
      }
    }

    if (_searchTerm.isNotEmpty) {
      filteredList =
          filteredList
              .where(
                (park) =>
                    park.name.toLowerCase().contains(
                      _searchTerm.toLowerCase(),
                    ) ||
                    park.address.toLowerCase().contains(
                      _searchTerm.toLowerCase(),
                    ),
              )
              .toList();
    }

    if (mounted) {
      setState(() {
        _parksToDisplayInParkTab = filteredList;
        if (_parksToDisplayInParkTab.isNotEmpty &&
            (_representativeParkForCourseTab == null ||
                _representativeParkForCourseTab!.id == 'no_park_data' ||
                _representativeParkForCourseTab!.id.startsWith('error_') ||
                _representativeParkForCourseTab!.id == 'initial_loading' ||
                _representativeParkForCourseTab!.id == 'no_park_data_filter')) {
          _representativeParkForCourseTab = _parksToDisplayInParkTab[0];
        } else if (_parksToDisplayInParkTab.isEmpty &&
            (_representativeParkForCourseTab?.id != 'no_park_data_filter' &&
                _representativeParkForCourseTab?.id != 'no_park_data')) {
          _representativeParkForCourseTab = ParkInfo(
            id: 'no_park_data_filter',
            name: "공원 정보 없음",
            type: "",
            address: "선택된 조건에 맞는 공원이 없습니다.",
          );
        }
        _generateExampleCoursesBasedOnParks();
      });
    }
  }

  // *** 여기가 수정된 부분 ***
  void _generateExampleCoursesBasedOnParks() {
    _allLocalCourses = [];
    // 모든 _allFetchedParks에 대해 예시 코스를 미리 생성해둡니다.
    // 이렇게 하면 _getCoursesForPark(park.id)가 항상 해당 공원의 모든 예시 코스를 반환할 수 있습니다.
    for (var park in _allFetchedParks) {
      _allLocalCourses.add(
        RecommendedCourseInfo(
          id: 'course_${park.id}_1',
          parkId: park.id,
          title: "코스 1",
          details: "${park.name} 둘레길", // 공원 이름을 사용한 일반적인 설명
          imagePath: 'assets/map_placeholder.png',
        ),
      );
      _allLocalCourses.add(
        RecommendedCourseInfo(
          id: 'course_${park.id}_2',
          parkId: park.id,
          title: "코스 2",
          details: "${park.name} 호수 산책", // 공원 이름을 사용한 일반적인 설명
          imagePath: 'assets/map_placeholder.png',
        ),
      );
      // 필요하다면 공원별로 더 많은 예시 코스 (코스 3, 코스 4 등)를 생성할 수 있습니다.
    }
    _updateDisplayedCoursesOnCourseTab(); // 추천 코스 탭에 표시될 코스 목록 갱신
  }
  // *** 여기까지 수정된 부분 ***

  void _updateDisplayedCoursesOnCourseTab() {
    if (_representativeParkForCourseTab != null &&
        _representativeParkForCourseTab!.id != 'no_park_data' &&
        _representativeParkForCourseTab!.id != 'initial_loading' &&
        !_representativeParkForCourseTab!.id.startsWith('error_') &&
        _representativeParkForCourseTab!.id != 'no_park_data_filter') {
      _displayedCoursesOnCourseTab =
          _allLocalCourses
              .where(
                (course) =>
                    course.parkId == _representativeParkForCourseTab!.id,
              )
              .take(4)
              .toList();
    } else {
      _displayedCoursesOnCourseTab = [];
    }
    if (mounted) setState(() {});
  }

  void _toggleEditMode() {
    if (mounted) {
      setState(() {
        _isEditMode = !_isEditMode;
        if (!_isEditMode) {
          _clearSelections();
        }
      });
    }
  }

  void _clearSelections() {
    for (var park in _allFetchedParks) {
      park.isSelected = false;
      park.isExpanded = false;
    }
    for (var course in _allLocalCourses) {
      course.isSelected = false;
    }
  }

  void _deleteSelectedCourses() {
    List<String> idsToDelete = [];
    bool itemSelected = false;
    if (!mounted) return;

    if (_tabController.index == 1) {
      _displayedCoursesOnCourseTab.where((course) => course.isSelected).forEach(
        (course) {
          idsToDelete.add(course.id);
          itemSelected = true;
        },
      );
    } else {
      return;
    }

    if (!itemSelected && _isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("삭제할 코스를 선택해주세요."),
          backgroundColor: YELLOW_INFO_BASE_30,
        ),
      );
      return;
    }

    if (idsToDelete.isNotEmpty) {
      setState(() {
        _allLocalCourses.removeWhere(
          (course) => idsToDelete.contains(course.id),
        );
        _updateDisplayedCoursesOnCourseTab();
        _isEditMode = false;
        _clearSelections();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("선택한 코스가 삭제되었습니다."),
          backgroundColor: GREEN_SUCCESS_TEXT_50,
        ),
      );
    }
  }

  void _addCourse() {
    String? targetParkId;
    String targetParkName = "새 공원";

    final ParkInfo? repPark = _representativeParkForCourseTab;
    if (repPark != null &&
        repPark.id != 'initial_loading' &&
        !repPark.id.startsWith('error_') &&
        repPark.id != 'no_park_data' &&
        repPark.id != 'no_park_data_filter') {
      targetParkId = repPark.id;
      targetParkName = repPark.name;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("코스를 추가할 대표 공원 정보가 유효하지 않습니다."),
            backgroundColor: YELLOW_INFO_BASE_30,
          ),
        );
      }
      return;
    }

    String newCourseId = 'new_course_${DateTime.now().millisecondsSinceEpoch}';
    // 새로 추가되는 코스도 일반적인 이름으로
    int newCourseNumber = _getCoursesForPark(targetParkId).length + 1;
    RecommendedCourseInfo newCourse = RecommendedCourseInfo(
      id: newCourseId,
      parkId: targetParkId,
      title: "코스 $newCourseNumber",
      details: "$targetParkName 새로운 코스",
      imagePath: 'assets/map_placeholder.png',
    );

    if (mounted) {
      setState(() {
        _allLocalCourses.add(newCourse);
        if (newCourse.parkId == repPark.id) {
          _updateDisplayedCoursesOnCourseTab();
        }
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${newCourse.title} 코스가 추가되었습니다 (실제 저장 기능 필요)."),
          backgroundColor: GREEN_SUCCESS_TEXT_50,
        ),
      );
    }
  }

  void _switchToCourseTabWithPark(ParkInfo park) {
    if (mounted) {
      setState(() {
        _representativeParkForCourseTab = park;
        _representativeParkIsFavorite = false;
        _generateExampleCoursesBasedOnParks(); // 대표 공원 변경 시 코스 재생성 및 UI 갱신
        _isEditMode = false;
        _clearSelections();
      });
      _tabController.animateTo(1);
    }
  }

  Widget _buildParkListItem(ParkInfo park) {
    int courseCount = _getCoursesForPark(park.id).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: GRAYSCALE_LABEL_50,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: GRAYSCALE_LABEL_200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(32, 32, 32, 0.05),
            spreadRadius: 0.5,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _switchToCourseTabWithPark(park),
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: GRAYSCALE_LABEL_950,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          park.type,
                          style: TextStyle(
                            fontSize: 13,
                            color: GRAYSCALE_LABEL_600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: YELLOW_INFO_BASE_30,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "추천 코스 $courseCount개",
                          style: TextStyle(
                            fontSize: 13,
                            color: BLUE_SECONDARY_700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
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

  Widget _buildCourseCardItem(
    RecommendedCourseInfo course, {
    bool isEmbedded = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (_isEditMode) {
          if (mounted) {
            setState(() {
              course.isSelected = !course.isSelected;
            });
          }
        } else {
          print("View course: ${course.title}");
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: BACKGROUND_COLOR,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(32, 32, 32, 0.08),
              spreadRadius: 1,
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
          border:
              _isEditMode && course.isSelected
                  ? Border.all(color: BLUE_SECONDARY_500, width: 2.0)
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12.0),
                      ),
                      child: Image.asset(
                        course.imagePath,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: GRAYSCALE_LABEL_400,
                                size: 40,
                              ),
                            ),
                      ),
                    ),
                  ),
                  if (_isEditMode && course.isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.check_circle,
                        color: BLUE_SECONDARY_500,
                        size: 24,
                      ),
                    ),
                  if (!_isEditMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (mounted)
                              setState(
                                () => course.isFavorite = !course.isFavorite,
                              );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              course.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  course.isFavorite
                                      ? HEART_FILL
                                      : GRAYSCALE_LABEL_600,
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
                    course.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: GRAYSCALE_LABEL_950,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    course.details,
                    style: TextStyle(fontSize: 12, color: GRAYSCALE_LABEL_700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBarAndFilters() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "공원 이름 검색",
                hintStyle: TextStyle(color: GRAYSCALE_LABEL_400, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: GRAYSCALE_LABEL_500,
                  size: 20,
                ),
                filled: true,
                fillColor: GRAYSCALE_LABEL_100,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: GRAYSCALE_LABEL_200,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: BLUE_SECONDARY_500, width: 1.5),
                ),
                suffixIcon:
                    _searchTerm.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: GRAYSCALE_LABEL_500,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
              ),
              style: TextStyle(fontSize: 14, color: GRAYSCALE_LABEL_950),
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              _buildFilterChip(ParkFilterType.all, "전체 공원"),
              SizedBox(width: 8),
              _buildFilterChip(ParkFilterType.nearby, "내 주변 (5km)"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ParkFilterType filterType, String label) {
    bool isSelected = _currentParkFilter == filterType;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          if (filterType == ParkFilterType.nearby && _currentPosition == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
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
              _applyParkFilterAndSearch();
            });
          }
        }
      },
      backgroundColor: GRAYSCALE_LABEL_100,
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      showCheckmark: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPageMargin = 20.0;
    ParkInfo currentRepresentativeParkForUI =
        _representativeParkForCourseTab ??
        ParkInfo(
          id: 'initial_loading',
          name: "정보 로딩 중...",
          type: "",
          address: "잠시만 기다려주세요.",
        );

    bool isCourseTabActive = _tabController.index == 1;
    bool canShowEditButtons = isCourseTabActive;
    bool canShowDeleteButton =
        _isEditMode &&
        canShowEditButtons &&
        _displayedCoursesOnCourseTab.any((c) => c.isSelected);
    bool canShowAddButton =
        !_isEditMode &&
        canShowEditButtons &&
        currentRepresentativeParkForUI.id != 'initial_loading' &&
        !currentRepresentativeParkForUI.id.startsWith('error_') &&
        currentRepresentativeParkForUI.id != 'no_park_data' &&
        currentRepresentativeParkForUI.id != 'no_park_data_filter';

    Widget bodyContent;
    if (_isLoadingLocation) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: BLUE_SECONDARY_500),
            SizedBox(height: 15),
            Text(
              "현재 위치를 가져오는 중...",
              style: TextStyle(color: GRAYSCALE_LABEL_700),
            ),
          ],
        ),
      );
    } else if (_apiError.isNotEmpty &&
        _parksToDisplayInParkTab.isEmpty &&
        !_isLoadingParks) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(horizontalPageMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: RED_DANGER_TEXT_50, size: 48),
              SizedBox(height: 16),
              Text(
                "오류 발생",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GRAYSCALE_LABEL_900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _apiError,
                style: TextStyle(color: GRAYSCALE_LABEL_700, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh, color: BACKGROUND_COLOR),
                label: Text("다시 시도", style: TextStyle(color: BACKGROUND_COLOR)),
                onPressed: _initializeDataWithLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BLUE_SECONDARY_500,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      bodyContent = TabBarView(
        controller: _tabController,
        physics:
            _isEditMode && isCourseTabActive
                ? NeverScrollableScrollPhysics()
                : null,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPageMargin,
                ),
                child: _buildSearchBarAndFilters(),
              ),
              Expanded(
                child:
                    _isLoadingParks
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: BLUE_SECONDARY_500,
                              ),
                              SizedBox(height: 15),
                              Text(
                                "공원 정보를 불러오는 중...",
                                style: TextStyle(color: GRAYSCALE_LABEL_700),
                              ),
                            ],
                          ),
                        )
                        : _parksToDisplayInParkTab.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: horizontalPageMargin,
                            ),
                            child: Text(
                              _searchTerm.isNotEmpty
                                  ? "검색 결과가 없습니다."
                                  : (_apiError.isNotEmpty &&
                                          !_allFetchedParks.isNotEmpty
                                      ? _apiError
                                      : "표시할 공원 정보가 없습니다."),
                              style: TextStyle(
                                color:
                                    _apiError.isNotEmpty &&
                                            !_allFetchedParks.isNotEmpty
                                        ? RED_DANGER_TEXT_50
                                        : GRAYSCALE_LABEL_600,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            horizontalPageMargin,
                            0,
                            horizontalPageMargin,
                            horizontalPageMargin,
                          ),
                          itemCount: _parksToDisplayInParkTab.length,
                          itemBuilder: (context, index) {
                            return _buildParkListItem(
                              _parksToDisplayInParkTab[index],
                            );
                          },
                        ),
              ),
            ],
          ),
          _isLoadingParks && _representativeParkForCourseTab == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: BLUE_SECONDARY_500),
                    SizedBox(height: 15),
                    Text(
                      "추천 코스 정보를 준비 중입니다...",
                      style: TextStyle(color: GRAYSCALE_LABEL_700),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(horizontalPageMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentRepresentativeParkForUI.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: GRAYSCALE_LABEL_950,
                                  ),
                                ),
                                SizedBox(height: 4),
                                if (currentRepresentativeParkForUI
                                    .type
                                    .isNotEmpty)
                                  Text(
                                    currentRepresentativeParkForUI.type,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: GRAYSCALE_LABEL_600,
                                    ),
                                  ),
                                SizedBox(height: 2),
                                if (currentRepresentativeParkForUI
                                    .address
                                    .isNotEmpty)
                                  Text(
                                    currentRepresentativeParkForUI.address,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: GRAYSCALE_LABEL_700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          if (!_isEditMode &&
                              currentRepresentativeParkForUI.id !=
                                  'initial_loading' &&
                              !currentRepresentativeParkForUI.id.startsWith(
                                'error_',
                              ) &&
                              currentRepresentativeParkForUI.id !=
                                  'no_park_data')
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (mounted) {
                                    setState(() {
                                      _representativeParkIsFavorite =
                                          !_representativeParkIsFavorite;
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    _representativeParkIsFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color:
                                        _representativeParkIsFavorite
                                            ? HEART_FILL
                                            : GRAYSCALE_LABEL_600,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Divider(
                      color: GRAYSCALE_LABEL_200,
                      height: 20,
                      thickness: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
                      child: Text(
                        "추천 코스 목록",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: GRAYSCALE_LABEL_800,
                        ),
                      ),
                    ),
                    _displayedCoursesOnCourseTab.isEmpty &&
                            !(_isLoadingParks &&
                                _representativeParkForCourseTab == null)
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30.0),
                            child: Text(
                              _isLoadingParks
                                  ? "코스 정보 로딩 중..."
                                  : "이 공원의 추천 코스가 아직 없습니다.",
                              style: TextStyle(
                                color: GRAYSCALE_LABEL_600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        : GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12.0,
                                mainAxisSpacing: 12.0,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: _displayedCoursesOnCourseTab.length,
                          itemBuilder: (context, index) {
                            return _buildCourseCardItem(
                              _displayedCoursesOnCourseTab[index],
                            );
                          },
                        ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: BACKGROUND_COLOR,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: GRAYSCALE_LABEL_950,
            size: 20,
          ),
          onPressed: () {
            if (_isEditMode && isCourseTabActive) {
              _toggleEditMode();
            } else {
              if (Navigator.canPop(context)) Navigator.pop(context);
            }
          },
        ),
        title: Text(
          "추천 코스",
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (canShowEditButtons) ...[
            if (_isEditMode)
              TextButton(
                onPressed: canShowDeleteButton ? _deleteSelectedCourses : null,
                child: Text(
                  "삭제",
                  style: TextStyle(
                    color:
                        canShowDeleteButton
                            ? RED_DANGER_TEXT_50
                            : GRAYSCALE_LABEL_400,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else if (canShowAddButton)
              TextButton(
                onPressed: _addCourse,
                child: Text(
                  "추가",
                  style: TextStyle(
                    color: BLUE_SECONDARY_700,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            TextButton(
              onPressed: _toggleEditMode,
              child: Text(
                _isEditMode ? "취소" : "편집",
                style: TextStyle(
                  color: _isEditMode ? GRAYSCALE_LABEL_700 : BLUE_SECONDARY_700,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          SizedBox(width: canShowEditButtons ? 8 : 16),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(49.0),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                onTap: (index) {
                  // _handleTabChange 리스너에서 처리
                },
                indicatorColor: GRAYSCALE_LABEL_950,
                indicatorWeight: 2.5,
                labelColor: GRAYSCALE_LABEL_950,
                unselectedLabelColor: GRAYSCALE_LABEL_500,
                labelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
                tabs: [Tab(text: "공원"), Tab(text: "추천 코스")],
              ),
              Divider(color: GRAYSCALE_LABEL_200, height: 1, thickness: 1),
            ],
          ),
        ),
      ),
      body: bodyContent,
    );
  }
}
