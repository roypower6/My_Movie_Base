import 'package:flutter/material.dart';
import 'package:my_movie_base/models/movie_model.dart';
import 'package:my_movie_base/screens/movie_detail_screen.dart';

class MovieItem extends StatelessWidget {
  final Movie movie;

  const MovieItem({super.key, required this.movie, required String heroId});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MovieDetailScreen(
                movie: movie,
                heroTag: 'movie_${movie.id}',
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                var begin = const Offset(1.0, 0.0);
                var end = Offset.zero;
                var curve = Curves.easeInOutQuart;
                var tween = Tween(begin: begin, end: end).chain(
                  CurveTween(curve: curve),
                );
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: movie.posterPath != null
                      ? Hero(
                          tag: 'movie_${movie.id}',
                          child: Image.network(
                            movie.fullPosterPath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[850],
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.white54,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          color: Colors.grey[850],
                          child: const Center(
                            child: Icon(
                              Icons.movie_rounded,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (movie.releaseDate != null) ...[
                const SizedBox(height: 6),
                Text(
                  movie.releaseDate!.substring(0, 4),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
