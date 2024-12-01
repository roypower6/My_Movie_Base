import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_movie_base/model/actor_model.dart';
import 'package:my_movie_base/model/movie_model.dart';
import 'package:my_movie_base/model/movie_video_model.dart';
import 'package:my_movie_base/model/review_model.dart';
import 'package:my_movie_base/services/api_service.dart';
import 'package:my_movie_base/services/favorite_provider.dart';
import 'package:my_movie_base/services/favorite_service.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Future<Movie> _movieDetailsFuture;
  late Future<List<Actor>> _movieCreditsFuture;
  late Future<List<Review>> _movieReviewsFuture;
  late Future<bool> _isFavoriteFuture;
  late Future<String?> _movieRatingFuture;
  late Future<Actor?> _movieDirectorFuture;
  late Future<Map<String, List<String>>> _watchProvidersFuture;
  late Future<List<MovieVideo>> _movieVideosFuture;
  final FavoriteService _favoriteService = FavoriteService();
  String? _selectedVideoKey;
  YoutubePlayerController? _youtubeController;
  final PageController _pageController = PageController();
  int _currentVideoPage = 0;

  @override
  void initState() {
    super.initState();
    _movieDetailsFuture = _fetchMovieDetails();
    _movieCreditsFuture = _fetchMovieCredits();
    _movieReviewsFuture = _fetchMovieReviews();
    _isFavoriteFuture = _checkFavoriteStatus();
    _movieRatingFuture = ApiService().getMovieRating(widget.movie.id);
    _movieDirectorFuture = ApiService().getMovieDirector(widget.movie.id);
    _watchProvidersFuture = ApiService().getWatchProviders(widget.movie.id);
    _movieVideosFuture = ApiService().getMovieVideos(widget.movie.id);
  }

  // 영화 상세 정보 조회
  Future<Movie> _fetchMovieDetails() async {
    final apiService = ApiService();
    return await apiService.getMovieDetails(widget.movie.id);
  }

  // 영화 주요 출연진 조회
  Future<List<Actor>> _fetchMovieCredits() async {
    final apiService = ApiService();
    return await apiService.getMovieCredits(widget.movie.id);
  }

  // 영화 리뷰 조회
  Future<List<Review>> _fetchMovieReviews() async {
    final apiService = ApiService();
    return await apiService.getMovieReviews(widget.movie.id);
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

  void _playVideo(String videoKey) {
    setState(() {
      _selectedVideoKey = videoKey;
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoKey,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
        ),
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _youtubeController?.dispose();
    super.dispose();
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
                  FutureBuilder<bool>(
                    future: _isFavoriteFuture,
                    builder: (context, favSnapshot) {
                      final isFavorite = favSnapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: _toggleFavorite,
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.movie.posterPath != null
                      ? Image.network(
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
                        )
                      : Container(
                          color: Colors.grey[850],
                          child: const Center(
                            child: Icon(
                              Icons.movie_rounded,
                              size: 48,
                            ),
                          ),
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
                        _buildMovieDetails(context, snapshot.data!),
                        const SizedBox(height: 10),
                        _buildVideosSection(),
                        _buildCastSection(),
                        _buildWatchProvidersSection(),
                        _buildReviewsSection(),
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

  // 영화 상세 정보 섹션
  Widget _buildMovieDetails(BuildContext context, Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                movie.title,
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
          '개봉일: ${movie.formattedReleaseDate}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '장르: ${movie.genresText}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '언어: ${movie.languageText}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '상영시간: ${movie.formattedRuntime}',
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
          movie.overview ?? '줄거리 정보가 없습니다.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        if (movie.voteCount != null && movie.voteCount! > 0) ...[
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
                      value: (movie.voteAverage ?? 0) / 10,
                      strokeWidth: 8,
                      backgroundColor: Colors.transparent,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(movie.voteAverage! >= 7
                              ? Colors.green
                              : movie.voteAverage! >= 5
                                  ? Colors.lime
                                  : movie.voteAverage! >= 3
                                      ? Colors.orange
                                      : Colors.red),
                    ),
                    Center(
                      child: Text(
                        '${((movie.voteAverage! * 10)).toStringAsFixed(1)}%',
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
                    "${movie.formattedVoteCount}를 기준으로 산출",
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

  // 예고편 & 영상 유튜브 위젯
  Widget _buildVideosSection() {
    return FutureBuilder<List<MovieVideo>>(
      future: _movieVideosFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final videos = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '예고편 & 영상',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (_selectedVideoKey != null && _youtubeController != null) ...[
              Hero(
                tag: 'video_player',
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(
                    controller: _youtubeController!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.red,
                    progressColors: const ProgressBarColors(
                      playedColor: Colors.red,
                      handleColor: Colors.redAccent,
                    ),
                    onEnded: (metaData) {
                      setState(() {
                        _selectedVideoKey = null;
                        _youtubeController?.dispose();
                        _youtubeController = null;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: videos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentVideoPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Hero(
                      tag: 'video_thumbnail_${videos[index].key}',
                      child: _buildVideoThumbnail(videos[index]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // 페이지 인디케이터
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < videos.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentVideoPage
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // 예고편 & 영상 유튜브 썸네일 위젯
  Widget _buildVideoThumbnail(MovieVideo video) {
    final isSelected = video.key == _selectedVideoKey;
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          setState(() {
            _selectedVideoKey = null;
            _youtubeController?.dispose();
            _youtubeController = null;
          });
        } else {
          _playVideo(video.key);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://img.youtube.com/vi/${video.key}/hqdefault.jpg',
                fit: BoxFit.cover,
              ),
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
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSelected ? Icons.stop : Icons.play_arrow,
                    color: isSelected ? Colors.red : Colors.white,
                    size: 30,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  video.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 주요 출연진 섹션
  Widget _buildCastSection() {
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

  // 감상 가능한 곳 섹션
  Widget _buildWatchProvidersSection() {
    return FutureBuilder<Map<String, List<String>>>(
      future: _watchProvidersFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final providers = snapshot.data!;

        return Container(
          margin: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '감상 가능한 곳',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (providers['flatrate']?.isNotEmpty ?? false)
                _buildProviderCard(
                  context: context,
                  title: '스트리밍',
                  providers: providers['flatrate']!,
                  icon: Icons.play_circle_outline_rounded,
                  gradientColors: [
                    Colors.grey[900]!,
                    Colors.grey[850]!,
                  ],
                  iconColor: Colors.red[400]!,
                ),
              if (providers['rent']?.isNotEmpty ?? false)
                _buildProviderCard(
                  context: context,
                  title: '대여',
                  providers: providers['rent']!,
                  icon: Icons.shopping_bag_outlined,
                  gradientColors: [
                    Colors.grey[900]!,
                    Colors.grey[850]!,
                  ],
                  iconColor: Colors.blue[400]!,
                ),
              if (providers['buy']?.isNotEmpty ?? false)
                _buildProviderCard(
                  context: context,
                  title: '구매',
                  providers: providers['buy']!,
                  icon: Icons.shopping_cart_outlined,
                  gradientColors: [
                    Colors.grey[900]!,
                    Colors.grey[850]!,
                  ],
                  iconColor: Colors.green[400]!,
                ),
            ],
          ),
        );
      },
    );
  }

  // 감상 가능한 곳 카드
  Widget _buildProviderCard({
    required BuildContext context,
    required String title,
    required List<String> providers,
    required IconData icon,
    required List<Color> gradientColors,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: providers.map((provider) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: iconColor,
                              size: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                provider,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 리뷰 섹션
  Widget _buildReviewsSection() {
    return FutureBuilder<List<Review>>(
      future: _movieReviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          if (kDebugMode) {
            print('Review error: ${snapshot.error}'); // 에러 로깅
          }
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
