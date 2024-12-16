import 'package:flutter/material.dart';
import 'package:my_movie_base/models/movie_model.dart';

class MovieTile extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  final bool fromSearch;

  const MovieTile({
    super.key,
    required this.movie,
    required this.onTap,
    required this.fromSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: _buildLeadingImage(),
      title: Text(
        movie.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${movie.releaseYear.isNotEmpty ? movie.releaseYear : '미정'} · ${movie.genres.isNotEmpty ? movie.genresText : '장르 없음'}',
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: _buildRating(),
    );
  }

  Widget _buildLeadingImage() {
    return movie.posterPath != null
        ? Image.network(
            movie.thumbnailPath,
            width: 50,
            height: 75,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.movie, size: 50);
            },
          )
        : const Icon(Icons.movie, size: 50);
  }

  Widget _buildRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 1.5),
        Text(
          movie.voteAverage != null && movie.voteAverage != 0.0
              ? '${((movie.voteAverage! * 10)).toInt()}%'
              : 'N/R',
        ),
      ],
    );
  }
}
