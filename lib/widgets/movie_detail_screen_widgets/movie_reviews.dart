import 'package:flutter/material.dart';
import 'package:my_movie_base/models/movie_model.dart';
import 'package:my_movie_base/models/review_model.dart';
import 'package:my_movie_base/services/api_service.dart';

class MovieReviews extends StatefulWidget {
  final Movie movie;

  const MovieReviews({
    super.key,
    required this.movie,
  });

  @override
  State<MovieReviews> createState() => _MovieReviewsState();
}

class _MovieReviewsState extends State<MovieReviews> {
  late Future<List<Review>> _movieReviewsFuture;

  @override
  void initState() {
    super.initState();
    _movieReviewsFuture = _fetchMovieReviews();
  }

  // 영화 리뷰 조회
  Future<List<Review>> _fetchMovieReviews() async {
    final apiService = ApiService();
    return await apiService.getMovieReviews(widget.movie.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: _movieReviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '관람평',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '아직 작성된 관람평이 없습니다.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '관람평',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Tooltip(
                    showDuration: Duration(seconds: 5),
                    message:
                        "API 제공사 TMDB의 한국어 리뷰 부족으로 인해 \n영어권 리뷰를 제공드리는 점 양해 부탁드립니다.",
                    triggerMode: TooltipTriggerMode.tap,
                    child: Icon(
                      Icons.info,
                      size: 25,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...reviews.map((review) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  review.author,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                //리뷰에 레이팅이 있을 시 레이팅 가져오기
                                if (review.rating != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: Colors.amber[400],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${review.formattedRating.replaceAll('.0', '')} / 10",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              review.formattedDate,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              review.content,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
