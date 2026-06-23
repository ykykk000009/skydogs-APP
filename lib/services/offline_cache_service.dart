import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/media_track.dart';

class OfflineCacheService {
  OfflineCacheService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<bool> isReady(MediaTrack track) async {
    if (track.builtIn) {
      return true;
    }

    final path = track.cachedFilePath;
    if (path == null || path.isEmpty) {
      return false;
    }

    return File(path).exists();
  }

  Future<String?> cacheTrack(MediaTrack track) async {
    if (track.builtIn) {
      return track.assetPath;
    }
    if (track.remoteUrl == null || track.remoteUrl!.isEmpty) {
      return null;
    }

    final appDirectory = await getApplicationDocumentsDirectory();
    final cacheDirectory = Directory('${appDirectory.path}/audio_cache');
    await cacheDirectory.create(recursive: true);

    final extension = _resolveExtension(track.remoteUrl!);
    final file = File('${cacheDirectory.path}/${track.id}.$extension');
    if (await file.exists()) {
      return file.path;
    }

    final response = await _dio.get<List<int>>(
      track.remoteUrl!,
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _resolveExtension(String url) {
    final uri = Uri.tryParse(url);
    final lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : url;
    final dotIndex = lastSegment.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == lastSegment.length - 1) {
      return 'mp3';
    }
    return lastSegment.substring(dotIndex + 1);
  }
}
