import 'package:flutter/material.dart';
import 'package:my_movie_base/models/actor_model.dart';
import 'package:my_movie_base/models/movie_model.dart';
import 'package:my_movie_base/services/api_service.dart';

class MovieCast extends StatefulWidget {
  final Movie movie;

  const MovieCast({
    super.key,
    required this.movie,
  });

  @override
  State<MovieCast> createState() => _MovieCastState();
}

class _MovieCastState extends State<MovieCast> {
  late Future<Actor?> _movieDirectorFuture;
  late Future<List<Actor>> _movieCreditsFuture;

  @override
  void initState() {
    super.initState();
    _movieDirectorFuture = ApiService().getMovieDirector(widget.movie.id);
    _movieCreditsFuture = ApiService().getMovieCredits(widget.movie.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 감독 섹션
        FutureBuilder<Actor?>(
          future: _movieDirectorFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox.shrink();
            }

            final director = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '감독',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const SizedBox(width: 5),
                    if (director.profilePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          'https://image.tmdb.org/t/p/w200${director.profilePath}',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.person,
                                color: Colors.white54,
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Director',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[400],
                                      letterSpacing: 1.2,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            director.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),

        // 배우 섹션
        FutureBuilder<List<Actor>>(
          future: _movieCreditsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final actors = snapshot.data!.take(10).toList(); // 상위 10명의 배우만 표시

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '주요 출연진',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: actors.map((actor) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: actor.profilePath != null
                                  ? NetworkImage(actor.fullProfilePath)
                                  : null,
                              child: actor.profilePath == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              actor.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              actor.character,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
