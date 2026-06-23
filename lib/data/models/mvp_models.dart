enum EmotionStage { earlyBreakup, adjusting, released }

extension EmotionStageLabel on EmotionStage {
  String get label {
    switch (this) {
      case EmotionStage.earlyBreakup:
        return '初期分手';
      case EmotionStage.adjusting:
        return '调整期';
      case EmotionStage.released:
        return '释怀期';
    }
  }
}

enum LoginMethod { phone, email, thirdParty }

enum NightEmergencyState {
  wantToContact,
  cannotSleep,
  startThinkingAgain,
  furious,
  wronged,
  missThem,
  selfBlame,
  panic,
  numb,
}

extension NightEmergencyStateLabel on NightEmergencyState {
  String get label {
    switch (this) {
      case NightEmergencyState.wantToContact:
        return '想联系对方';
      case NightEmergencyState.cannotSleep:
        return '睡不着';
      case NightEmergencyState.startThinkingAgain:
        return '又开始想';
      case NightEmergencyState.furious:
        return '想暴揍对方';
      case NightEmergencyState.wronged:
        return '特别委屈';
      case NightEmergencyState.missThem:
        return '突然很想念';
      case NightEmergencyState.selfBlame:
        return '开始责怪自己';
      case NightEmergencyState.panic:
        return '心慌失控';
      case NightEmergencyState.numb:
        return '麻木空掉';
    }
  }

  List<String> get actions {
    switch (this) {
      case NightEmergencyState.wantToContact:
        return const <String>['写下来', '生成不发送的信', '安抚建议'];
      case NightEmergencyState.cannotSleep:
        return const <String>['个性化助眠', '呼吸练习', '倒计时'];
      case NightEmergencyState.startThinkingAgain:
        return const <String>['复盘时间线', '标记情绪', '生成小结'];
      case NightEmergencyState.furious:
        return const <String>['承接愤怒', '降低冲动', '保护边界'];
      case NightEmergencyState.wronged:
        return const <String>['命名委屈', '确认需求', '安抚自己'];
      case NightEmergencyState.missThem:
        return const <String>['区分想念和行动', '写下但不发送', '稳定呼吸'];
      case NightEmergencyState.selfBlame:
        return const <String>['停止自责循环', '还原事实', '给自己一句话'];
      case NightEmergencyState.panic:
        return const <String>['落地练习', '身体扫描', '短句陪伴'];
      case NightEmergencyState.numb:
        return const <String>['轻量记录', '找回身体感', '低刺激声音'];
    }
  }
}

enum RelationshipEventType {
  met,
  ambiguous,
  confirmed,
  conflict,
  distant,
  breakup,
  reunion,
  repeated,
}

extension RelationshipEventTypeLabel on RelationshipEventType {
  String get label {
    switch (this) {
      case RelationshipEventType.met:
        return '认识';
      case RelationshipEventType.ambiguous:
        return '暧昧';
      case RelationshipEventType.confirmed:
        return '确认';
      case RelationshipEventType.conflict:
        return '冲突';
      case RelationshipEventType.distant:
        return '冷淡';
      case RelationshipEventType.breakup:
        return '分手';
      case RelationshipEventType.reunion:
        return '复合';
      case RelationshipEventType.repeated:
        return '反复';
    }
  }
}

enum RelationshipEmotion {
  angry,
  sad,
  relieved,
  empty,
  anxious,
  nostalgic,
  calm,
  guilty,
  hopeful,
  numb,
}

extension RelationshipEmotionLabel on RelationshipEmotion {
  String get label {
    switch (this) {
      case RelationshipEmotion.angry:
        return '愤怒';
      case RelationshipEmotion.sad:
        return '悲伤';
      case RelationshipEmotion.relieved:
        return '释怀';
      case RelationshipEmotion.empty:
        return '空虚';
      case RelationshipEmotion.anxious:
        return '焦虑';
      case RelationshipEmotion.nostalgic:
        return '怀念';
      case RelationshipEmotion.calm:
        return '平静';
      case RelationshipEmotion.guilty:
        return '内疚';
      case RelationshipEmotion.hopeful:
        return '期待';
      case RelationshipEmotion.numb:
        return '麻木';
    }
  }
}

enum FactOrFantasy { fact, fantasy }

extension FactOrFantasyLabel on FactOrFantasy {
  String get label => this == FactOrFantasy.fact ? '事实' : '幻想';
}

class UserAccount {
  const UserAccount({
    required this.userId,
    required this.nickname,
    required this.emotionStage,
    required this.loginMethod,
    required this.defaultPrivate,
    this.gender,
    this.email,
    this.phone,
    this.avatarPath,
    this.signature,
    this.passwordHint = '本地加密保存',
  });

  final String userId;
  final String nickname;
  final String? gender;
  final EmotionStage emotionStage;
  final LoginMethod loginMethod;
  final String? email;
  final String? phone;
  final String? avatarPath;
  final String? signature;
  final String passwordHint;
  final bool defaultPrivate;

  UserAccount copyWith({
    String? userId,
    String? nickname,
    String? gender,
    EmotionStage? emotionStage,
    LoginMethod? loginMethod,
    String? email,
    String? phone,
    String? avatarPath,
    String? signature,
    String? passwordHint,
    bool? defaultPrivate,
  }) {
    return UserAccount(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      emotionStage: emotionStage ?? this.emotionStage,
      loginMethod: loginMethod ?? this.loginMethod,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      signature: signature ?? this.signature,
      passwordHint: passwordHint ?? this.passwordHint,
      defaultPrivate: defaultPrivate ?? this.defaultPrivate,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'nickname': nickname,
      'gender': gender,
      'emotionStage': emotionStage.name,
      'loginMethod': loginMethod.name,
      'email': email,
      'phone': phone,
      'avatarPath': avatarPath,
      'signature': signature,
      'passwordHint': passwordHint,
      'defaultPrivate': defaultPrivate,
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      userId: json['userId'] as String? ?? 'local-user',
      nickname: json['nickname'] as String? ?? 'SkyDogs 用户',
      gender: json['gender'] as String?,
      emotionStage: EmotionStage.values.byName(
        json['emotionStage'] as String? ?? EmotionStage.adjusting.name,
      ),
      loginMethod: LoginMethod.values.byName(
        json['loginMethod'] as String? ?? LoginMethod.email.name,
      ),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarPath: json['avatarPath'] as String?,
      signature: json['signature'] as String?,
      passwordHint: json['passwordHint'] as String? ?? '本地加密保存',
      defaultPrivate: json['defaultPrivate'] as bool? ?? true,
    );
  }

  factory UserAccount.defaults() {
    return const UserAccount(
      userId: 'local-user',
      nickname: 'SkyDogs 用户',
      emotionStage: EmotionStage.adjusting,
      loginMethod: LoginMethod.email,
      defaultPrivate: true,
    );
  }
}

class NightEmergencyLog {
  const NightEmergencyLog({
    required this.id,
    required this.state,
    required this.createdAt,
    required this.userMessage,
    required this.actions,
    this.aiLetter,
    this.miniSummary,
  });

  final String id;
  final NightEmergencyState state;
  final DateTime createdAt;
  final String userMessage;
  final List<String> actions;
  final String? aiLetter;
  final String? miniSummary;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'state': state.name,
      'createdAt': createdAt.toIso8601String(),
      'userMessage': userMessage,
      'actions': actions,
      'aiLetter': aiLetter,
      'miniSummary': miniSummary,
    };
  }

  factory NightEmergencyLog.fromJson(Map<String, dynamic> json) {
    return NightEmergencyLog(
      id: json['id'] as String,
      state: NightEmergencyState.values.byName(json['state'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      userMessage: json['userMessage'] as String? ?? '',
      actions: (json['actions'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item as String)
          .toList(),
      aiLetter: json['aiLetter'] as String?,
      miniSummary: json['miniSummary'] as String?,
    );
  }
}

class PersonalScene {
  const PersonalScene({
    required this.id,
    required this.sceneName,
    required this.audioFiles,
    required this.textEntries,
    required this.images,
    required this.playbackOptions,
    this.entryDate,
    this.weekdayLabel,
    this.moodLabel,
    this.styleKey,
  });

  final String id;
  final String sceneName;
  final List<PersonalAudioFile> audioFiles;
  final List<PersonalTextEntry> textEntries;
  final List<PersonalImageEntry> images;
  final PlaybackOptions playbackOptions;
  final DateTime? entryDate;
  final String? weekdayLabel;
  final String? moodLabel;
  final String? styleKey;

  PersonalScene copyWith({
    String? id,
    String? sceneName,
    List<PersonalAudioFile>? audioFiles,
    List<PersonalTextEntry>? textEntries,
    List<PersonalImageEntry>? images,
    PlaybackOptions? playbackOptions,
    DateTime? entryDate,
    String? weekdayLabel,
    String? moodLabel,
    String? styleKey,
  }) {
    return PersonalScene(
      id: id ?? this.id,
      sceneName: sceneName ?? this.sceneName,
      audioFiles: audioFiles ?? this.audioFiles,
      textEntries: textEntries ?? this.textEntries,
      images: images ?? this.images,
      playbackOptions: playbackOptions ?? this.playbackOptions,
      entryDate: entryDate ?? this.entryDate,
      weekdayLabel: weekdayLabel ?? this.weekdayLabel,
      moodLabel: moodLabel ?? this.moodLabel,
      styleKey: styleKey ?? this.styleKey,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sceneName': sceneName,
      'audioFiles': audioFiles.map((item) => item.toJson()).toList(),
      'textEntries': textEntries.map((item) => item.toJson()).toList(),
      'images': images.map((item) => item.toJson()).toList(),
      'playbackOptions': playbackOptions.toJson(),
      'entryDate': entryDate?.toIso8601String(),
      'weekdayLabel': weekdayLabel,
      'moodLabel': moodLabel,
      'styleKey': styleKey,
    };
  }

  factory PersonalScene.fromJson(Map<String, dynamic> json) {
    return PersonalScene(
      id: json['id'] as String,
      sceneName: json['sceneName'] as String? ?? '未命名日记本',
      audioFiles: (json['audioFiles'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => PersonalAudioFile.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      textEntries: (json['textEntries'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => PersonalTextEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      images: (json['images'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => PersonalImageEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      playbackOptions: PlaybackOptions.fromJson(
        json['playbackOptions'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      entryDate: json['entryDate'] == null
          ? null
          : DateTime.parse(json['entryDate'] as String),
      weekdayLabel: json['weekdayLabel'] as String?,
      moodLabel: json['moodLabel'] as String?,
      styleKey: json['styleKey'] as String?,
    );
  }
}

extension PersonalSceneStats on PersonalScene {
  int get audioDurationSeconds =>
      audioFiles.fold<int>(0, (sum, file) => sum + file.duration);
}

class PersonalAudioFile {
  const PersonalAudioFile({
    required this.fileName,
    required this.fileType,
    required this.duration,
    this.localPath,
  });

  final String fileName;
  final String fileType;
  final int duration;
  final String? localPath;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fileName': fileName,
      'fileType': fileType,
      'duration': duration,
      'localPath': localPath,
    };
  }

  factory PersonalAudioFile.fromJson(Map<String, dynamic> json) {
    return PersonalAudioFile(
      fileName: json['fileName'] as String? ?? '',
      fileType: json['fileType'] as String? ?? 'audio',
      duration: json['duration'] as int? ?? 0,
      localPath: json['localPath'] as String?,
    );
  }
}

class PersonalTextEntry {
  const PersonalTextEntry({required this.content, required this.linkedAudio});

  final String content;
  final bool linkedAudio;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'content': content, 'linkedAudio': linkedAudio};
  }

  factory PersonalTextEntry.fromJson(Map<String, dynamic> json) {
    return PersonalTextEntry(
      content: json['content'] as String? ?? '',
      linkedAudio: json['linkedAudio'] as bool? ?? false,
    );
  }
}

class PersonalImageEntry {
  const PersonalImageEntry({
    required this.fileName,
    required this.annotations,
    this.localPath,
  });

  final String fileName;
  final String annotations;
  final String? localPath;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fileName': fileName,
      'annotations': annotations,
      'localPath': localPath,
    };
  }

  factory PersonalImageEntry.fromJson(Map<String, dynamic> json) {
    return PersonalImageEntry(
      fileName: json['fileName'] as String? ?? '',
      annotations: json['annotations'] as String? ?? '',
      localPath: json['localPath'] as String?,
    );
  }
}

class PlaybackOptions {
  const PlaybackOptions({
    required this.single,
    required this.loop,
    required this.shuffle,
    required this.personalizedPlaylist,
  });

  final bool single;
  final bool loop;
  final bool shuffle;
  final bool personalizedPlaylist;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'single': single,
      'loop': loop,
      'shuffle': shuffle,
      'personalizedPlaylist': personalizedPlaylist,
    };
  }

  factory PlaybackOptions.fromJson(Map<String, dynamic> json) {
    return PlaybackOptions(
      single: json['single'] as bool? ?? true,
      loop: json['loop'] as bool? ?? true,
      shuffle: json['shuffle'] as bool? ?? true,
      personalizedPlaylist: json['personalizedPlaylist'] as bool? ?? true,
    );
  }

  factory PlaybackOptions.defaults() {
    return const PlaybackOptions(
      single: true,
      loop: true,
      shuffle: true,
      personalizedPlaylist: true,
    );
  }
}

class RelationshipEvent {
  const RelationshipEvent({
    required this.eventId,
    required this.eventType,
    required this.timestamp,
    required this.content,
    required this.emotion,
    required this.factOrFantasy,
    this.audio,
    this.image,
  });

  final String eventId;
  final RelationshipEventType eventType;
  final DateTime timestamp;
  final String content;
  final String? audio;
  final String? image;
  final RelationshipEmotion emotion;
  final FactOrFantasy factOrFantasy;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eventId': eventId,
      'eventType': eventType.name,
      'timestamp': timestamp.toIso8601String(),
      'content': content,
      'audio': audio,
      'image': image,
      'emotion': emotion.name,
      'factOrFantasy': factOrFantasy.name,
    };
  }

  factory RelationshipEvent.fromJson(Map<String, dynamic> json) {
    return RelationshipEvent(
      eventId: json['eventId'] as String,
      eventType: RelationshipEventType.values.byName(
        json['eventType'] as String,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      content: json['content'] as String? ?? '',
      audio: json['audio'] as String?,
      image: json['image'] as String?,
      emotion: RelationshipEmotion.values.byName(
        json['emotion'] as String? ?? RelationshipEmotion.sad.name,
      ),
      factOrFantasy: FactOrFantasy.values.byName(
        json['factOrFantasy'] as String? ?? FactOrFantasy.fact.name,
      ),
    );
  }
}

class SleepRitualLog {
  const SleepRitualLog({
    required this.id,
    required this.createdAt,
    required this.emotionRating,
    required this.unsayableSentence,
    required this.soundSceneId,
    required this.relaxationMinutes,
    required this.nextDayActionReminder,
  });

  final String id;
  final DateTime createdAt;
  final int emotionRating;
  final String unsayableSentence;
  final String soundSceneId;
  final int relaxationMinutes;
  final String nextDayActionReminder;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'emotionRating': emotionRating,
      'unsayableSentence': unsayableSentence,
      'soundSceneId': soundSceneId,
      'relaxationMinutes': relaxationMinutes,
      'nextDayActionReminder': nextDayActionReminder,
    };
  }

  factory SleepRitualLog.fromJson(Map<String, dynamic> json) {
    return SleepRitualLog(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      emotionRating: json['emotionRating'] as int? ?? 3,
      unsayableSentence: json['unsayableSentence'] as String? ?? '',
      soundSceneId: json['soundSceneId'] as String? ?? 'rain_loop',
      relaxationMinutes: json['relaxationMinutes'] as int? ?? 6,
      nextDayActionReminder: json['nextDayActionReminder'] as String? ?? '',
    );
  }
}

class AiAssistResult {
  const AiAssistResult({
    required this.noSendLetter,
    required this.miniSummary,
    required this.recommendedSceneIds,
    required this.updatedAt,
  });

  final String noSendLetter;
  final String miniSummary;
  final List<String> recommendedSceneIds;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'noSendLetter': noSendLetter,
      'miniSummary': miniSummary,
      'recommendedSceneIds': recommendedSceneIds,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AiAssistResult.fromJson(Map<String, dynamic> json) {
    return AiAssistResult(
      noSendLetter: json['noSendLetter'] as String? ?? '',
      miniSummary: json['miniSummary'] as String? ?? '',
      recommendedSceneIds:
          (json['recommendedSceneIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item as String)
              .toList(),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  factory AiAssistResult.empty() {
    return AiAssistResult(
      noSendLetter: '',
      miniSummary: '今晚先把冲动留在 SkyDogs 里，不必立刻做决定。',
      recommendedSceneIds: const <String>['rain_loop', 'breath_reset'],
      updatedAt: DateTime.now(),
    );
  }
}
