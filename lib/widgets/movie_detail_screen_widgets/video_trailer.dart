import 'package:flutter/material.dart';
import 'package:my_movie_base/models/movie_model.dart';
import 'package:my_movie_base/models/movie_video_model.dart';
import 'package:my_movie_base/services/api_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoTrailer extends StatefulWidget {
  final Movie movie;

  const VideoTrailer({super.key, required this.movie});

  @override
  State<VideoTrailer> createState() => _VideoTrailerState();
}

class _VideoTrailerState extends State<VideoTrailer> {
  late Future<List<MovieVideo>> _movieVideosFuture;
  String? _selectedVideoKey;
  YoutubePlayerController? _youtubeController;
  int _currentVideoPage = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _movieVideosFuture = ApiService().getMovieVideos(widget.movie.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _youtubeController?.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
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
            //트레일러 개수 인디케이터
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
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

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
              // 트레일러 썸네일
              Image.network(
                'https://img.youtube.com/vi/${video.key}/hqdefault.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.movie_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              // 그라데이션 필름
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
              // 트레일러 재생 버튼
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
              // 트레일러 제목
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
}
