class MovieVideo {
  final String id;
  final String key;
  final String name;
  final String type;

  MovieVideo({
    required this.id,
    required this.key,
    required this.name,
    required this.type,
  });

  MovieVideo.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        key = json['key'],
        name = json['name'],
        type = json['type'];
}
