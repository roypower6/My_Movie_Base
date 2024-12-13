import 'package:flutter/material.dart';
import 'package:my_movie_base/models/movie_model.dart';
import 'package:my_movie_base/screens/movie_detail_screen.dart';
import 'package:my_movie_base/services/api_service.dart';

class TopSearchSection extends StatefulWidget {
  const TopSearchSection({super.key});

  @override
  State<TopSearchSection> createState() => _TopSearchSectionState();
}

class _TopSearchSectionState extends State<TopSearchSection> {
  final LayerLink _layerLink = LayerLink();
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;
  OverlayEntry? _overlayEntry;
  List<Movie> searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      _removeOverlay();
    }
  }

  Future<void> _searchMovies(String query) async {
    if (query.trim().isEmpty) {
      _removeOverlay();
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final results = await _apiService.searchMovies(query);
      setState(() {
        searchResults = results;
        isSearching = false;
      });

      // 검색 결과 오버레이 생성
      _removeOverlay();
      _createOverlay();
    } catch (e) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _createOverlay() {
    if (searchResults.isEmpty) return;

    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    var size = renderBox?.size ?? Size.zero;
    var offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 17,
        top: offset.dy + 90, // 검색바 아래
        width: size.width - 32, // 검색바와 같은 너비
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(15, 70), // 검색바 아래에 위치
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final movie = searchResults[index];
                  return InkWell(
                    onTap: () {
                      _removeOverlay();
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[800]!,
                            width: 0.5,
                          ),
                        ),
                      ),
                      // 각 영화 검색 결과 타일
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              movie.posterPath ?? '',
                              width: 40,
                              height: 65,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 40,
                                  height: 65,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.movie,
                                    color: Colors.white54,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${movie.releaseYear} · ${movie.genresText}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
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
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _searchMovies,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '검색하고 싶은 영화가 있으신가요?',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400]),
                    onPressed: () {
                      _searchController.clear();
                      _removeOverlay();
                      setState(() {
                        searchResults = [];
                        isSearching = false;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }
}
