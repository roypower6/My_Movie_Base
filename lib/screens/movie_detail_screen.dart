import 'package:flutter/material.dart';
import 'package:my_movie_base/models/movie_model.dart';
import 'package:my_movie_base/services/api_service.dart';
import 'package:my_movie_base/services/favorite_provider.dart';
import 'package:my_movie_base/services/favorite_service.dart';
import 'package:my_movie_base/widgets/movie_detail_screen_widgets/movie_cast.dart';
import 'package:my_movie_base/widgets/movie_detail_screen_widgets/movie_details.dart';
import 'package:my_movie_base/widgets/movie_detail_screen_widgets/movie_reviews.dart';
import 'package:my_movie_base/widgets/movie_detail_screen_widgets/video_trailer.dart';
import 'package:my_movie_base/widgets/movie_detail_screen_widgets/watch_providers.dart';
import 'package:provider/provider.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  final String heroTag;

  const MovieDetailScreen({
    super.key,
    required this.movie,
    required this.heroTag,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Future<Movie> _movieDetailsFuture;
  late Future<bool> _isFavoriteFuture;
  final FavoriteService _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _movieDetailsFuture = _fetchMovieDetails();
    _isFavoriteFuture = _checkFavoriteStatus();
  }

  // 영화 상세 정보 조회 (MovieDetails Class에 영화 상세 정보 전송)
  Future<Movie> _fetchMovieDetails() async {
    final apiService = ApiService();
    return await apiService.getMovieDetails(widget.movie.id);
  }

  // 즐겨찾기 상태 조회
  Future<bool> _checkFavoriteStatus() async {
    return await _favoriteService.isFavorite(widget.movie.id);
  }

  // 즐겨찾기 상태 토글
  void _toggleFavorite() async {
    final favoriteProvider =
        Provider.of<FavoriteProvider>(context, listen: false);
    await favoriteProvider.toggleFavorite(widget.movie);
    setState(() {
      _isFavoriteFuture = _checkFavoriteStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Movie>(
        future: _movieDetailsFuture,
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                expandedHeight: 400,
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: FutureBuilder<bool>(
                      future: _isFavoriteFuture,
                      builder: (context, favSnapshot) {
                        final isFavorite = favSnapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                          ),
                          onPressed: _toggleFavorite,
                        );
                      },
                    ),
                  ),
                ],
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.movie.posterPath != null)
                        Image.network(
                          widget.movie.fullPosterPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[850],
                              child: const Center(
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (snapshot.hasError)
                        Center(child: Text('Error: ${snapshot.error}'))
                      else if (snapshot.hasData) ...[
                        MovieDetails(context: context, movie: snapshot.data!),
                        const SizedBox(height: 10),
                        VideoTrailer(movie: widget.movie),
                        MovieCast(movie: widget.movie),
                        WatchProviders(movie: widget.movie),
                        MovieReviews(movie: widget.movie),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
