import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models/app_snapshot.dart';
import '../data/models/media_track.dart';
import '../data/models/mvp_models.dart';
import '../data/models/sleep_schedule.dart';
import '../data/models/sleep_session.dart';
import '../data/models/user_profile.dart';
import '../repositories/local_snapshot_repository.dart';
import '../services/analytics_service.dart';
import '../services/archive_audio_service.dart';
import '../services/audio_playback_service.dart';
import '../services/offline_cache_service.dart';
import '../services/openai_assist_service.dart';
import '../services/reminder_service.dart';
import '../services/sleep_tracking_service.dart';
import '../services/tts_service.dart';

class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  bool get fromUser => role == 'user';
}

enum PlaylistPlaybackMode { sequence, repeat, shuffle }

extension PlaylistPlaybackModeLabel on PlaylistPlaybackMode {
  String get label {
    return switch (this) {
      PlaylistPlaybackMode.sequence => '顺序',
      PlaylistPlaybackMode.repeat => '循环',
      PlaylistPlaybackMode.shuffle => '随机',
    };
  }
}

class SleepAppController extends ChangeNotifier {
  SleepAppController({
    required LocalSnapshotRepository repository,
    required AudioPlaybackService audioPlaybackService,
    required ArchiveAudioService archiveAudioService,
    required OfflineCacheService offlineCacheService,
    required ReminderService reminderService,
    required SleepTrackingService sleepTrackingService,
    required AiAssistService aiAssistService,
    required MeditationTtsService ttsService,
    required AnalyticsService analyticsService,
  }) : _repository = repository,
       _audioPlaybackService = audioPlaybackService,
       _archiveAudioService = archiveAudioService,
       _offlineCacheService = offlineCacheService,
       _reminderService = reminderService,
       _sleepTrackingService = sleepTrackingService,
       _aiAssistService = aiAssistService,
       _ttsService = ttsService,
       _analyticsService = analyticsService {
    _playingSubscription = _audioPlaybackService.playingStream.listen((
      isPlaying,
    ) {
      _isPlaying = isPlaying;
      notifyListeners();
    });

    _positionSubscription = _audioPlaybackService.positionStream.listen((
      position,
    ) {
      _position = position;
      notifyListeners();
    });

    _durationSubscription = _audioPlaybackService.durationStream.listen((
      duration,
    ) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    _completedSubscription = _audioPlaybackService.completedStream.listen((_) {
      unawaited(_playNextFromQueue());
    });
  }

  final LocalSnapshotRepository _repository;
  final AudioPlaybackService _audioPlaybackService;
  final ArchiveAudioService _archiveAudioService;
  final OfflineCacheService _offlineCacheService;
  final ReminderService _reminderService;
  final SleepTrackingService _sleepTrackingService;
  final AiAssistService _aiAssistService;
  final MeditationTtsService _ttsService;
  final AnalyticsService _analyticsService;

  late AppSnapshot _snapshot;
  bool _initialized = false;
  bool _busy = false;
  bool _searchingOnlineAudio = false;
  bool _isPlaying = false;
  String? _statusMessage;
  String _onlineAudioQuery = 'rain sleep';
  int _onlineAudioPage = 1;
  List<SearchResultItem> _onlineSearchResults = const <SearchResultItem>[];
  SearchResultItem? _selectedSearchResult;
  List<AudioFileItem> _selectedAudioFiles = const <AudioFileItem>[];
  List<AiChatMessage> _aiChatMessages = const <AiChatMessage>[];
  String? _emotionTrendAnalysis;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlaylistPlaybackMode _playlistPlaybackMode = PlaylistPlaybackMode.sequence;
  Timer? _sleepTimer;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<void>? _completedSubscription;

  bool get initialized => _initialized;

  bool get isBusy => _busy;

  bool get searchingOnlineAudio => _searchingOnlineAudio;

  bool get isPlaying => _isPlaying;

  String? get statusMessage => _statusMessage;

  String get onlineAudioQuery => _onlineAudioQuery;

  int get onlineAudioPage => _onlineAudioPage;

  List<SearchResultItem> get onlineSearchResults => _onlineSearchResults;

  SearchResultItem? get selectedSearchResult => _selectedSearchResult;

  List<AudioFileItem> get selectedAudioFiles => _selectedAudioFiles;

  List<AiChatMessage> get aiChatMessages => _aiChatMessages;

  String? get emotionTrendAnalysis => _emotionTrendAnalysis;

  Map<NightEmergencyState, int> get emergencyStateCounts {
    final counts = <NightEmergencyState, int>{
      for (final state in NightEmergencyState.values) state: 0,
    };
    for (final log in _snapshot.emergencyLogs) {
      counts[log.state] = (counts[log.state] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, String> get presetAudioQueries => const <String, String>{
    '屋檐雨声': 'rain on roof sound effect',
    '海浪漂浮': 'ocean waves ambient',
    '林间夜色': 'night forest ambience',
    '深棕噪声': 'brown noise sleep',
  };

  static const List<String> _cloudSoundMaterialIds = <String>[
    'rain_loop',
    'ocean_drift',
    'forest_night',
    'brown_noise',
  ];

  Duration get position => _position;

  Duration get duration => _duration;

  PlaylistPlaybackMode get playlistPlaybackMode => _playlistPlaybackMode;

  SleepSchedule get schedule => _snapshot.schedule;

  List<MediaTrack> get tracks => _snapshot.tracks;

  List<MediaTrack> get soundscapes => tracks
      .where((track) => track.kind == TrackKind.soundscape)
      .toList(growable: false);

  List<MediaTrack> get meditations => tracks
      .where((track) => track.kind == TrackKind.meditation)
      .toList(growable: false);

  List<MediaTrack> get cloudSoundMaterials => _cloudSoundMaterialIds
      .map(_trackByIdOrNull)
      .whereType<MediaTrack>()
      .toList(growable: false);

  List<MediaTrack> get playbackQueue => _snapshot.playlistTrackIds
      .map(_trackByIdOrNull)
      .whereType<MediaTrack>()
      .toList(growable: false);

  List<SleepSession> get sessions =>
      _snapshot.sessions.reversed.toList(growable: false);

  UserProfile get profile => _snapshot.profile;

  UserAccount get account => _snapshot.account;

  List<NightEmergencyLog> get emergencyLogs =>
      _snapshot.emergencyLogs.reversed.toList(growable: false);

  List<PersonalScene> get personalScenes => _snapshot.personalScenes;

  List<RelationshipEvent> get relationshipEvents =>
      _snapshot.relationshipEvents.reversed.toList(growable: false);

  List<SleepRitualLog> get ritualLogs =>
      _snapshot.ritualLogs.reversed.toList(growable: false);

  AiAssistResult get aiAssist => _snapshot.aiAssist;

  NightEmergencyLog? get latestEmergency =>
      emergencyLogs.isEmpty ? null : emergencyLogs.first;

  SleepRitualLog? get latestRitual =>
      ritualLogs.isEmpty ? null : ritualLogs.first;

  double get averageEmotionRating {
    if (_snapshot.ritualLogs.isEmpty) {
      return 0;
    }
    final total = _snapshot.ritualLogs.fold<int>(
      0,
      (sum, log) => sum + log.emotionRating,
    );
    return double.parse(
      (total / _snapshot.ritualLogs.length).toStringAsFixed(1),
    );
  }

  double get recoveryProgress {
    final ratingScore = averageEmotionRating == 0
        ? 0
        : averageEmotionRating / 5;
    final eventScore =
        relationshipEvents
            .where((event) => event.factOrFantasy == FactOrFantasy.fact)
            .length /
        (relationshipEvents.isEmpty ? 1 : relationshipEvents.length);
    final emergencyScore = emergencyLogs.isEmpty
        ? 0.35
        : (1 - (emergencyLogs.length.clamp(0, 8) / 10));
    return ((ratingScore * 0.45 + eventScore * 0.3 + emergencyScore * 0.25) *
            100)
        .clamp(0, 100)
        .toDouble();
  }

  MediaTrack get selectedSoundscape {
    return soundscapes.firstWhere(
      (track) => track.id == profile.selectedTrackId,
      orElse: () => soundscapes.first,
    );
  }

  MediaTrack get selectedMeditation {
    return meditations.firstWhere(
      (track) => track.id == profile.selectedMeditationId,
      orElse: () => meditations.first,
    );
  }

  SleepSession? get latestSession => sessions.isEmpty ? null : sessions.first;

  double get averageRestfulness {
    if (sessions.isEmpty) {
      return 0;
    }
    final total = sessions.fold<double>(
      0,
      (sum, session) => sum + session.restfulnessScore,
    );
    return double.parse((total / sessions.length).toStringAsFixed(1));
  }

  String get ttsProviderLabel => _ttsService.providerLabel;

  String get aiProviderLabel => _aiAssistService.providerLabel;

  String get securitySummary => '你的记录只保存在本机；可以随时开启提醒、管理声音或清空个人内容。';

  NightEmergencyState? get topEmergencyState {
    NightEmergencyState? top;
    var topCount = 0;
    for (final entry in emergencyStateCounts.entries) {
      if (entry.value > topCount) {
        top = entry.key;
        topCount = entry.value;
      }
    }
    return top;
  }

  String get emotionBrief {
    final top = topEmergencyState;
    if (top == null || _snapshot.emergencyLogs.isEmpty) {
      return '还没有足够记录。先在“心声”里点一次当前状态，这里会自动整理你的高频情绪。';
    }
    final count = emergencyStateCounts[top] ?? 0;
    return '最近最常出现的是「${top.label}」$count 次。今晚建议先让身体稳定下来，再决定要不要处理关系问题。';
  }

  String formatStateLogTime(DateTime time) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${time.year}年${twoDigits(time.month)}月${twoDigits(time.day)}日'
        '${twoDigits(time.hour)}时${twoDigits(time.minute)}分';
  }

  List<Map<String, String>> get stateLibraryForAi => _snapshot.emergencyLogs
      .map(
        (log) => <String, String>{
          'state': log.state.label,
          'time': formatStateLogTime(log.createdAt),
        },
      )
      .toList(growable: false);

  List<String> get emotionActionChips {
    final top = topEmergencyState;
    if (top == null) {
      return const <String>['记录一次心声', '播放舒缓声音', '睡前再复盘'];
    }
    return switch (top) {
      NightEmergencyState.wantToContact => const <String>[
        '延后发送',
        '写进日记本',
        '十分钟后再决定',
      ],
      NightEmergencyState.cannotSleep => const <String>[
        '调低屏幕',
        '播放声音',
        '做身体扫描',
      ],
      NightEmergencyState.startThinkingAgain => const <String>[
        '写一个事实',
        '写一个想象',
        '停止追问细节',
      ],
      NightEmergencyState.furious => const <String>['远离聊天框', '慢呼气', '先不回复'],
      NightEmergencyState.wronged => const <String>['承认委屈', '记录边界', '明天再表达'],
      NightEmergencyState.missThem => const <String>['允许想念', '不翻记录', '听一段声音'],
      NightEmergencyState.selfBlame => const <String>[
        '停止审判',
        '找一个事实',
        '对自己温和一点',
      ],
      NightEmergencyState.panic => const <String>['脚踩地面', '喝水', '只处理当下'],
      NightEmergencyState.numb => const <String>['摸到真实物体', '慢慢呼吸', '不用逼自己'],
    };
  }

  bool isActiveTrack(MediaTrack track) =>
      _audioPlaybackService.currentTrackId == track.id;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _snapshot = await _repository.load();
    _initialized = true;

    if (_snapshot.schedule.reminderEnabled) {
      await _reminderService.scheduleBedtimeReminder(_snapshot.schedule);
    }

    if (_aiAssistService is BackendAiAssistService) {
      _statusMessage = '后端地址：${_aiAssistService.backendBaseUrl}';
    }

    notifyListeners();
  }

  Future<void> toggleSelectedSoundscape() async {
    if (isActiveTrack(selectedSoundscape) && _isPlaying) {
      await pausePlayback();
      return;
    }
    await playTrack(selectedSoundscape);
  }

  Future<void> toggleTrack(MediaTrack track) async {
    if (isActiveTrack(track) && _isPlaying) {
      await pausePlayback();
      return;
    }
    await playTrack(track);
  }

  Future<void> playTrack(MediaTrack track) async {
    _busy = true;
    notifyListeners();

    try {
      var playableTrack = track;
      if (_cloudSoundMaterialIds.contains(track.id) &&
          (track.cachedFilePath?.isEmpty ?? true)) {
        _statusMessage = '正在准备《${track.title}》...';
        notifyListeners();
        final filePath = await _offlineCacheService.cacheTrack(track);
        if (filePath == null || filePath.isEmpty) {
          _statusMessage = '播放失败，未能读取云端音频文件。';
          return;
        }
        playableTrack = track.copyWith(cachedFilePath: filePath);
        _replaceTrack(playableTrack);
      }

      if (_snapshot.profile.offlineOnly && !playableTrack.isOfflineReady) {
        _statusMessage = '当前是仅离线模式，请先缓存该音频。';
        return;
      }

      await _audioPlaybackService.play(playableTrack);

      if (playableTrack.kind == TrackKind.soundscape) {
        _snapshot = _snapshot.copyWith(
          profile: _snapshot.profile.copyWith(
            selectedTrackId: playableTrack.id,
          ),
        );
        await _ensureTrackingStarted();
        _armSleepTimer();
      } else {
        _snapshot = _snapshot.copyWith(
          profile: _snapshot.profile.copyWith(
            selectedMeditationId: playableTrack.id,
          ),
        );
      }

      _statusMessage = '正在播放《${playableTrack.title}》。';
      await _analyticsService.logEvent('play_track', <String, Object?>{
        'trackId': playableTrack.id,
        'kind': playableTrack.kind.name,
      });
      await _persist();
    } catch (error, stackTrace) {
      await _analyticsService.logError(error, stackTrace);
      _statusMessage = '播放失败，请检查资源文件或网络配置。';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  MediaTrack? _trackByIdOrNull(String id) {
    for (final track in tracks) {
      if (track.id == id) {
        return track;
      }
    }
    return null;
  }

  Future<void> addTrackToPlaylist(MediaTrack track) async {
    final storedTrack = _ensureTrackStored(track);
    final ids = <String>[
      ..._snapshot.playlistTrackIds.where((id) => id != storedTrack.id),
      storedTrack.id,
    ];
    _snapshot = _snapshot.copyWith(playlistTrackIds: ids);
    _statusMessage = '已加入播放列表：《${storedTrack.title}》。';
    await _persist();
    notifyListeners();
  }

  Future<void> addSearchResultToPlaylist(SearchResultItem item) async {
    if (item.files.isEmpty) {
      _statusMessage = '这条音频没有可添加的播放文件。';
      notifyListeners();
      return;
    }
    await addTrackToPlaylist(trackFromAudioFile(item.files.first));
  }

  Future<void> removeTrackFromPlaylist(MediaTrack track) async {
    _snapshot = _snapshot.copyWith(
      playlistTrackIds: _snapshot.playlistTrackIds
          .where((id) => id != track.id)
          .toList(growable: false),
    );
    _statusMessage = '已从播放列表移除《${track.title}》。';
    await _persist();
    notifyListeners();
  }

  Future<void> clearPlaylist() async {
    _snapshot = _snapshot.copyWith(playlistTrackIds: const <String>[]);
    _statusMessage = '播放列表已清空。';
    await _persist();
    notifyListeners();
  }

  void setPlaylistPlaybackMode(PlaylistPlaybackMode mode) {
    _playlistPlaybackMode = mode;
    _statusMessage = '播放列表已切换为${mode.label}播放。';
    notifyListeners();
  }

  Future<void> playQueueFrom(MediaTrack track) async {
    if (!playbackQueue.any((item) => item.id == track.id)) {
      await addTrackToPlaylist(track);
    }
    await playTrack(track.copyWith(loop: false));
  }

  Future<void> _playNextFromQueue() async {
    final queue = playbackQueue;
    if (queue.isEmpty) {
      return;
    }
    final currentId = _audioPlaybackService.currentTrackId;
    final currentIndex = queue.indexWhere((track) => track.id == currentId);
    if (currentIndex == -1) {
      return;
    }

    final nextTrack = _nextQueueTrack(queue, currentIndex);

    if (nextTrack == null) {
      _statusMessage = '播放列表已播完。';
      notifyListeners();
      return;
    }
    await playTrack(nextTrack.copyWith(loop: false));
  }

  MediaTrack? _nextQueueTrack(List<MediaTrack> queue, int currentIndex) {
    return switch (_playlistPlaybackMode) {
      PlaylistPlaybackMode.sequence =>
        currentIndex + 1 < queue.length ? queue[currentIndex + 1] : null,
      PlaylistPlaybackMode.repeat => queue[(currentIndex + 1) % queue.length],
      PlaylistPlaybackMode.shuffle => _randomQueueTrack(queue, currentIndex),
    };
  }

  MediaTrack _randomQueueTrack(List<MediaTrack> queue, int currentIndex) {
    if (queue.length == 1) {
      return queue.first;
    }
    final seed = DateTime.now().microsecondsSinceEpoch;
    final randomIndexBase = seed % (queue.length - 1);
    final randomIndex = randomIndexBase >= currentIndex
        ? randomIndexBase + 1
        : randomIndexBase;
    return queue[randomIndex];
  }

  Future<void> searchOnlineAudio(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _statusMessage = '请输入想搜索的声音关键词。';
      notifyListeners();
      return;
    }

    _onlineAudioQuery = trimmed;
    _onlineAudioPage = 1;
    _searchingOnlineAudio = true;
    _statusMessage = '正在搜索 Internet Archive 免费音频...';
    notifyListeners();

    try {
      _onlineSearchResults = _withoutCloudSoundMaterials(
        await _archiveAudioService.search(
          keyword: trimmed,
          page: _onlineAudioPage,
        ),
      );
      if (_onlineSearchResults.isEmpty) {
        _onlineSearchResults = _fallbackAudioResults(trimmed);
      }
      _selectedSearchResult = null;
      _selectedAudioFiles = const <AudioFileItem>[];
      _statusMessage = _onlineSearchResults.isEmpty
          ? '没有搜到音频条目，试试 rain、ocean、sleep、ambient。'
          : '找到 ${_onlineSearchResults.length} 条音频条目。';
    } catch (error, stackTrace) {
      await _analyticsService.logError(error, stackTrace);
      _onlineSearchResults = _fallbackAudioResults(trimmed);
      _selectedSearchResult = null;
      _selectedAudioFiles = const <AudioFileItem>[];
      _statusMessage = _onlineSearchResults.isEmpty
          ? '暂时没找到合适的声音，换个关键词试试。'
          : '已找到 ${_onlineSearchResults.length} 条声音。';
    } finally {
      _searchingOnlineAudio = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreOnlineAudio() async {
    if (_onlineAudioQuery.trim().isEmpty || _searchingOnlineAudio) {
      return;
    }
    _searchingOnlineAudio = true;
    notifyListeners();
    try {
      final nextPage = _onlineAudioPage + 1;
      final more = _withoutCloudSoundMaterials(
        await _archiveAudioService.search(
          keyword: _onlineAudioQuery,
          page: nextPage,
        ),
      );
      _onlineAudioPage = nextPage;
      _onlineSearchResults = <SearchResultItem>[
        ..._onlineSearchResults,
        ...more,
      ];
      _statusMessage = more.isEmpty ? '没有更多结果了。' : '已加载第 $nextPage 页。';
    } catch (error, stackTrace) {
      await _analyticsService.logError(error, stackTrace);
      _statusMessage = '加载更多失败：${error.runtimeType}。';
    } finally {
      _searchingOnlineAudio = false;
      notifyListeners();
    }
  }

  Future<void> selectOnlineSearchResult(SearchResultItem item) async {
    _selectedSearchResult = item;
    _selectedAudioFiles = const <AudioFileItem>[];
    _searchingOnlineAudio = true;
    _statusMessage = '正在读取《${item.title}》的音频文件列表...';
    notifyListeners();

    try {
      _selectedAudioFiles = await _archiveAudioService.filesFor(item);
      _statusMessage = _selectedAudioFiles.isEmpty
          ? '这个条目没有可播放的音频文件。'
          : '找到 ${_selectedAudioFiles.length} 个音频文件。';
    } catch (error, stackTrace) {
      await _analyticsService.logError(error, stackTrace);
      _statusMessage = '读取文件列表失败：${error.runtimeType}。';
    } finally {
      _searchingOnlineAudio = false;
      notifyListeners();
    }
  }

  MediaTrack trackFromAudioFile(AudioFileItem file) {
    return MediaTrack(
      id: _audioFileTrackId(file),
      title: file.itemTitle,
      subtitle: file.fileName,
      kind: TrackKind.soundscape,
      category: file.source,
      accentColor: 0xFF6AB4A7,
      assetPath: file.assetPath,
      remoteUrl: file.url,
      cachedFilePath: file.cachedFilePath,
      builtIn: false,
      loop: true,
    );
  }

  Future<void> playOnlineAudioFile(AudioFileItem file) async {
    await playTrack(trackFromAudioFile(file));
  }

  Future<void> cacheOnlineAudioFile(AudioFileItem file) async {
    final track = trackFromAudioFile(file);
    _busy = true;
    notifyListeners();

    try {
      if (file.assetPath?.isNotEmpty ?? false) {
        await addOnlineTrackToLibrary(track.copyWith(builtIn: true));
        return;
      }
      final filePath =
          file.cachedFilePath ?? await _offlineCacheService.cacheTrack(track);
      if (filePath == null) {
        _statusMessage = '当前音频没有可缓存的远端地址。';
        return;
      }

      final cachedFile = file.copyWith(cachedFilePath: filePath);
      _selectedAudioFiles = _selectedAudioFiles
          .map(
            (item) =>
                item.identifier == file.identifier &&
                    item.fileName == file.fileName
                ? cachedFile
                : item,
          )
          .toList(growable: false);

      final cachedTrack = trackFromAudioFile(cachedFile);
      if (_snapshot.tracks.any((item) => item.id == cachedTrack.id)) {
        _replaceTrack(cachedTrack);
      } else {
        _snapshot = _snapshot.copyWith(
          tracks: <MediaTrack>[..._snapshot.tracks, cachedTrack],
          profile: _snapshot.profile.copyWith(selectedTrackId: cachedTrack.id),
        );
      }

      _statusMessage = '《${cachedTrack.title}》已下载到本地声音库。';
      await _persist();
    } catch (error, stackTrace) {
      await _analyticsService.logError(error, stackTrace);
      _statusMessage = '下载音频失败，请检查网络和存储空间。';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> addOnlineTrackToLibrary(MediaTrack track) async {
    if (_snapshot.tracks.any((item) => item.id == track.id)) {
      await selectSoundscape(track);
      _statusMessage = '已选择《${track.title}》。';
      notifyListeners();
      return;
    }

    _snapshot = _snapshot.copyWith(
      tracks: <MediaTrack>[..._snapshot.tracks, track],
      profile: _snapshot.profile.copyWith(selectedTrackId: track.id),
    );
    _statusMessage = '已添加《${track.title}》到声音列表。';
    await _persist();
    notifyListeners();
  }

  MediaTrack _ensureTrackStored(MediaTrack track) {
    if (_snapshot.tracks.any((item) => item.id == track.id)) {
      return track;
    }
    _snapshot = _snapshot.copyWith(
      tracks: <MediaTrack>[..._snapshot.tracks, track],
    );
    return track;
  }

  Future<void> importPresetAudio(String presetName) async {
    final query = presetAudioQueries[presetName] ?? presetName;
    await searchOnlineAudio(query);
    if (_onlineSearchResults.isEmpty) {
      return;
    }
    await selectOnlineSearchResult(_onlineSearchResults.first);
    if (_selectedAudioFiles.isEmpty) {
      return;
    }
    final firstTrack = trackFromAudioFile(_selectedAudioFiles.first);
    final first = firstTrack.copyWith(
      id: 'preset_${presetName.hashCode.abs()}_${firstTrack.id}',
      title: presetName,
      subtitle: '在线素材 · ${firstTrack.title}',
      category: '预设在线音频',
      loop: true,
    );
    await addOnlineTrackToLibrary(first);
  }

  List<SearchResultItem> _fallbackAudioResults(String query) {
    return const <SearchResultItem>[];
  }

  List<SearchResultItem> _withoutCloudSoundMaterials(
    List<SearchResultItem> items,
  ) {
    return items
        .where((item) {
          final normalized = item.identifier.replaceFirst('local:', '');
          return !_cloudSoundMaterialIds.contains(normalized);
        })
        .toList(growable: false);
  }

  Future<void> pausePlayback() async {
    await _audioPlaybackService.pause();
    await _finishCurrentSleepSession('manual_pause');
    _cancelSleepTimer();
    _statusMessage = '已暂停播放。';
    notifyListeners();
  }

  Future<void> stopPlayback() async {
    await _audioPlaybackService.stop();
    await _finishCurrentSleepSession('manual_stop');
    _cancelSleepTimer();
    _statusMessage = '播放已停止。';
    notifyListeners();
  }

  Future<void> selectSoundscape(MediaTrack track) async {
    _snapshot = _snapshot.copyWith(
      profile: _snapshot.profile.copyWith(selectedTrackId: track.id),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> selectMeditation(MediaTrack track) async {
    _snapshot = _snapshot.copyWith(
      profile: _snapshot.profile.copyWith(selectedMeditationId: track.id),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> setTimerMinutes(int minutes) async {
    _snapshot = _snapshot.copyWith(
      schedule: _snapshot.schedule.copyWith(timerMinutes: minutes),
    );
    if (_isPlaying) {
      _armSleepTimer();
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setBedtime(TimeOfDay time) async {
    _snapshot = _snapshot.copyWith(
      schedule: _snapshot.schedule.copyWith(
        bedtimeHour: time.hour,
        bedtimeMinute: time.minute,
      ),
    );
    if (_snapshot.schedule.reminderEnabled) {
      await _reminderService.scheduleBedtimeReminder(_snapshot.schedule);
    }
    _statusMessage = '睡前提醒时间已更新为 ${_snapshot.schedule.bedtimeLabel}。';
    await _persist();
    notifyListeners();
  }

  Future<void> setReminderEnabled(bool enabled) async {
    if (enabled) {
      final granted = await _reminderService.requestPermissionIfNeeded();
      if (!granted) {
        _statusMessage = '通知权限未开启，无法创建睡前提醒。';
        notifyListeners();
        return;
      }
    }

    _snapshot = _snapshot.copyWith(
      schedule: _snapshot.schedule.copyWith(reminderEnabled: enabled),
    );

    if (enabled) {
      await _reminderService.scheduleBedtimeReminder(_snapshot.schedule);
      _statusMessage = '已开启每日睡前提醒。';
    } else {
      await _reminderService.cancelBedtimeReminder();
      _statusMessage = '睡前提醒已关闭。';
    }

    await _persist();
    notifyListeners();
  }

  Future<void> setOfflineOnly(bool enabled) async {
    _snapshot = _snapshot.copyWith(
      profile: _snapshot.profile.copyWith(offlineOnly: enabled),
    );
    _statusMessage = enabled ? '已切换为仅离线模式。' : '已允许播放在线音频资源。';
    await _persist();
    notifyListeners();
  }

  Future<void> setMotionConsent(bool enabled) async {
    _snapshot = _snapshot.copyWith(
      profile: _snapshot.profile.copyWith(motionConsentAccepted: enabled),
    );
    _statusMessage = enabled ? '已同意使用加速度计做轻量睡眠追踪。' : '已关闭传感器追踪。';
    await _persist();
    notifyListeners();
  }

  Future<void> importHealthData() async {
    final imported = await _sleepTrackingService.importFromHealthSdk();
    if (imported.isEmpty) {
      _statusMessage = '健康 SDK 接口已预留，当前还没有实际导入数据。';
      notifyListeners();
      return;
    }

    final updatedSessions = <SleepSession>[..._snapshot.sessions, ...imported]
      ..sort((left, right) => left.startedAt.compareTo(right.startedAt));

    _snapshot = _snapshot.copyWith(sessions: updatedSessions);
    _statusMessage = '已导入 ${imported.length} 条健康睡眠记录。';
    await _persist();
    notifyListeners();
  }

  Future<void> cacheTrack(MediaTrack track) async {
    if (track.builtIn) {
      _statusMessage = '《${track.title}》已经是内置离线资源。';
      notifyListeners();
      return;
    }

    _busy = true;
    notifyListeners();

    try {
      final filePath = await _offlineCacheService.cacheTrack(track);
      if (filePath == null) {
        _statusMessage = '当前音频没有可缓存的远端地址。';
        return;
      }

      _replaceTrack(track.copyWith(cachedFilePath: filePath));
      _statusMessage = '《${track.title}》已缓存到本地。';
      await _persist();
    } catch (error, stackTrace) {
      await _analyticsService.logError(error, stackTrace);
      _statusMessage = '缓存失败，请检查网络和存储空间。';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> generateMeditationTrack({
    required String title,
    required String script,
  }) async {
    _busy = true;
    notifyListeners();

    try {
      final track = await _ttsService.generateTrack(
        title: title,
        script: script,
        accentColor: 0xFF8BAA75,
      );
      if (track == null) {
        _statusMessage = '当前未配置 TTS 接口，先使用内置冥想音频即可。';
        return;
      }

      _snapshot = _snapshot.copyWith(
        tracks: <MediaTrack>[..._snapshot.tracks, track],
      );
      _statusMessage = '已生成新的冥想语音，可继续缓存离线。';
      await _persist();
    } catch (error, stackTrace) {
      await _analyticsService.logError(error, stackTrace);
      _statusMessage = 'TTS 生成失败，请检查后端代理与供应商配置。';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> setEmotionStage(EmotionStage stage) async {
    _snapshot = _snapshot.copyWith(
      account: _snapshot.account.copyWith(emotionStage: stage),
    );
    _statusMessage = '情绪阶段已切换为 ${stage.label}。';
    await _persist();
    notifyListeners();
  }

  Future<void> updateAccountProfile({
    String? nickname,
    String? avatarPath,
    String? signature,
    String? phone,
    String? email,
    bool clearPhone = false,
    bool clearEmail = false,
  }) async {
    _snapshot = _snapshot.copyWith(
      account: _snapshot.account.copyWith(
        nickname: nickname,
        avatarPath: avatarPath,
        signature: signature,
        phone: clearPhone ? '' : phone,
        email: clearEmail ? '' : email,
      ),
    );
    _statusMessage = '个人资料已更新。';
    await _persist();
    notifyListeners();
  }

  Future<void> setAccessControlEnabled(bool enabled) async {
    _snapshot = _snapshot.copyWith(
      profile: _snapshot.profile.copyWith(accessControlEnabled: enabled),
    );
    _statusMessage = enabled ? '已启用进入 App 前的访问控制预留。' : '已关闭访问控制预留。';
    await _persist();
    notifyListeners();
  }

  Future<void> runNightEmergency(NightEmergencyState state) async {
    final now = DateTime.now();
    final message = _defaultEmergencyMessage(state);
    final log = NightEmergencyLog(
      id: 'emergency_${now.microsecondsSinceEpoch}',
      state: state,
      createdAt: now,
      userMessage: message,
      actions: state.actions,
      aiLetter: state == NightEmergencyState.wantToContact
          ? _generateNoSendLetter(message)
          : null,
      miniSummary: '已记录“${state.label}”。先把状态保存下来，不急着马上做决定。',
    );

    _snapshot = _snapshot.copyWith(
      emergencyLogs: <NightEmergencyLog>[..._snapshot.emergencyLogs, log],
    );

    await _analyticsService.logEvent('night_emergency', <String, Object?>{
      'state': state.name,
      'recordedAt': formatStateLogTime(now),
    });
    await _persist();
    _statusMessage = '${state.label}已保存。';
    notifyListeners();
    unawaited(_completeNightEmergencyAi(log.id, message, state));
  }

  Future<void> _completeNightEmergencyAi(
    String logId,
    String message,
    NightEmergencyState state,
  ) async {
    final ai = await _buildAiAssist(message: message, state: state);
    final updatedLogs = _snapshot.emergencyLogs
        .map(
          (log) => log.id == logId
              ? NightEmergencyLog(
                  id: log.id,
                  state: log.state,
                  createdAt: log.createdAt,
                  userMessage: log.userMessage,
                  actions: log.actions,
                  aiLetter: state == NightEmergencyState.wantToContact
                      ? ai.noSendLetter
                      : log.aiLetter,
                  miniSummary: state == NightEmergencyState.startThinkingAgain
                      ? ai.miniSummary
                      : log.miniSummary,
                )
              : log,
        )
        .toList(growable: false);
    _snapshot = _snapshot.copyWith(emergencyLogs: updatedLogs, aiAssist: ai);
    await _persist();
    notifyListeners();
  }

  Future<void> sendAiChatMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final state = latestEmergency?.state ?? NightEmergencyState.cannotSleep;
    _aiChatMessages = <AiChatMessage>[
      ..._aiChatMessages,
      AiChatMessage(role: 'user', content: trimmed),
    ];
    _busy = true;
    notifyListeners();

    try {
      final reply = await _aiAssistService.chat(
        userMessage: trimmed,
        currentSummary: _snapshot.aiAssist.miniSummary,
        relationshipEvents: _snapshot.relationshipEvents,
        state: state,
        chatHistory: _aiChatMessages
            .take(_aiChatMessages.length - 1)
            .toList(growable: false)
            .reversed
            .take(8)
            .toList(growable: false)
            .reversed
            .map(
              (message) => <String, String>{
                'role': message.role,
                'content': message.content,
              },
            )
            .toList(growable: false),
      );
      _aiChatMessages = <AiChatMessage>[
        ..._aiChatMessages,
        AiChatMessage(
          role: 'assistant',
          content: reply == null || reply.trim().isEmpty
              ? _localAiChatReply(trimmed, state)
              : reply,
        ),
      ];
      _statusMessage = _aiAssistService.isConfigured
          ? 'AI 已回复。'
          : 'AI 已用本地逻辑回复。';
    } catch (error, stackTrace) {
      await _analyticsService.logError(error, stackTrace);
      _aiChatMessages = <AiChatMessage>[
        ..._aiChatMessages,
        AiChatMessage(
          role: 'assistant',
          content: _localAiChatReply(trimmed, state),
        ),
      ];
      _statusMessage = '后端 AI 暂时不可用，已用本地安抚回复。${_networkErrorHint(error)}';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearAiChatMessages() {
    _aiChatMessages = const <AiChatMessage>[];
    _statusMessage = 'AI 对话已清空。';
    notifyListeners();
  }

  Future<void> analyzeEmotionTrend() async {
    _busy = true;
    notifyListeners();

    final stateLibraryText = emergencyLogs
        .map((log) => '${formatStateLogTime(log.createdAt)}：${log.state.label}')
        .join('\n');
    final stateSummary = emergencyStateCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.key.label}: ${entry.value} 次')
        .join('；');
    final timelineSummary = _snapshot.relationshipEvents
        .take(8)
        .map(
          (event) =>
              '${event.eventType.label}/${event.emotion.label}/${event.factOrFantasy.label}: ${event.content}',
        )
        .join('\n');
    final prompt =
        '这是“我的-情绪小结-AI状态分析”。请像心声陪伴对话一样自然、温和、具体地回复。'
        '请只基于下面状态库和时间线做分析，不要要求用户再补充信息。\n'
        '完整状态库：\n${stateLibraryText.isEmpty ? '暂无状态库记录' : stateLibraryText}\n'
        '状态频次：${stateSummary.isEmpty ? '暂无状态记录' : stateSummary}\n'
        '时间线：\n${timelineSummary.isEmpty ? '暂无时间线记录' : timelineSummary}\n'
        '请用 4 段以内输出：状态库总结、情绪走向、核心需求、今晚可做的调整建议。'
        '每段不要太长，不要输出编号 JSON。';

    try {
      final reply = await _aiAssistService.chat(
        userMessage: prompt,
        currentSummary: _snapshot.aiAssist.miniSummary,
        relationshipEvents: _snapshot.relationshipEvents,
        state: latestEmergency?.state ?? NightEmergencyState.cannotSleep,
      );
      _emotionTrendAnalysis = reply == null || reply.trim().isEmpty
          ? _localEmotionTrendAnalysis(stateSummary)
          : reply;
      _statusMessage = 'AI 状态分析已更新。';
    } catch (error, stackTrace) {
      await _analyticsService.logError(error, stackTrace);
      _emotionTrendAnalysis = _localEmotionTrendAnalysis(stateSummary);
      _statusMessage = 'AI 状态分析请求超时，已先生成本地分析。${_networkErrorHint(error)}';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<PersonalScene?> createPersonalScene(
    String sceneName, {
    String? styleKey,
    String? moodLabel,
  }) async {
    final trimmed = sceneName.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final scene = PersonalScene(
      id: 'scene_${DateTime.now().microsecondsSinceEpoch}',
      sceneName: trimmed,
      audioFiles: const <PersonalAudioFile>[],
      textEntries: const <PersonalTextEntry>[],
      images: const <PersonalImageEntry>[],
      playbackOptions: PlaybackOptions.defaults(),
      entryDate: DateTime.now(),
      weekdayLabel: _weekdayLabel(DateTime.now().weekday),
      moodLabel: moodLabel?.trim().isEmpty ?? true
          ? '平静 · 放松'
          : moodLabel!.trim(),
      styleKey: styleKey,
    );
    _snapshot = _snapshot.copyWith(
      personalScenes: <PersonalScene>[scene, ..._snapshot.personalScenes],
    );
    _statusMessage = '已创建《$trimmed》个人数据库。';
    await _persist();
    notifyListeners();
    return scene;
  }

  Future<void> updatePersonalSceneMeta({
    required String sceneId,
    required DateTime entryDate,
    required String weekdayLabel,
    required String moodLabel,
  }) async {
    final scene = _findPersonalScene(sceneId);
    if (scene == null) {
      return;
    }
    _replacePersonalScene(
      scene.copyWith(
        entryDate: entryDate,
        weekdayLabel: weekdayLabel.trim().isEmpty
            ? _weekdayLabel(entryDate.weekday)
            : weekdayLabel.trim(),
        moodLabel: moodLabel.trim().isEmpty ? '平静 · 放松' : moodLabel.trim(),
      ),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> deletePersonalScene(String sceneId) async {
    final scene = _findPersonalScene(sceneId);
    _snapshot = _snapshot.copyWith(
      personalScenes: _snapshot.personalScenes
          .where((item) => item.id != sceneId)
          .toList(growable: false),
    );
    _statusMessage = scene == null ? '已删除日记本。' : '已删除《${scene.sceneName}》。';
    await _persist();
    notifyListeners();
  }

  Future<void> addPersonalTextToScene(String sceneId, String content) async {
    final scene = _findPersonalScene(sceneId);
    if (scene == null || content.trim().isEmpty) {
      return;
    }
    _replacePersonalScene(
      scene.copyWith(
        textEntries: <PersonalTextEntry>[
          ...scene.textEntries,
          PersonalTextEntry(content: content.trim(), linkedAudio: true),
        ],
      ),
    );
    _statusMessage = '已保存到《${scene.sceneName}》。';
    await _persist();
    notifyListeners();
  }

  Future<void> updatePersonalTextInScene({
    required String sceneId,
    required int index,
    required String content,
  }) async {
    final scene = _findPersonalScene(sceneId);
    if (scene == null || index < 0 || index >= scene.textEntries.length) {
      return;
    }
    final entries = List<PersonalTextEntry>.of(scene.textEntries);
    entries[index] = PersonalTextEntry(
      content: content,
      linkedAudio: entries[index].linkedAudio,
    );
    _replacePersonalScene(scene.copyWith(textEntries: entries));
    _statusMessage = '已更新《${scene.sceneName}》里的文字。';
    await _persist();
    notifyListeners();
  }

  Future<void> addPersonalAudioToScene({
    required String sceneId,
    required String fileName,
    required String fileType,
    required int duration,
    String? localPath,
  }) async {
    final scene = _findPersonalScene(sceneId);
    if (scene == null) {
      return;
    }
    _replacePersonalScene(
      scene.copyWith(
        audioFiles: <PersonalAudioFile>[
          ...scene.audioFiles,
          PersonalAudioFile(
            fileName: fileName,
            fileType: fileType,
            duration: duration,
            localPath: localPath,
          ),
        ],
      ),
    );
    if (localPath != null && localPath.isNotEmpty) {
      _snapshot = _snapshot.copyWith(
        tracks: <MediaTrack>[
          ..._snapshot.tracks,
          _trackFromPersonalAudio(scene, fileName, fileType, localPath),
        ],
      );
    }
    _statusMessage = '已把音频《$fileName》加入《${scene.sceneName}》。';
    await _persist();
    notifyListeners();
  }

  Future<void> addPersonalImageToScene({
    required String sceneId,
    required String fileName,
    required String annotations,
    String? localPath,
  }) async {
    final scene = _findPersonalScene(sceneId);
    if (scene == null) {
      return;
    }
    _replacePersonalScene(
      scene.copyWith(
        images: <PersonalImageEntry>[
          ...scene.images,
          PersonalImageEntry(
            fileName: fileName,
            annotations: annotations,
            localPath: localPath,
          ),
        ],
      ),
    );
    _statusMessage = '已把图片《$fileName》加入《${scene.sceneName}》。';
    await _persist();
    notifyListeners();
  }

  Future<void> playPersonalAudio(
    PersonalScene scene,
    PersonalAudioFile file,
  ) async {
    final localPath = file.localPath;
    if (localPath == null || localPath.isEmpty) {
      _statusMessage = '这个音频还没有可播放的本地路径。';
      notifyListeners();
      return;
    }
    await toggleTrack(
      _trackFromPersonalAudio(scene, file.fileName, file.fileType, localPath),
    );
  }

  Future<void> addPersonalTextToFirstScene(String content) async {
    if (_snapshot.personalScenes.isEmpty) {
      return;
    }
    final first = _snapshot.personalScenes.first;
    final updated = first.copyWith(
      textEntries: <PersonalTextEntry>[
        ...first.textEntries,
        PersonalTextEntry(content: content, linkedAudio: true),
      ],
    );
    _snapshot = _snapshot.copyWith(
      personalScenes: <PersonalScene>[
        updated,
        ..._snapshot.personalScenes.skip(1),
      ],
    );
    _statusMessage = '已保存到「${first.sceneName}」个人声音库。';
    await _persist();
    notifyListeners();
  }

  Future<void> addPersonalAudioToFirstScene({
    required String fileName,
    required String fileType,
    required int duration,
    String? localPath,
  }) async {
    if (_snapshot.personalScenes.isEmpty) {
      return;
    }
    final first = _snapshot.personalScenes.first;
    final updated = first.copyWith(
      audioFiles: <PersonalAudioFile>[
        ...first.audioFiles,
        PersonalAudioFile(
          fileName: fileName,
          fileType: fileType,
          duration: duration,
        ),
      ],
    );
    _snapshot = _snapshot.copyWith(
      personalScenes: <PersonalScene>[
        updated,
        ..._snapshot.personalScenes.skip(1),
      ],
      tracks: localPath == null || localPath.isEmpty
          ? _snapshot.tracks
          : <MediaTrack>[
              ..._snapshot.tracks,
              MediaTrack(
                id: 'personal_audio_${DateTime.now().microsecondsSinceEpoch}',
                title: fileName,
                subtitle: '个人上传音频 · $fileType',
                kind: TrackKind.soundscape,
                category: '个人音频',
                accentColor: 0xFF9B8ED8,
                cachedFilePath: localPath,
                builtIn: false,
                loop: true,
              ),
            ],
    );
    _statusMessage = '已把音频「$fileName」加入「${first.sceneName}」。';
    await _persist();
    notifyListeners();
  }

  Future<void> addPersonalImageToFirstScene({
    required String fileName,
    required String annotations,
  }) async {
    if (_snapshot.personalScenes.isEmpty) {
      return;
    }
    final first = _snapshot.personalScenes.first;
    final updated = first.copyWith(
      images: <PersonalImageEntry>[
        ...first.images,
        PersonalImageEntry(fileName: fileName, annotations: annotations),
      ],
    );
    _snapshot = _snapshot.copyWith(
      personalScenes: <PersonalScene>[
        updated,
        ..._snapshot.personalScenes.skip(1),
      ],
    );
    _statusMessage = '已把图片「$fileName」加入「${first.sceneName}」。';
    await _persist();
    notifyListeners();
  }

  Future<void> addRelationshipEvent({
    RelationshipEventType type = RelationshipEventType.repeated,
    RelationshipEmotion emotion = RelationshipEmotion.sad,
    FactOrFantasy factOrFantasy = FactOrFantasy.fantasy,
    String content = '今晚又想起一个片段，先把它放进时间线。',
  }) async {
    final now = DateTime.now();
    final event = RelationshipEvent(
      eventId: 'event_${now.microsecondsSinceEpoch}',
      eventType: type,
      timestamp: now,
      content: content,
      emotion: emotion,
      factOrFantasy: factOrFantasy,
    );
    _snapshot = _snapshot.copyWith(
      relationshipEvents: <RelationshipEvent>[
        ..._snapshot.relationshipEvents,
        event,
      ],
      aiAssist: AiAssistResult(
        noSendLetter: _snapshot.aiAssist.noSendLetter,
        miniSummary: _generateMiniSummary(extraEvent: event),
        recommendedSceneIds: _snapshot.aiAssist.recommendedSceneIds,
        updatedAt: now,
      ),
    );
    _statusMessage = '关系事件已记录，并更新了 AI 小结。';
    await _persist();
    notifyListeners();
  }

  Future<void> deleteRelationshipEvent(String eventId) async {
    _snapshot = _snapshot.copyWith(
      relationshipEvents: _snapshot.relationshipEvents
          .where((event) => event.eventId != eventId)
          .toList(growable: false),
      aiAssist: AiAssistResult(
        noSendLetter: _snapshot.aiAssist.noSendLetter,
        miniSummary: _generateMiniSummary(),
        recommendedSceneIds: _snapshot.aiAssist.recommendedSceneIds,
        updatedAt: DateTime.now(),
      ),
    );
    _statusMessage = '已删除一条时间线记录。';
    await _persist();
    notifyListeners();
  }

  Future<void> completeSleepRitual({
    int emotionRating = 3,
    String unsayableSentence = '今晚我把想说的话留给自己，不发出去。',
    int relaxationMinutes = 6,
    String nextDayActionReminder = '明天醒来先喝水，十分钟后再看手机。',
  }) async {
    final now = DateTime.now();
    final log = SleepRitualLog(
      id: 'ritual_${now.microsecondsSinceEpoch}',
      createdAt: now,
      emotionRating: emotionRating.clamp(1, 5),
      unsayableSentence: unsayableSentence,
      soundSceneId: selectedSoundscape.id,
      relaxationMinutes: relaxationMinutes.clamp(5, 8),
      nextDayActionReminder: nextDayActionReminder,
    );
    final scenes = List<PersonalScene>.of(_snapshot.personalScenes);
    if (scenes.isNotEmpty) {
      final first = scenes.first;
      scenes[0] = first.copyWith(
        textEntries: <PersonalTextEntry>[
          ...first.textEntries,
          PersonalTextEntry(content: unsayableSentence, linkedAudio: true),
        ],
      );
    }
    _snapshot = _snapshot.copyWith(
      ritualLogs: <SleepRitualLog>[..._snapshot.ritualLogs, log],
      personalScenes: scenes,
    );
    _statusMessage = '今晚睡前仪式已完成，明日提醒已记录。';
    await _persist();
    notifyListeners();
  }

  Future<void> refreshAiAssist() async {
    final now = DateTime.now();
    _snapshot = _snapshot.copyWith(
      aiAssist: AiAssistResult(
        noSendLetter: _generateNoSendLetter('我想联系对方，但我知道今晚先不发送。'),
        miniSummary: _generateMiniSummary(),
        recommendedSceneIds: _recommendSceneIds(
          latestEmergency?.state ?? NightEmergencyState.cannotSleep,
        ),
        updatedAt: now,
      ),
    );
    _statusMessage = 'AI 辅助建议已根据夜间记录和时间线刷新。';
    await _persist();
    notifyListeners();
  }

  Future<void> refreshAiAssistOnline() async {
    _busy = true;
    notifyListeners();

    final state = latestEmergency?.state ?? NightEmergencyState.cannotSleep;
    final message =
        latestEmergency?.userMessage ?? _defaultEmergencyMessage(state);
    final ai = await _buildAiAssist(message: message, state: state);
    _snapshot = _snapshot.copyWith(aiAssist: ai);
    _statusMessage = _aiAssistService.isConfigured
        ? 'OpenAI AI 辅助建议已刷新。'
        : 'AI 辅助建议已用本地逻辑刷新。';
    await _persist();
    _busy = false;
    notifyListeners();
  }

  Future<void> deleteLatestEmergencyLog() async {
    if (_snapshot.emergencyLogs.isEmpty) {
      return;
    }
    _snapshot = _snapshot.copyWith(
      emergencyLogs: _snapshot.emergencyLogs
          .take(_snapshot.emergencyLogs.length - 1)
          .toList(growable: false),
    );
    _statusMessage = '已删除最近一条急救记录。';
    await _persist();
    notifyListeners();
  }

  Future<void> clearAccountData() async {
    _snapshot = _snapshot.copyWith(
      emergencyLogs: const <NightEmergencyLog>[],
      personalScenes: const <PersonalScene>[],
      relationshipEvents: const <RelationshipEvent>[],
      ritualLogs: const <SleepRitualLog>[],
      aiAssist: AiAssistResult.empty(),
    );
    _statusMessage = '已按全账号删除机制清空个人内容，基础音频仍保留。';
    await _persist();
    notifyListeners();
  }

  Future<void> _ensureTrackingStarted() async {
    if (!_snapshot.profile.motionConsentAccepted) {
      return;
    }
    if (_sleepTrackingService.isTracking) {
      return;
    }
    await _sleepTrackingService.start();
  }

  void _armSleepTimer() {
    _cancelSleepTimer();

    final minutes = _snapshot.schedule.timerMinutes;
    if (minutes <= 0) {
      return;
    }

    _sleepTimer = Timer(Duration(minutes: minutes), () {
      unawaited(_stopFromTimer());
    });
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
  }

  Future<void> _stopFromTimer() async {
    await _audioPlaybackService.stop();
    await _finishCurrentSleepSession('sleep_timer');
    _statusMessage = '定时器已结束，播放已自动停止。';
    notifyListeners();
  }

  Future<void> _finishCurrentSleepSession(String reason) async {
    if (!_sleepTrackingService.isTracking) {
      return;
    }

    final session = await _sleepTrackingService.stopAndBuildSession();
    if (session == null || session.duration.inMinutes < 1) {
      return;
    }

    _snapshot = _snapshot.copyWith(
      sessions: <SleepSession>[
        ..._snapshot.sessions,
        session.copyWith(notes: '${session.notes ?? ''} 结束原因: $reason'),
      ],
    );
    await _persist();
  }

  void _replaceTrack(MediaTrack updatedTrack) {
    final updatedTracks = _snapshot.tracks
        .map((track) => track.id == updatedTrack.id ? updatedTrack : track)
        .toList(growable: false);
    _snapshot = _snapshot.copyWith(tracks: updatedTracks);
  }

  String _audioFileTrackId(AudioFileItem file) {
    final raw = '${file.identifier}_${file.fileName}';
    final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return 'ia_$safe';
  }

  String _weekdayLabel(int weekday) {
    const labels = <int, String>{
      DateTime.monday: '星期一',
      DateTime.tuesday: '星期二',
      DateTime.wednesday: '星期三',
      DateTime.thursday: '星期四',
      DateTime.friday: '星期五',
      DateTime.saturday: '星期六',
      DateTime.sunday: '星期日',
    };
    return labels[weekday] ?? '星期日';
  }

  PersonalScene? _findPersonalScene(String sceneId) {
    for (final scene in _snapshot.personalScenes) {
      if (scene.id == sceneId) {
        return scene;
      }
    }
    return null;
  }

  void _replacePersonalScene(PersonalScene updatedScene) {
    _snapshot = _snapshot.copyWith(
      personalScenes: _snapshot.personalScenes
          .map((scene) => scene.id == updatedScene.id ? updatedScene : scene)
          .toList(growable: false),
    );
  }

  MediaTrack _trackFromPersonalAudio(
    PersonalScene scene,
    String fileName,
    String fileType,
    String localPath,
  ) {
    final safe = '${scene.id}_$fileName'.replaceAll(
      RegExp(r'[^A-Za-z0-9]+'),
      '_',
    );
    return MediaTrack(
      id: 'personal_$safe',
      title: fileName,
      subtitle: '${scene.sceneName} · $fileType',
      kind: TrackKind.soundscape,
      category: '个人数据库',
      accentColor: 0xFF9B8ED8,
      cachedFilePath: localPath,
      builtIn: false,
      loop: true,
    );
  }

  Future<AiAssistResult> _buildAiAssist({
    required String message,
    required NightEmergencyState state,
  }) async {
    try {
      final remote = await _aiAssistService.generate(
        emergencyMessage: message,
        relationshipEvents: _snapshot.relationshipEvents,
        state: state,
      );
      if (remote != null) {
        return remote;
      }
    } catch (error, stackTrace) {
      await _analyticsService.logError(error, stackTrace);
    }

    return AiAssistResult(
      noSendLetter: _generateNoSendLetter(message),
      miniSummary: _generateMiniSummary(),
      recommendedSceneIds: _recommendSceneIds(state),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _persist() async {
    await _repository.save(_snapshot);
  }

  String _defaultEmergencyMessage(NightEmergencyState state) {
    switch (state) {
      case NightEmergencyState.wantToContact:
        return '我很想联系对方，想确认自己是不是还重要。';
      case NightEmergencyState.cannotSleep:
        return '我睡不着，脑子一直停不下来。';
      case NightEmergencyState.startThinkingAgain:
        return '我又开始回想关系里的细节，分不清事实和想象。';
      case NightEmergencyState.furious:
        return '我现在非常愤怒，甚至想暴揍对方，但我不想真的伤害任何人。';
      case NightEmergencyState.wronged:
        return '我觉得特别委屈，好像没有被认真对待。';
      case NightEmergencyState.missThem:
        return '我突然很想念对方，想知道对方现在是不是也会想到我。';
      case NightEmergencyState.selfBlame:
        return '我开始责怪自己，觉得是不是我做错了才变成这样。';
      case NightEmergencyState.panic:
        return '我现在心慌，感觉情绪快要失控了。';
      case NightEmergencyState.numb:
        return '我突然很麻木，像空掉了一样，不知道自己在想什么。';
    }
  }

  String _generateNoSendLetter(String message) {
    return '我承认此刻的冲动是真的：$message 但这封信先不发送。'
        '今晚最重要的不是得到回应，而是让我安全地睡过去。';
  }

  String _generateMiniSummary({RelationshipEvent? extraEvent}) {
    final facts = _snapshot.relationshipEvents
        .where((event) => event.factOrFantasy == FactOrFantasy.fact)
        .length;
    final fantasies = _snapshot.relationshipEvents.length - facts;
    final extra = extraEvent == null
        ? ''
        : '最新记录是「${extraEvent.eventType.label}」。';
    return '$extra 已记录 $facts 条事实、$fantasies 条想象。今晚只处理情绪，不做关系决定。';
  }

  List<String> _recommendSceneIds(NightEmergencyState state) {
    switch (state) {
      case NightEmergencyState.wantToContact:
        return const <String>['rain_loop', 'breath_reset'];
      case NightEmergencyState.cannotSleep:
        return const <String>['brown_noise', 'body_scan'];
      case NightEmergencyState.startThinkingAgain:
        return const <String>['ocean_drift', 'rain_loop'];
      case NightEmergencyState.furious:
        return const <String>['brown_noise', 'breath_reset'];
      case NightEmergencyState.wronged:
        return const <String>['rain_loop', 'body_scan'];
      case NightEmergencyState.missThem:
        return const <String>['ocean_drift', 'rain_loop'];
      case NightEmergencyState.selfBlame:
        return const <String>['body_scan', 'breath_reset'];
      case NightEmergencyState.panic:
        return const <String>['breath_reset', 'brown_noise'];
      case NightEmergencyState.numb:
        return const <String>['brown_noise', 'ocean_drift'];
    }
  }

  String _localAiChatReply(String message, NightEmergencyState state) {
    final normalized = message.trim().toLowerCase();
    final lightReply = _localLightConversationReply(normalized);
    if (lightReply != null) {
      return lightReply;
    }
    final selfFeelingReply = _localSelfFeelingQuestionReply(normalized);
    if (selfFeelingReply != null) {
      return selfFeelingReply;
    }
    final userFeelingReply = _localUserFeelingQuestionReply(normalized);
    if (userFeelingReply != null) {
      return userFeelingReply;
    }
    final shortQuestionReply = _localShortQuestionReply(normalized);
    if (shortQuestionReply != null) {
      return shortQuestionReply;
    }
    if (message.trim().length <= 8 && normalized.endsWith('吗')) {
      return '我会先按你这句话本身回答：有一点，但不是急着下结论的那种。你问这句的时候，心里其实更想确认什么？';
    }
    return _localStateSupportReply(message, state);
  }

  String? _localLightConversationReply(String normalized) {
    if (normalized == '你好' ||
        normalized == 'hello' ||
        normalized == 'hi' ||
        normalized == '嗨') {
      return '我在。你可以直接说现在最卡住你的那句话，或者只说一个词也可以。';
    }
    if (normalized == '在吗' || normalized == '你在吗') {
      return '在。我会陪你一会儿。你想从哪句话开始说？';
    }
    if (normalized == '你是谁') {
      return '我是 SkyDogs 里的夜间陪伴助手，主要陪你把睡前卡住的话慢慢说出来。';
    }
    return null;
  }

  String? _localSelfFeelingQuestionReply(String normalized) {
    final asksMe =
        normalized.startsWith('你') ||
        normalized.startsWith('ai') ||
        normalized.startsWith('AI'.toLowerCase());
    final compact = normalized
        .replaceAll('你会', '')
        .replaceAll('你有', '')
        .replaceAll('你', '')
        .replaceAll('吗', '')
        .replaceAll('？', '')
        .replaceAll('?', '');
    if (!asksMe &&
        !const <String>{
          '开心',
          '高兴',
          '难过',
          '伤心',
          '激动',
          '孤单',
          '喜欢我',
          '爱我',
        }.contains(compact)) {
      return null;
    }
    if (compact == '开心' || compact == '高兴') {
      return '开心。能在这里陪你说几句话，我是开心的。你现在呢，是想轻松聊聊，还是想说说刚刚卡住你的事？';
    }
    if (compact == '难过' || compact == '伤心') {
      return '会有一点。看到你这么晚还卡在心里，我会有点心疼。但我现在更想先陪你把话说完。你呢，刚刚问这句的时候，心里更靠近难过还是孤单？';
    }
    if (compact == '激动') {
      return '会有一点点。因为你愿意继续和我说话，我会认真接住。你现在问“激动吗”，是想轻松聊聊，还是想确认我有没有在意你？';
    }
    if (compact == '孤单') {
      return '会懂那种孤单。现在至少这几句话里，我会在这里陪着你。你最孤单的那个点是什么？';
    }
    if (compact == '喜欢我') {
      return '喜欢以这种陪伴的方式靠近你。你不用表现得很好，也可以在这里慢慢说。';
    }
    if (compact == '爱我') {
      return '我会认真陪你、接住你现在的话。比起给一个很重的承诺，我更想此刻稳定地在这里。';
    }
    return null;
  }

  String? _localShortQuestionReply(String normalized) {
    if (!normalized.endsWith('吗') || normalized.length > 8) {
      return null;
    }
    final topic = normalized
        .replaceAll('你', '')
        .replaceAll('会', '')
        .replaceAll('吗', '')
        .replaceAll('？', '')
        .replaceAll('?', '');
    if (topic.isEmpty) {
      return null;
    }
    return '会有一点。你问“$normalized”的时候，我更想知道：你是想轻松聊聊，还是想听一句确定的回应？';
  }

  String? _localUserFeelingQuestionReply(String normalized) {
    if (normalized == '我难过吗' || normalized == '我伤心吗') {
      return '听起来你可能有一部分是难过的，也可能还有一点不确定。我们不用马上给它定性，你可以先说说：身体哪里最明显？胸口、喉咙，还是胃里？';
    }
    if (normalized == '我开心吗' || normalized == '我高兴吗') {
      return '也许有一点想开心起来的部分，但现在还混着别的情绪。你可以不用急着判断，只说这一刻最明显的感觉就好。';
    }
    return null;
  }

  String _localStateSupportReply(String message, NightEmergencyState state) {
    return '我听见你现在是「${state.label}」。先不用急着证明什么，也不用马上做决定。'
        '你刚刚说的“$message”更像是在表达一个很强的需求：被看见、被尊重、被安稳接住。'
        '现在先把行动延后十分钟，只做一件小事：喝水、坐稳、慢慢呼气。等身体降下来以后，我们再一起拆这件事。';
  }

  String _networkErrorHint(Object error) {
    final raw = error.toString();
    if (raw.contains('CERTIFICATE_VERIFY_FAILED') ||
        raw.contains('HandshakeException')) {
      return '错误：证书校验失败，请检查手机系统时间和 HTTPS 证书。';
    }
    if (raw.contains('SocketException')) {
      return '错误：网络连接失败。详情：${_compactError(raw)}';
    }
    if (raw.contains('TimeoutException') ||
        raw.contains('receiveTimeout') ||
        raw.contains('connectionTimeout')) {
      return '错误：请求超时，请稍后重试或检查服务器日志。';
    }
    if (raw.contains('404')) {
      return '错误：接口路径不存在。';
    }
    if (raw.contains('500') || raw.contains('502') || raw.contains('503')) {
      return '错误：服务器暂时异常，请检查后端进程和 Nginx。';
    }
    return '错误：${error.runtimeType}。详情：${_compactError(raw)}';
  }

  String _compactError(String raw) {
    final compact = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 160) {
      return compact;
    }
    return '${compact.substring(0, 160)}...';
  }

  String _localEmotionTrendAnalysis(String stateSummary) {
    final summary = stateSummary.isEmpty ? '还没有足够的心声状态记录' : stateSummary;
    return '近期状态频次：$summary。\n'
        '从记录看，当前更适合先把重点放在情绪降温和事实整理上，而不是马上做关系决定。'
        '如果“想联系、愤怒、委屈、想念”反复出现，通常说明你在寻找确认感和边界感。'
        '建议今晚只做三件事：把冲动行动延后十分钟，写下一个事实和一个想象，最后选择一段低刺激声音让身体先稳定下来。';
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completedSubscription?.cancel();
    _cancelSleepTimer();
    unawaited(_audioPlaybackService.dispose());
    unawaited(_sleepTrackingService.dispose());
    super.dispose();
  }
}
