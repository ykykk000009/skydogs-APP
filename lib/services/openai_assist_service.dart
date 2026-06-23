import 'dart:convert';

import 'package:dio/dio.dart';

import '../data/models/mvp_models.dart';

abstract class AiAssistService {
  String get providerLabel;

  bool get isConfigured;

  Future<AiAssistResult?> generate({
    required String emergencyMessage,
    required List<RelationshipEvent> relationshipEvents,
    required NightEmergencyState state,
  });

  Future<String?> chat({
    required String userMessage,
    required String currentSummary,
    required List<RelationshipEvent> relationshipEvents,
    required NightEmergencyState state,
    List<Map<String, String>> chatHistory = const <Map<String, String>>[],
  });
}

class DisabledAiAssistService implements AiAssistService {
  const DisabledAiAssistService();

  @override
  String get providerLabel => '本地占位 AI';

  @override
  bool get isConfigured => false;

  @override
  Future<AiAssistResult?> generate({
    required String emergencyMessage,
    required List<RelationshipEvent> relationshipEvents,
    required NightEmergencyState state,
  }) async {
    return null;
  }

  @override
  Future<String?> chat({
    required String userMessage,
    required String currentSummary,
    required List<RelationshipEvent> relationshipEvents,
    required NightEmergencyState state,
    List<Map<String, String>> chatHistory = const <Map<String, String>>[],
  }) async {
    return null;
  }
}

class BackendAiAssistService implements AiAssistService {
  BackendAiAssistService({required Dio dio, required String backendBaseUrl})
    : _dio = dio,
      _backendBaseUrl = backendBaseUrl.trim().replaceFirst(RegExp(r'/$'), ''),
      _backendBaseUrls = _buildBackendBaseUrls(backendBaseUrl);

  final Dio _dio;
  final String _backendBaseUrl;
  final List<String> _backendBaseUrls;

  String get backendBaseUrl => _backendBaseUrl;

  @override
  String get providerLabel => 'SkyDogs 后端 AI';

  @override
  bool get isConfigured => _backendBaseUrl.isNotEmpty;

  @override
  Future<AiAssistResult?> generate({
    required String emergencyMessage,
    required List<RelationshipEvent> relationshipEvents,
    required NightEmergencyState state,
  }) async {
    final response = await _postBackendJson('/api/ai/assist', <String, Object?>{
      'state': state.name,
      'stateLabel': state.label,
      'emergencyMessage': emergencyMessage,
      'relationshipEvents': relationshipEvents
          .take(20)
          .map(
            (event) => <String, Object?>{
              'eventType': event.eventType.label,
              'emotion': event.emotion.label,
              'factOrFantasy': event.factOrFantasy.label,
              'content': event.content,
              'timestamp': event.timestamp.toIso8601String(),
            },
          )
          .toList(growable: false),
    });
    final data = response.data ?? const <String, dynamic>{};
    return AiAssistResult(
      noSendLetter: data['noSendLetter'] as String? ?? '',
      miniSummary: data['miniSummary'] as String? ?? '',
      recommendedSceneIds:
          (data['recommendedSceneIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(growable: false),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<String?> chat({
    required String userMessage,
    required String currentSummary,
    required List<RelationshipEvent> relationshipEvents,
    required NightEmergencyState state,
    List<Map<String, String>> chatHistory = const <Map<String, String>>[],
  }) async {
    final response = await _postBackendJson('/api/chat', <String, Object?>{
      'state': state.name,
      'stateLabel': state.label,
      'userMessage': userMessage,
      'currentSummary': currentSummary,
      'chatHistory': chatHistory,
      'relationshipEvents': relationshipEvents
          .take(20)
          .map(
            (event) => <String, Object?>{
              'eventType': event.eventType.label,
              'emotion': event.emotion.label,
              'factOrFantasy': event.factOrFantasy.label,
              'content': event.content,
              'timestamp': event.timestamp.toIso8601String(),
            },
          )
          .toList(growable: false),
    });
    return response.data?['reply'] as String?;
  }

  Future<Response<Map<String, dynamic>>> _postBackendJson(
    String path,
    Map<String, Object?> data,
  ) async {
    Object? lastError;
    StackTrace? lastStackTrace;
    for (final baseUrl in _backendBaseUrls) {
      try {
        return await _dio.post<Map<String, dynamic>>(
          '$baseUrl$path',
          data: data,
          options: Options(
            receiveTimeout: path == '/api/chat'
                ? const Duration(seconds: 45) //更改时间段，数据过多/经常报后端ai不可用 则设置长一些
                : const Duration(seconds: 18),
            sendTimeout: const Duration(seconds: 15),
            headers: const <String, String>{
              // Some mobile networks reset reused TLS sockets. A fresh
              // connection is slower but much more predictable for chat.
              'Connection': 'close',
            },
          ),
        );
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        if (!_canRetryWithNextBackendUrl(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }
      }
    }
    Error.throwWithStackTrace(
      BackendConnectionException(_backendBaseUrls, lastError),
      lastStackTrace ?? StackTrace.current,
    );
  }

  bool _canRetryWithNextBackendUrl(Object error) {
    if (error is! DioException) {
      return false;
    }
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.unknown => true,
      DioExceptionType.badResponse => (error.response?.statusCode ?? 0) >= 500,
      DioExceptionType.badCertificate || DioExceptionType.cancel => false,
    };
  }
}

class BackendConnectionException implements Exception {
  const BackendConnectionException(this.triedBaseUrls, this.cause);

  final List<String> triedBaseUrls;
  final Object? cause;

  @override
  String toString() {
    return 'BackendConnectionException: tried ${triedBaseUrls.join(', ')}; '
        'last error: $cause';
  }
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

class OpenAiAssistService implements AiAssistService {
  OpenAiAssistService({
    required Dio dio,
    required String apiKey,
    required String model,
  }) : _dio = dio,
       _apiKey = apiKey,
       _model = model;

  final Dio _dio;
  final String _apiKey;
  final String _model;

  @override
  String get providerLabel => 'OpenAI $_model';

  @override
  bool get isConfigured => _apiKey.trim().isNotEmpty;

  @override
  Future<AiAssistResult?> generate({
    required String emergencyMessage,
    required List<RelationshipEvent> relationshipEvents,
    required NightEmergencyState state,
  }) async {
    if (!isConfigured) {
      return null;
    }

    final eventSummary = relationshipEvents
        .take(12)
        .map((event) {
          return '- ${event.eventType.label}/${event.emotion.label}/${event.factOrFantasy.label}: ${event.content}';
        })
        .join('\n');

    final response = await _dio.post<Map<String, dynamic>>(
      'https://api.openai.com/v1/responses',
      options: Options(
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: <String, dynamic>{
        'model': _model,
        'input': <Map<String, dynamic>>[
          <String, dynamic>{
            'role': 'system',
            'content':
                '你是 SkyDogs 的夜间情绪陪伴助手。必须紧扣用户选择的当前状态，给出温柔、克制、非医疗诊断的中文回应。不要自称 AI，不要解释模型能力，不要输出“无法/不可用/抱歉”等技术失败话术。输出必须是 JSON，包含 noSendLetter、miniSummary、recommendedSceneIds 三个字段。recommendedSceneIds 只能从 rain_loop、ocean_drift、brown_noise、breath_reset、body_scan 中选择。',
          },
          <String, dynamic>{
            'role': 'user',
            'content':
                '当前状态：${state.label}\n用户此刻的话：$emergencyMessage\n关系时间线：\n$eventSummary',
          },
        ],
        'text': <String, dynamic>{
          'format': <String, dynamic>{
            'type': 'json_schema',
            'name': 'skydogs_ai_assist',
            'strict': true,
            'schema': <String, dynamic>{
              'type': 'object',
              'additionalProperties': false,
              'properties': <String, dynamic>{
                'noSendLetter': <String, dynamic>{'type': 'string'},
                'miniSummary': <String, dynamic>{'type': 'string'},
                'recommendedSceneIds': <String, dynamic>{
                  'type': 'array',
                  'items': <String, dynamic>{
                    'type': 'string',
                    'enum': <String>[
                      'rain_loop',
                      'ocean_drift',
                      'brown_noise',
                      'breath_reset',
                      'body_scan',
                    ],
                  },
                  'minItems': 1,
                  'maxItems': 3,
                },
              },
              'required': <String>[
                'noSendLetter',
                'miniSummary',
                'recommendedSceneIds',
              ],
            },
          },
        },
      },
    );

    final outputText = _extractOutputText(response.data);
    if (outputText == null || outputText.trim().isEmpty) {
      return null;
    }

    final decoded = responseDecoder(outputText);
    return AiAssistResult(
      noSendLetter: decoded['noSendLetter'] as String? ?? '',
      miniSummary: decoded['miniSummary'] as String? ?? '',
      recommendedSceneIds:
          (decoded['recommendedSceneIds'] as List<dynamic>? ??
                  const <dynamic>[])
              .map((item) => item as String)
              .toList(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<String?> chat({
    required String userMessage,
    required String currentSummary,
    required List<RelationshipEvent> relationshipEvents,
    required NightEmergencyState state,
    List<Map<String, String>> chatHistory = const <Map<String, String>>[],
  }) async {
    if (!isConfigured) {
      return null;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      'https://api.openai.com/v1/responses',
      options: Options(
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: <String, dynamic>{
        'model': _model,
        'input': <Map<String, dynamic>>[
          <String, dynamic>{
            'role': 'system',
            'content':
                '你是 SkyDogs 的夜间情绪陪伴助手。只提供情绪支持、陪伴、反思问题和安全建议，不做医疗诊断。必须紧扣用户刚说的话和当前状态，用简洁温柔的中文回答。不要自称 AI，不要解释模型能力。',
          },
          <String, dynamic>{
            'role': 'user',
            'content':
                '当前状态：${state.label}\n当前小结：$currentSummary\n用户继续说：$userMessage',
          },
        ],
      },
    );
    return _extractOutputText(response.data);
  }

  Map<String, dynamic> responseDecoder(String raw) {
    return Map<String, dynamic>.from(
      const JsonDecoder().convert(raw) as Map<String, dynamic>,
    );
  }

  String? _extractOutputText(Map<String, dynamic>? data) {
    final direct = data?['output_text'] as String?;
    if (direct != null) {
      return direct;
    }

    final output = data?['output'] as List<dynamic>?;
    if (output == null) {
      return null;
    }
    for (final item in output) {
      final content =
          (item as Map<String, dynamic>)['content'] as List<dynamic>?;
      if (content == null) {
        continue;
      }
      for (final contentItem in content) {
        final mapped = contentItem as Map<String, dynamic>;
        final text = mapped['text'] as String?;
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }
    }
    return null;
  }
}
