enum TrackKind { soundscape, meditation }

class MediaTrack {
  const MediaTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.category,
    required this.accentColor,
    this.assetPath,
    this.remoteUrl,
    this.cachedFilePath,
    this.script,
    this.builtIn = false,
    this.loop = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final TrackKind kind;
  final String category;
  final int accentColor;
  final String? assetPath;
  final String? remoteUrl;
  final String? cachedFilePath;
  final String? script;
  final bool builtIn;
  final bool loop;

  bool get hasPlayableSource =>
      (cachedFilePath?.isNotEmpty ?? false) ||
      (assetPath?.isNotEmpty ?? false) ||
      (remoteUrl?.isNotEmpty ?? false);

  bool get isOfflineReady => builtIn || (cachedFilePath?.isNotEmpty ?? false);

  MediaTrack copyWith({
    String? id,
    String? title,
    String? subtitle,
    TrackKind? kind,
    String? category,
    int? accentColor,
    String? assetPath,
    String? remoteUrl,
    String? cachedFilePath,
    String? script,
    bool? builtIn,
    bool? loop,
  }) {
    return MediaTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      kind: kind ?? this.kind,
      category: category ?? this.category,
      accentColor: accentColor ?? this.accentColor,
      assetPath: assetPath ?? this.assetPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      cachedFilePath: cachedFilePath ?? this.cachedFilePath,
      script: script ?? this.script,
      builtIn: builtIn ?? this.builtIn,
      loop: loop ?? this.loop,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'kind': kind.name,
      'category': category,
      'accentColor': accentColor,
      'assetPath': assetPath,
      'remoteUrl': remoteUrl,
      'cachedFilePath': cachedFilePath,
      'script': script,
      'builtIn': builtIn,
      'loop': loop,
    };
  }

  factory MediaTrack.fromJson(Map<String, dynamic> json) {
    return MediaTrack(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      kind: TrackKind.values.byName(json['kind'] as String),
      category: json['category'] as String,
      accentColor: json['accentColor'] as int,
      assetPath: json['assetPath'] as String?,
      remoteUrl: json['remoteUrl'] as String?,
      cachedFilePath: json['cachedFilePath'] as String?,
      script: json['script'] as String?,
      builtIn: json['builtIn'] as bool? ?? false,
      loop: json['loop'] as bool? ?? true,
    );
  }
}
