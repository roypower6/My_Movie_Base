import 'package:flutter/material.dart';
import 'package:my_movie_base/model/movie_model.dart';
import 'package:my_movie_base/screen/movie_item.dart';
import 'package:my_movie_base/services/api_service.dart';
import 'package:my_movie_base/screen/movie_detail_screen.dart';
import 'dart:async';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  MovieListScreenState createState() => MovieListScreenState();
}

class MovieListScreenState extends State<MovieListScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  late Future<List<Movie>> playingMovies;
  late Future<List<Movie>> popularMovies;
  late Future<List<Movie>> upcomingMovies;
  late Future<List<Movie>> topRatedMovies;
  int selectedIndex = 0; // 선택된 토글 인덱스
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadMovies();
    // 자동 슬라이드 타이머 시작
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        if (_currentPage < 4) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _loadMovies() {
    playingMovies = _apiService.getPlayingMovies(); // 상영중인 영화
    upcomingMovies = _apiService.getUpcomingMovies(); // 개봉 예정 영화
    popularMovies = _apiService.getPopularMovies(); // 인기 영화
    topRatedMovies = _apiService.getTopRatedMovies(page: currentPage); //탑 랭킹 영화
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Movie Base',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 27,
              ),
        ),
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
              _buildHeroSection(),
              _buildToggleAndMovieSection(),
              const SizedBox(height: 8),
              _buildTopRatedSection(),
              _buildPagination(),
            ],
          ),
        ),
      ),
    );
  }

  // 최상단 자동 슬라이드 섹션
  Widget _buildHeroSection() {
    return FutureBuilder<List<Movie>>(
      future: popularMovies,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final heroMovies = snapshot.data!.take(5).toList();

        return Stack(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: heroMovies.length,
                itemBuilder: (context, index) {
                  final movie = heroMovies[index];
                  return Stack(
                    children: [
                      // 배경 이미지
                      Image.network(
                        movie.backdropPath ?? movie.posterPath!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      // 그라데이션 오버레이
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                      // 영화 정보
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              movie.overview ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // 페이지 인디케이터 추가
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  heroMovies.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.blue
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
                      child: MovieItem(movie: movie),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  //TMDB 선정 영화 순위 섹션
  Widget _buildTopRatedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'TMDB 선정 영화 순위',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
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
                        builder: (context) => MovieDetailScreen(movie: movie),
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
}
