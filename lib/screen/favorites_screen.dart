import 'package:flutter/material.dart';
import 'package:my_movie_base/screen/movie_detail_screen.dart';
import 'package:my_movie_base/services/favorite_provider.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  FavoritesScreenState createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoriteProvider>(context, listen: false).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '관심 목록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, child) {
          final movies = favoriteProvider.favorites;

          if (movies.isEmpty) {
            return const Center(
              child: Text(
                '관심 목록이 비어있습니다.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(
                        movie: movie,
                        heroTag: 'favorite_${movie.id}',
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Stack(
                    children: [
                      // 배경 포스터
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(
                                movie.backdropPath ?? movie.posterPath!),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.8),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                      ),
                      // 삭제 버튼
                      Positioned(
                        top: 3,
                        right: 3,
                        child: IconButton(
                          onPressed: () async {
                            await favoriteProvider.toggleFavorite(movie);
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('관심 목록에서 삭제되었습니다'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      // 영화 정보
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // 포스터 이미지
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                movie.posterPath!,
                                width: 110,
                                height: 165,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 영화 상세 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    movie.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '평점: ${(movie.voteAverage! * 10).toInt()}%',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              child: LinearProgressIndicator(
                                                value:
                                                    (movie.voteAverage ?? 0) /
                                                        10,
                                                backgroundColor:
                                                    Colors.grey[800],
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  movie.voteAverage! >= 7
                                                      ? Colors.green
                                                      : movie.voteAverage! >= 5
                                                          ? Colors.lime
                                                          : movie.voteAverage! >=
                                                                  3
                                                              ? Colors.orange
                                                              : Colors.red,
                                                ),
                                                minHeight: 5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Expanded(
                                        flex: 2,
                                        child: SizedBox(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    movie.genresText,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    movie.overview ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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
    );
  }
}
