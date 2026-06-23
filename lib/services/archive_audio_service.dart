import 'package:dio/dio.dart';

class ArchiveAudioService {
  ArchiveAudioService({required Dio dio, required String backendBaseUrl})
    : _dio = dio,
      _backendBaseUrls = _buildBackendBaseUrls(backendBaseUrl);

  final Dio _dio;
  final List<String> _backendBaseUrls;

  Future<List<SearchResultItem>> search({
    required String keyword,
    required int page,
  }) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return const <SearchResultItem>[];
    }

    Object? lastError;
    StackTrace? lastStackTrace;
    for (final baseUrl in _backendBaseUrls) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          '$baseUrl/api/audio/search',
          queryParameters: <String, Object?>{
            'q': trimmed,
            'page': page,
            'limit': 12,
          },
          options: Options(
            receiveTimeout: const Duration(seconds: 30),
            headers: const <String, String>{
              // Mobile carriers sometimes reset reused HTTPS sockets.
              'Connection': 'close',
            },
          ),
        );

        final results =
            response.data?['results'] as List<dynamic>? ?? const <dynamic>[];
        return results
            .map(
              (item) => SearchResultItem.fromJson(item as Map<String, dynamic>),
            )
            .where((item) => item.identifier.isNotEmpty)
            .toList(growable: false);
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        if (!_canRetryWithNextBackendUrl(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }
      }
    }
    Error.throwWithStackTrace(
      BackendAudioConnectionException(_backendBaseUrls, lastError),
      lastStackTrace ?? StackTrace.current,
    );
  }

  Future<List<AudioFileItem>> filesFor(SearchResultItem item) async {
    return item.files;
  }
}

class BackendAudioConnectionException implements Exception {
  const BackendAudioConnectionException(this.triedBaseUrls, this.cause);

  final List<String> triedBaseUrls;
  final Object? cause;

  @override
  String toString() {
    return 'BackendAudioConnectionException: tried ${triedBaseUrls.join(', ')}; '
        'last error: $cause';
  }
}

bool _canRetryWithNextBackendUrl(Object error) {
  if (error is! DioException) {
    return false;
  }
  return switch (error.type) {
    DioExceptionType.badCertificate ||
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.unknown => true,
    DioExceptionType.badResponse => (error.response?.statusCode ?? 0) >= 500,
    DioExceptionType.cancel => false,
  };
}

List<String> _buildBackendBaseUrls(String backendBaseUrl) {
  final primary = backendBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
  if (primary.isEmpty) {
    return const <String>[];
  }
  final urls = <String>[primary];
  final uri = Uri.tryParse(primary);
  if (uri != null && uri.scheme == 'https' && uri.host == 'skydogs.top') {
    urls.add(
      uri
          .replace(host: '115.29.232.99')
          .toString()
          .replaceFirst(RegExp(r'/$'), ''),
    );
  }
  if (uri != null && uri.scheme == 'https') {
    urls.add(
      uri.replace(scheme: 'http').toString().replaceFirst(RegExp(r'/$'), ''),
    );
  }
  return urls.toSet().toList(growable: false);
}

class SearchResultItem {
  const SearchResultItem({
    required this.identifier,
    required this.title,
    required this.creator,
    required this.mediatype,
    required this.format,
    required this.source,
    required this.files,
  });

  final String identifier;
  final String title;
  final String creator;
  final String mediatype;
  final String format;
  final String source;
  final List<AudioFileItem> files;

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    final filesJson =
        json['files'] as List<dynamic>? ??
        json['audioFiles'] as List<dynamic>? ??
        const <dynamic>[];
    return SearchResultItem(
      identifier: _stringValue(json['identifier']) ?? '',
      title: _stringValue(json['title']) ?? 'Untitled audio',
      creator: _stringValue(json['creator']) ?? '',
      mediatype: _stringValue(json['mediatype']) ?? 'audio',
      format: _stringValue(json['format']) ?? '',
      source: _stringValue(json['source']) ?? 'Audio API',
      files: filesJson
          .map((file) => AudioFileItem.fromJson(file as Map<String, dynamic>))
          .where(
            (file) =>
                file.url.isNotEmpty ||
                (file.assetPath != null && file.assetPath!.isNotEmpty),
          )
          .toList(growable: false),
    );
  }

  static String? _stringValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    return value.toString();
  }
}

class AudioFileItem {
  const AudioFileItem({
    required this.identifier,
    required this.itemTitle,
    required this.fileName,
    required this.format,
    required this.size,
    required this.url,
    required this.source,
    this.cachedFilePath,
    this.assetPath,
  });

  final String identifier;
  final String itemTitle;
  final String fileName;
  final String format;
  final int size;
  final String url;
  final String source;
  final String? cachedFilePath;
  final String? assetPath;

  bool get cached =>
      (cachedFilePath != null && cachedFilePath!.isNotEmpty) ||
      (assetPath != null && assetPath!.isNotEmpty);

  factory AudioFileItem.fromJson(Map<String, dynamic> json) {
    return AudioFileItem(
      identifier: _stringValue(json['identifier']) ?? '',
      itemTitle:
          _stringValue(json['itemTitle']) ??
          _stringValue(json['title']) ??
          'Untitled audio',
      fileName:
          _stringValue(json['fileName']) ??
          _stringValue(json['name']) ??
          'audio',
      format: _stringValue(json['format']) ?? 'audio',
      size: _intValue(json['size']),
      url: _stringValue(json['url']) ?? _stringValue(json['audioUrl']) ?? '',
      source: _stringValue(json['source']) ?? 'Audio API',
      cachedFilePath: _stringValue(json['cachedFilePath']),
      assetPath: _stringValue(json['assetPath']),
    );
  }

  AudioFileItem copyWith({String? cachedFilePath}) {
    return AudioFileItem(
      identifier: identifier,
      itemTitle: itemTitle,
      fileName: fileName,
      format: format,
      size: size,
      url: url,
      source: source,
      cachedFilePath: cachedFilePath ?? this.cachedFilePath,
      assetPath: assetPath,
    );
  }

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(_stringValue(value) ?? '') ?? 0;
  }

  static String? _stringValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    return value.toString();
  }
}
