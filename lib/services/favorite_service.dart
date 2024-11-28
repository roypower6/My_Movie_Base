import 'dart:convert';

import 'package:my_movie_base/model/movie_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String _favoritesKey = 'favorite_movies';

  // 즐겨찾기 조회
  Future<List<Movie>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    return favoritesJson
        .map((json) => Movie.fromJson(jsonDecode(json)))
        .toList();
  }

  // 즐겨찾기 추가 및 삭제
  Future<void> toggleFavorite(Movie movie) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    // 즐겨찾기 존재 여부 확인
    final movieIndex = favoritesJson.indexWhere((json) {
      final existingMovie = Movie.fromJson(jsonDecode(json));
      return existingMovie.id == movie.id;
    });
    if (movieIndex >= 0) {
      // 즐겨찾기 삭제
      favoritesJson.removeAt(movieIndex);
    } else {
      // 즐겨찾기 추가
      final updatedMovie = movie.copyWith(isFavorite: true);
      favoritesJson.add(jsonEncode(updatedMovie.toJson()));
    }
    // 즐겨찾기 저장
    await prefs.setStringList(_favoritesKey, favoritesJson);
  }

  // 즐겨찾기 존재 여부 확인
  Future<bool> isFavorite(int movieId) async {
    final favorites = await getFavorites();
    return favorites.any((movie) => movie.id == movieId);
  }
}
