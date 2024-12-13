import 'package:flutter/material.dart';
import 'package:my_movie_base/models/movie_model.dart';
import 'package:my_movie_base/screens/movie_item.dart';
import 'package:my_movie_base/services/api_service.dart';
import 'package:my_movie_base/widgets/home_screen_widgets/top_rated.dart';
import 'dart:async';
import 'package:my_movie_base/widgets/home_screen_widgets/top_search_section.dart';
import 'package:my_movie_base/widgets/home_screen_widgets/weekly_box_office.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  MovieListScreenState createState() => MovieListScreenState();
}

class MovieListScreenState extends State<MovieListScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  bool isSearching = false;

  late Future<List<Movie>> playingMovies; // 현재 상영 중인 영화
  late Future<List<Movie>> popularMovies; // 유명 영화
  late Future<List<Movie>> upcomingMovies; // 상영 예정 영화
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMovies() {
    playingMovies = _apiService.getPlayingMovies();
    upcomingMovies = _apiService.getUpcomingMovies();
    popularMovies = _apiService.getPopularMovies();
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
              const TopSearchSection(),
              const SizedBox(height: 16),
              _buildToggleAndMovieSection(),
              const SizedBox(height: 16),
              const WeeklyBoxOffice(),
              const SizedBox(height: 16),
              const TopRated(),
              const SizedBox(height: 24),
            ],
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
              // 1
              _buildToggleButton(
                index: 0,
                icon: Icons.movie_outlined,
                label: '현재 상영중',
              ),
              // 1
              _buildToggleButton(
                index: 1,
                icon: Icons.upcoming_outlined,
                label: '상영 예정',
              ),
            ],
          ),
        ),
        // 2
        _buildMovieSection(
          selectedIndex == 0 ? playingMovies : upcomingMovies,
          isHorizontal: true,
        ),
      ],
    );
  }

  // 1. 현재 상영중, 상영 예정 영화 목록 섹션 토글 버튼
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

  // 2. 현재 상영중, 상영 예정 영화 목록 가로 리스트
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
}
