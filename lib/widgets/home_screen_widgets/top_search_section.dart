import 'package:flutter/material.dart';
import 'package:my_movie_base/screens/movie_detail_screen.dart';
import 'package:my_movie_base/services/api_service.dart';

class TopSearchSection extends StatefulWidget {
  const TopSearchSection({super.key});

  @override
  State<TopSearchSection> createState() => _TopSearchSectionState();
}

class _TopSearchSectionState extends State<TopSearchSection> {
  final ApiService _apiService = ApiService();
  bool isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SearchAnchor.bar(
        isFullScreen: false,
        barHintText: '검색하고 싶은 영화가 있으신가요?',
        barHintStyle: MaterialStateProperty.all(
          TextStyle(color: Colors.grey[400]),
        ),
        barTextStyle: MaterialStateProperty.all(
          const TextStyle(color: Colors.white),
        ),
        barBackgroundColor: MaterialStateProperty.all(Colors.grey[900]),
        barOverlayColor: MaterialStateProperty.all(Colors.grey[900]),
        barElevation: MaterialStateProperty.all(0),
        barPadding: const MaterialStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16.0),
        ),
        barLeading: Icon(Icons.search, color: Colors.grey[400]),
        suggestionsBuilder: (context, controller) async {
          // 검색어가 없으면 빈 리스트 반환
          if (controller.text.trim().isEmpty) return [];

          // 검색 결과를 가져와서 ListTile 리스트로 변환
          final results = await _apiService.searchMovies(controller.text);
          return results
              .map((movie) => ListTile(
                    title: Text(
                      movie.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailScreen(
                            movie: movie,
                            heroTag: 'search_${movie.id}',
                          ),
                        ),
                      );
                    },
                  ))
              .toList();
        },
      ),
    );
  }
}
