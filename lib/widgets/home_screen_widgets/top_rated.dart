import 'package:flutter/material.dart';
import 'package:my_movie_base/models/movie_model.dart';
import 'package:my_movie_base/screens/movie_detail_screen.dart';
import 'package:my_movie_base/services/api_service.dart';
import 'package:my_movie_base/widgets/home_screen_widgets/section_title.dart';

class TopRated extends StatefulWidget {
  const TopRated({super.key});

  @override
  State<TopRated> createState() => _TopRatedState();
}

class _TopRatedState extends State<TopRated> {
  final ApiService _apiService = ApiService();
  late Future<List<Movie>> topRatedMovies; // tmdb 선정 영화
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    topRatedMovies = _apiService.getTopRatedMovies();
    _loadMovies();
  }

  void _loadMovies() {
    topRatedMovies = _apiService.getTopRatedMovies(page: currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'TMDB 선정 영화 순위'),
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
        const SizedBox(height: 16),
        _buildPagination(),
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
