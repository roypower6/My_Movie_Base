import 'package:flutter/material.dart';
import 'package:my_movie_base/models/movie_model.dart';
import 'package:my_movie_base/screens/movie_detail_screen.dart';
import 'package:my_movie_base/services/api_service.dart';
import 'package:my_movie_base/widgets/home_screen_widgets/section_title.dart';

class WeeklyBoxOffice extends StatefulWidget {
  const WeeklyBoxOffice({super.key});

  @override
  State<WeeklyBoxOffice> createState() => _WeeklyBoxOfficeState();
}

class _WeeklyBoxOfficeState extends State<WeeklyBoxOffice> {
  final ApiService _apiService = ApiService();
  late Future<List<Movie>> weeklyBoxOffice;

  @override
  void initState() {
    super.initState();
    weeklyBoxOffice = _apiService.getWeeklyBoxOffice();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '한국 주간 박스오피스 순위'),
        FutureBuilder<List<Movie>>(
          future: weeklyBoxOffice,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No movies available'));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  snapshot.data!.length > 10 ? 10 : snapshot.data!.length,
              itemBuilder: (context, index) {
                final movie = snapshot.data![index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(
                          movie: movie,
                          heroTag: 'boxOffice_${movie.id}',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]?.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[800]!,
                        width: 0.5,
                      ),
                    ),
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 35,
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: index < 3 ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            movie.posterPath!,
                            width: 60,
                            height: 90,
                            fit: BoxFit.cover,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '평점: ${((movie.voteAverage ?? 0) * 10).toInt()}% | ${movie.genresText}',
                                style: TextStyle(
                                  color: Colors.grey[400],
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
            );
          },
        ),
      ],
    );
  }
}
