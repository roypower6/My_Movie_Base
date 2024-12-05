import 'package:flutter/material.dart';
import 'package:my_movie_base/models/movie_model.dart';
import 'package:my_movie_base/screens/movie_item.dart';
import 'package:my_movie_base/services/api_service.dart';
import 'package:my_movie_base/screens/movie_detail_screen.dart';
import 'dart:async';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  MovieListScreenState createState() => MovieListScreenState();
}

class MovieListScreenState extends State<MovieListScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Movie> searchResults = [];
  bool isSearching = false;

  late Future<List<Movie>> playingMovies; // 현재 상영 중인 영화
  late Future<List<Movie>> popularMovies; // 유명 영화
  late Future<List<Movie>> upcomingMovies; // 상영 예정 영화
  late Future<List<Movie>> topRatedMovies; // tmdb 선정 영화
  late Future<List<Movie>> weeklyBoxOffice; // 주간 박스오피스
  int selectedIndex = 0;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _loadMovies() {
    playingMovies = _apiService.getPlayingMovies();
    upcomingMovies = _apiService.getUpcomingMovies();
    popularMovies = _apiService.getPopularMovies();
    topRatedMovies = _apiService.getTopRatedMovies(page: currentPage);
    weeklyBoxOffice = _apiService.getWeeklyBoxOffice();
  }

  Future<void> _searchMovies(String query) async {
    if (query.trim().isEmpty) {
      _removeOverlay();
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final results = await _apiService.searchMovies(query);
      setState(() {
        searchResults = results;
        isSearching = false;
      });

      // 검색 결과 오버레이 생성
      _removeOverlay();
      _createOverlay();
    } catch (e) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
    }
  }

  void _createOverlay() {
    if (searchResults.isEmpty) return;

    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    var size = renderBox?.size ?? Size.zero;
    var offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 17,
        top: offset.dy + 90, // 검색바 아래
        width: size.width - 32, // 검색바와 같은 너비
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(15, 70), // 검색바 아래에 위치
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final movie = searchResults[index];
                  return InkWell(
                    onTap: () {
                      _removeOverlay();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailScreen(
                            movie: movie,
                            heroTag: 'search_${movie.id}',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[800]!,
                            width: 0.5,
                          ),
                        ),
                      ),
                      // 각 영화 검색 결과 타일
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              movie.posterPath ?? '',
                              width: 40,
                              height: 65,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 40,
                                  height: 65,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.movie,
                                    color: Colors.white54,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${movie.releaseYear} · ${movie.genresText}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // 최상단 검색 섹션
  Widget _buildSearchSection() {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _searchMovies,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '검색하고 싶은 영화가 있으신가요?',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400]),
                    onPressed: () {
                      _searchController.clear();
                      _removeOverlay();
                      setState(() {
                        searchResults = [];
                        isSearching = false;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  //현재 상영중, 상영 예정 영화 목록 섹션
  Widget _buildToggleAndMovieSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              _buildToggleButton(
                index: 0,
                icon: Icons.movie_outlined,
                label: '현재 상영중',
              ),
              _buildToggleButton(
                index: 1,
                icon: Icons.upcoming_outlined,
                label: '상영 예정',
              ),
            ],
          ),
        ),
        _buildMovieSection(
          selectedIndex == 0 ? playingMovies : upcomingMovies,
          isHorizontal: true,
        ),
      ],
    );
  }

  //현재 상영중, 상영 예정 영화 목록 섹션 토글 버튼
  Widget _buildToggleButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey[400],
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovieSection(Future<List<Movie>> futureMovies,
      {bool isHorizontal = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isHorizontal)
          SizedBox(
            height: 280,
            child: FutureBuilder<List<Movie>>(
              future: futureMovies,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No movies available'));
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final movie = snapshot.data![index];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      child: MovieItem(
                        movie: movie,
                        heroId: 'search_${movie.id}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // 섹션 타이틀을 위한 공통 위젯
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 섹션 구분선
  Widget _buildSectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 1,
        color: Colors.grey[800],
      ),
    );
  }

  //TMDB 선정 영화 순위 섹션
  Widget _buildTopRatedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('TMDB 선정 영화 순위'),
        FutureBuilder<List<Movie>>(
          future: topRatedMovies,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No movies available'));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final movie = snapshot.data![index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(
                          movie: movie,
                          heroTag: 'topRated_${movie.id}',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 35,
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1 + (currentPage - 1) * 20}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: (index + (currentPage - 1) * 20) < 3
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            movie.posterPath!,
                            width: 60,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '평점: ${((movie.voteAverage ?? 0) * 10).toInt()}% | ${movie.genresText}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  //영화 순위 페이지네이션 (1~10페이지)
  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (index) {
          final page = index + 1;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  currentPage = page;
                  _loadMovies();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: currentPage == page ? Colors.blue : Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$page',
                  style: TextStyle(
                    color:
                        currentPage == page ? Colors.white : Colors.grey[400],
                    fontWeight: currentPage == page
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  //주간 박스오피스 순위
  Widget _buildWeeklyBoxOfficeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('한국 주간 박스오피스 순위'),
        FutureBuilder<List<Movie>>(
          future: weeklyBoxOffice,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No movies available'));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  snapshot.data!.length > 10 ? 10 : snapshot.data!.length,
              itemBuilder: (context, index) {
                final movie = snapshot.data![index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(
                          movie: movie,
                          heroTag: 'boxOffice_${movie.id}',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]?.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[800]!,
                        width: 0.5,
                      ),
                    ),
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 35,
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: index < 3 ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            movie.posterPath!,
                            width: 60,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '평점: ${((movie.voteAverage ?? 0) * 10).toInt()}% | ${movie.genresText}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'My Movie Base',
          style: TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadMovies();
          });
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchSection(),
              const SizedBox(height: 16),
              _buildToggleAndMovieSection(),
              _buildSectionDivider(),
              _buildWeeklyBoxOfficeSection(),
              _buildSectionDivider(),
              _buildTopRatedSection(),
              const SizedBox(height: 16),
              _buildPagination(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
