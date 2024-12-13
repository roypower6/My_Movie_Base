import 'package:flutter/material.dart';
import 'package:my_movie_base/models/movie_model.dart';
import 'package:my_movie_base/services/api_service.dart';

class MovieDetails extends StatefulWidget {
  final BuildContext context;
  final Movie movie;

  const MovieDetails({
    super.key,
    required this.context,
    required this.movie,
  });

  @override
  State<MovieDetails> createState() => _MovieDetailsState();
}

class _MovieDetailsState extends State<MovieDetails> {
  late Future<String?> _movieRatingFuture;

  @override
  void initState() {
    super.initState();
    _movieRatingFuture = ApiService().getMovieRating(widget.movie.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                widget.movie.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            FutureBuilder<String?>(
              future: _movieRatingFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox.shrink();
                }

                final rating = snapshot.data!;

                // 등급에 따른 색상 및 배경색 결정
                Color textColor;
                Color backgroundColor;
                Color borderColor;

                // 등급 텍스트 변환
                String displayRating = rating;
                if (rating == 'ALL' || rating == 'G' || rating == 'All') {
                  displayRating = '전체 관람가';
                  textColor = Colors.green[700]!;
                  backgroundColor = Colors.green[50]!;
                  borderColor = Colors.green[200]!;
                } else if (rating == '12' || rating.startsWith('12')) {
                  displayRating = '12세 이상 관람가';
                  textColor = Colors.blue[700]!;
                  backgroundColor = Colors.blue[50]!;
                  borderColor = Colors.blue[200]!;
                } else if (rating == '15' || rating.startsWith('15')) {
                  displayRating = '15세 이상 관람가';
                  textColor = Colors.orange[700]!;
                  backgroundColor = Colors.orange[50]!;
                  borderColor = Colors.orange[200]!;
                } else if (rating == '18' ||
                    rating == '19' ||
                    rating == 'R' ||
                    rating.contains('청소년')) {
                  displayRating = '청소년 관람불가';
                  textColor = Colors.red[700]!;
                  backgroundColor = Colors.red[50]!;
                  borderColor = Colors.red[200]!;
                } else if (rating == 'NR') {
                  displayRating = 'Not Rated';
                  textColor = Theme.of(context).colorScheme.primary;
                  backgroundColor =
                      Theme.of(context).colorScheme.primary.withOpacity(0.1);
                  borderColor =
                      Theme.of(context).colorScheme.primary.withOpacity(0.3);
                } else {
                  // 기타 등급의 경우
                  textColor = Theme.of(context).colorScheme.primary;
                  backgroundColor =
                      Theme.of(context).colorScheme.primary.withOpacity(0.1);
                  borderColor =
                      Theme.of(context).colorScheme.primary.withOpacity(0.3);
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    displayRating,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '개봉일: ${widget.movie.formattedReleaseDate}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '장르: ${widget.movie.genresText}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '언어: ${widget.movie.languageText}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '상영시간: ${widget.movie.formattedRuntime}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 24),
        Text(
          '줄거리',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.movie.overview ?? '줄거리 정보가 없습니다.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        if (widget.movie.voteCount != null && widget.movie.voteCount! > 0) ...[
          Text(
            '평가',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              SizedBox(
                width: 65,
                height: 65,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (widget.movie.voteAverage ?? 0) / 10,
                      strokeWidth: 8,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          widget.movie.voteAverage! >= 7
                              ? Colors.green
                              : widget.movie.voteAverage! >= 5
                                  ? Colors.lime
                                  : widget.movie.voteAverage! >= 3
                                      ? Colors.orange
                                      : Colors.red),
                    ),
                    Center(
                      child: Text(
                        '${((widget.movie.voteAverage! * 10)).toStringAsFixed(1)}%',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const SizedBox(
                    height: 40,
                  ),
                  Text(
                    "${widget.movie.formattedVoteCount}를 기준으로 산출",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
