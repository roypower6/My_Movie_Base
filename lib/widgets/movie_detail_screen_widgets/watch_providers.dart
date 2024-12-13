import 'package:flutter/material.dart';
import 'package:my_movie_base/models/movie_model.dart';
import 'package:my_movie_base/services/api_service.dart';

class WatchProviders extends StatefulWidget {
  final Movie movie;

  const WatchProviders({
    super.key,
    required this.movie,
  });

  @override
  State<WatchProviders> createState() => _WatchProvidersState();
}

class _WatchProvidersState extends State<WatchProviders> {
  late Future<Map<String, List<String>>> _watchProvidersFuture;

  @override
  void initState() {
    super.initState();
    _watchProvidersFuture = ApiService().getWatchProviders(widget.movie.id);
  }

  @override
  Widget build(BuildContext context) {
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
}
