import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/media_track.dart';
import '../../data/models/mvp_models.dart';
import '../../services/archive_audio_service.dart';
import '../../state/sleep_app_controller.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _lastShownStatusMessage;

  static const _titles = <String>['心声', '声音', '时间线', '我的'];

  void _showStatusToast(SleepAppController controller) {
    final message = controller.statusMessage;
    if (message == null ||
        message == _lastShownStatusMessage ||
        message.startsWith('后端地址：')) {
      if (message != null) {
        _lastShownStatusMessage = message;
      }
      return;
    }
    _lastShownStatusMessage = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showSoftSnack(context, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepAppController>(
      builder: (context, controller, _) {
        _showStatusToast(controller);
        final pages = <Widget>[
          _EmergencyPage(controller: controller),
          _SoundPage(controller: controller),
          _TimelinePage(controller: controller),
          _ProfilePage(controller: controller),
        ];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(_titles[_selectedIndex]),
            actions: <Widget>[
              IconButton(
                tooltip: '刷新 AI 建议',
                onPressed: controller.refreshAiAssistOnline,
                icon: const Icon(Icons.auto_awesome_rounded),
              ),
            ],
          ),
          body: controller.initialized
              ? IndexedStack(index: _selectedIndex, children: pages)
              : const Center(child: CircularProgressIndicator()),
          bottomNavigationBar: SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.nightlight_round),
                  selectedIcon: Icon(Icons.healing_rounded),
                  label: '心声',
                ),
                NavigationDestination(
                  icon: Icon(Icons.graphic_eq_rounded),
                  label: '声音',
                ),
                NavigationDestination(
                  icon: Icon(Icons.timeline_rounded),
                  label: '时间线',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_rounded),
                  label: '我的',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotebookStyleSpec {
  const _NotebookStyleSpec({
    required this.key,
    required this.name,
    required this.subtitle,
    required this.mood,
    required this.icon,
    required this.pageColor,
    required this.paperColor,
    required this.accentColor,
    required this.softColor,
    required this.borderColor,
    required this.lineColor,
    required this.patchColor,
    required this.footerColor,
    required this.decorationIcon,
  });

  final String key;
  final String name;
  final String subtitle;
  final String mood;
  final IconData icon;
  final Color pageColor;
  final Color paperColor;
  final Color accentColor;
  final Color softColor;
  final Color borderColor;
  final Color lineColor;
  final Color patchColor;
  final Color footerColor;
  final IconData decorationIcon;
}

const _notebookStyles = <_NotebookStyleSpec>[
  _NotebookStyleSpec(
    key: 'lavender',
    name: '薰衣草梦境',
    subtitle: '紫色纸张 · 夜晚安心',
    mood: '平静 · 安心',
    icon: Icons.local_florist_rounded,
    pageColor: Color(0xFFF1EAF8),
    paperColor: Color(0xFFFFFAF0),
    accentColor: Color(0xFF7C629C),
    softColor: Color(0xFFEDE1F4),
    borderColor: Color(0xFFD7C2E5),
    lineColor: Color(0xFFE6D9EA),
    patchColor: Color(0xFF9E8CC4),
    footerColor: Color(0xFF6C5A86),
    decorationIcon: Icons.nightlight_round,
  ),
  _NotebookStyleSpec(
    key: 'forest',
    name: '森林清晨',
    subtitle: '叶片素材 · 清透呼吸',
    mood: '平静 · 感恩',
    icon: Icons.eco_rounded,
    pageColor: Color(0xFFF3F0DE),
    paperColor: Color(0xFFFFFCF0),
    accentColor: Color(0xFF60743E),
    softColor: Color(0xFFE8EED4),
    borderColor: Color(0xFFD5DDB3),
    lineColor: Color(0xFFE1DEC6),
    patchColor: Color(0xFFB6C27D),
    footerColor: Color(0xFF667247),
    decorationIcon: Icons.filter_vintage_rounded,
  ),
  _NotebookStyleSpec(
    key: 'ocean',
    name: '海风月光',
    subtitle: '蓝色海岸 · 月夜倾听',
    mood: '平静 · 宁静',
    icon: Icons.water_rounded,
    pageColor: Color(0xFFE8F1F7),
    paperColor: Color(0xFFFFFBF1),
    accentColor: Color(0xFF4D6F98),
    softColor: Color(0xFFDDE9F4),
    borderColor: Color(0xFFC1D2E4),
    lineColor: Color(0xFFD9E1E8),
    patchColor: Color(0xFF7EA3C6),
    footerColor: Color(0xFF476486),
    decorationIcon: Icons.waves_rounded,
  ),
  _NotebookStyleSpec(
    key: 'sakura',
    name: '樱花便签',
    subtitle: '粉色花束 · 温柔记录',
    mood: '平静 · 感恩',
    icon: Icons.local_florist_outlined,
    pageColor: Color(0xFFFFF0E8),
    paperColor: Color(0xFFFFFBF1),
    accentColor: Color(0xFFC96E72),
    softColor: Color(0xFFFCE0DA),
    borderColor: Color(0xFFF0BBB4),
    lineColor: Color(0xFFEED7CF),
    patchColor: Color(0xFFEAA0A8),
    footerColor: Color(0xFFA95F61),
    decorationIcon: Icons.favorite_border_rounded,
  ),
  _NotebookStyleSpec(
    key: 'lakeside',
    name: '湖畔晨光',
    subtitle: '湖边日光 · 安静放松',
    mood: '平静 · 放松',
    icon: Icons.wb_sunny_outlined,
    pageColor: Color(0xFFF4EBDD),
    paperColor: Color(0xFFFFF8EA),
    accentColor: Color(0xFF7A5830),
    softColor: Color(0xFFE6F0DC),
    borderColor: Color(0xFFE1CEAC),
    lineColor: Color(0xFFE9DCC4),
    patchColor: Color(0xFF6E8FB8),
    footerColor: Color(0xFF6F4E26),
    decorationIcon: Icons.landscape_rounded,
  ),
];

_NotebookStyleSpec _styleForKey(String? key) {
  return _notebookStyles.firstWhere(
    (style) => style.key == key,
    orElse: () => _notebookStyles.first,
  );
}

class _EmergencyPage extends StatelessWidget {
  const _EmergencyPage({required this.controller});

  final SleepAppController controller;

  @override
  Widget build(BuildContext context) {
    final latest = controller.latestEmergency;
    return _Page(
      controller: controller,
      children: <Widget>[
        _Panel(
          title: '选择现在的状态',
          subtitle: '',
          icon: Icons.healing_rounded,
          child: Column(
            children: NightEmergencyState.values
                .map(
                  (state) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ActionRow(
                      icon: _emergencyIcon(state),
                      title: state.label,
                      subtitle: '',
                      onTap: () async {
                        await controller.runNightEmergency(state);
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (latest != null)
          _Panel(
            title: '最近一次心声',
            subtitle: '',
            icon: Icons.history_rounded,
            child: _SwipeDeleteLatestEmergencyLog(
              onDelete: controller.deleteLatestEmergencyLog,
              child: _MiniRecord(
                title: latest.state.label,
                body: controller.formatStateLogTime(latest.createdAt),
                chips: const <String>[],
              ),
            ),
          ),
        _AiAssistPanel(controller: controller),
      ],
    );
  }
}

class _SoundPage extends StatelessWidget {
  const _SoundPage({required this.controller});

  final SleepAppController controller;

  @override
  Widget build(BuildContext context) {
    return _Page(
      controller: controller,
      children: <Widget>[
        _Panel(
          title: 'Your Sound',
          subtitle: '',
          // subtitle: '播放、搜索和管理今晚的声音。',
          icon: Icons.graphic_eq_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _CurrentSoundCard(controller: controller),
              const SizedBox(height: 16),
              const _SoundSectionTitle(
                icon: Icons.auto_awesome_motion_rounded,
                title: '声音素材',
              ),
              const SizedBox(height: 10),
              ...controller.cloudSoundMaterials.map(
                (track) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TrackTile(
                    track: track,
                    active: controller.isActiveTrack(track),
                    playing: controller.isPlaying,
                    onPlay: () => controller.toggleTrack(track),
                    onQueue: () => controller.addTrackToPlaylist(track),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _SoundSectionTitle(
                icon: Icons.search_rounded,
                title: '搜索音频',
              ),
              const SizedBox(height: 10),
              _OnlineAudioSearch(controller: controller),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _showPlaylistSheet(context, controller),
                  icon: const Icon(Icons.queue_music_rounded),
                  label: Text('播放列表 ${controller.playbackQueue.length}'),
                ),
              ),
            ],
          ),
        ),
        _Panel(
          title: '日记本',
          subtitle: '',
          icon: Icons.menu_book_rounded,
          trailing: IconButton(
            tooltip: '新建日记本',
            onPressed: () =>
                _showCreatePersonalSceneDialog(context, controller),
            icon: const Icon(Icons.add_rounded),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (controller.personalScenes.isEmpty)
                const _EmptyState(text: '还没有日记本。')
              else
                ...controller.personalScenes.map(
                  (scene) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SwipeDeleteNotebookScene(
                      scene: scene,
                      onTap: () => _showPersonalSceneNotebook(
                        context,
                        controller,
                        scene,
                      ),
                      onDelete: () => _confirmDeletePersonalScene(
                        context,
                        controller,
                        scene,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrentSoundCard extends StatelessWidget {
  const _CurrentSoundCard({required this.controller});

  final SleepAppController controller;

  @override
  Widget build(BuildContext context) {
    final track = controller.selectedSoundscape;
    final active = controller.isActiveTrack(track);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: Color(track.accentColor).withValues(alpha: 0.18),
            foregroundColor: Color(track.accentColor),
            child: Icon(
              active && controller.isPlaying
                  ? Icons.graphic_eq_rounded
                  : Icons.music_note_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: controller.toggleSelectedSoundscape,
            icon: Icon(
              active && controller.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
            label: Text(active && controller.isPlaying ? '暂停' : '播放'),
          ),
        ],
      ),
    );
  }
}

class _SoundSectionTitle extends StatelessWidget {
  const _SoundSectionTitle({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: AppTheme.accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (trailing != null) ...<Widget>[const Spacer(), trailing!],
      ],
    );
  }
}

class _NotebookSceneRow extends StatelessWidget {
  const _NotebookSceneRow({required this.scene, required this.onTap});

  final PersonalScene scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _styleForKey(scene.styleKey);
    return _ActionRow(
      icon: style.icon,
      title: scene.sceneName,
      subtitle:
          '${scene.textEntries.length} 篇日记 · ${scene.images.length} 张图片 · ${scene.audioFiles.length} 段音频',
      onTap: onTap,
    );
  }
}

class _SwipeDeleteNotebookScene extends StatefulWidget {
  const _SwipeDeleteNotebookScene({
    required this.scene,
    required this.onTap,
    required this.onDelete,
  });

  final PersonalScene scene;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_SwipeDeleteNotebookScene> createState() =>
      _SwipeDeleteNotebookSceneState();
}

class _SwipeDeleteNotebookSceneState extends State<_SwipeDeleteNotebookScene> {
  static const double _deleteWidth = 82;
  double _dragOffset = 0;

  bool get _revealed => _dragOffset <= -_deleteWidth / 2;

  void _settle() {
    setState(() {
      _dragOffset = _revealed ? -_deleteWidth : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset = (_dragOffset + details.delta.dx).clamp(
            -_deleteWidth,
            0,
          );
        });
      },
      onHorizontalDragEnd: (_) => _settle(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.centerRight,
          children: <Widget>[
            Positioned.fill(
              child: Container(
                alignment: Alignment.centerRight,
                color: AppTheme.accentWarm.withValues(alpha: 0.18),
                padding: const EdgeInsets.only(right: 10),
                child: IconButton.filledTonal(
                  tooltip: '删除日记本',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_dragOffset, 0, 0),
              child: _NotebookSceneRow(
                scene: widget.scene,
                onTap: widget.onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelinePage extends StatelessWidget {
  const _TimelinePage({required this.controller});

  final SleepAppController controller;

  @override
  Widget build(BuildContext context) {
    return _Page(
      controller: controller,
      children: <Widget>[
        _HeroPanel(
          eyebrow: '关系复盘',
          title: '先分清事实和想象',
          body: '',
          action: FilledButton.icon(
            onPressed: () => _showRelationshipEventDialog(context, controller),
            icon: const Icon(Icons.add_rounded),
            label: const Text('记录片段'),
          ),
        ),
        _Panel(
          title: '事件时间线',
          subtitle: '',
          icon: Icons.timeline_rounded,
          child: Column(
            children: controller.relationshipEvents.isEmpty
                ? const <Widget>[_EmptyState(text: '暂无关系事件。')]
                : controller.relationshipEvents
                      .map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SwipeDeleteRelationshipEvent(
                            event: event,
                            onDelete: () => controller.deleteRelationshipEvent(
                              event.eventId,
                            ),
                          ),
                        ),
                      )
                      .toList(),
          ),
        ),
      ],
    );
  }
}

class _SwipeDeleteRelationshipEvent extends StatefulWidget {
  const _SwipeDeleteRelationshipEvent({
    required this.event,
    required this.onDelete,
  });

  final RelationshipEvent event;
  final VoidCallback onDelete;

  @override
  State<_SwipeDeleteRelationshipEvent> createState() =>
      _SwipeDeleteRelationshipEventState();
}

class _SwipeDeleteRelationshipEventState
    extends State<_SwipeDeleteRelationshipEvent> {
  static const double _deleteWidth = 78;
  double _dragOffset = 0;

  bool get _revealed => _dragOffset <= -_deleteWidth / 2;

  void _settle() {
    setState(() {
      _dragOffset = _revealed ? -_deleteWidth : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset = (_dragOffset + details.delta.dx).clamp(
            -_deleteWidth,
            0,
          );
        });
      },
      onHorizontalDragEnd: (_) => _settle(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.centerRight,
          children: <Widget>[
            Positioned.fill(
              child: Container(
                alignment: Alignment.centerRight,
                color: AppTheme.accentWarm.withValues(alpha: 0.18),
                padding: const EdgeInsets.only(right: 10),
                child: IconButton.filledTonal(
                  tooltip: '删除事件',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_dragOffset, 0, 0),
              child: _MiniRecord(
                title: widget.event.eventType.label,
                body: widget.event.content,
                chips: <String>[
                  widget.event.emotion.label,
                  widget.event.factOrFantasy.label,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeDeleteLatestEmergencyLog extends StatefulWidget {
  const _SwipeDeleteLatestEmergencyLog({
    required this.child,
    required this.onDelete,
  });

  final Widget child;
  final Future<void> Function() onDelete;

  @override
  State<_SwipeDeleteLatestEmergencyLog> createState() =>
      _SwipeDeleteLatestEmergencyLogState();
}

class _SwipeDeleteLatestEmergencyLogState
    extends State<_SwipeDeleteLatestEmergencyLog> {
  static const double _deleteWidth = 78;
  double _dragOffset = 0;

  bool get _revealed => _dragOffset <= -_deleteWidth / 2;

  void _settle() {
    setState(() {
      _dragOffset = _revealed ? -_deleteWidth : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset = (_dragOffset + details.delta.dx).clamp(
            -_deleteWidth,
            0,
          );
        });
      },
      onHorizontalDragEnd: (_) => _settle(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.centerRight,
          children: <Widget>[
            Positioned.fill(
              child: Container(
                alignment: Alignment.centerRight,
                color: AppTheme.accentWarm.withValues(alpha: 0.18),
                padding: const EdgeInsets.only(right: 10),
                child: IconButton.filledTonal(
                  tooltip: '删除最近一次心声',
                  onPressed: () async {
                    await widget.onDelete();
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _dragOffset = 0;
                    });
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_dragOffset, 0, 0),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({required this.controller});

  final SleepAppController controller;

  @override
  Widget build(BuildContext context) {
    return _Page(
      controller: controller,
      children: <Widget>[
        _ProfileHeader(
          controller: controller,
          onSettings: () => _showSettingsPage(context, controller),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: _ValueCard(
                label: '恢复进度',
                value: '${controller.recoveryProgress.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ValueCard(
                label: '心声次数',
                value: controller.emergencyLogs.length.toString(),
              ),
            ),
          ],
        ),
        _Panel(
          title: '情绪阶段',
          subtitle: '',
          // subtitle: '用于调整心声和声音推荐语气。',
          icon: Icons.psychology_rounded,
          child: SegmentedButton<EmotionStage>(
            segments: EmotionStage.values
                .map(
                  (stage) => ButtonSegment<EmotionStage>(
                    value: stage,
                    label: Text(stage.label),
                  ),
                )
                .toList(),
            selected: <EmotionStage>{controller.account.emotionStage},
            onSelectionChanged: (selection) =>
                controller.setEmotionStage(selection.first),
          ),
        ),
        _Panel(
          title: '情绪小结',
          subtitle: '',
          // subtitle: '把最近的心声记录整理成一个可行动的小结。',
          icon: Icons.favorite_border_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  TextButton.icon(
                    onPressed: () =>
                        _showStateLibrarySheet(context, controller),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('状态库'),
                  ),
                  TextButton.icon(
                    onPressed: controller.isBusy
                        ? null
                        : controller.analyzeEmotionTrend,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('AI分析状态'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: controller.recoveryProgress / 100,
                minHeight: 10,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 12),
              _MiniRecord(
                title: '最近情绪',
                body: controller.emotionBrief,
                chips: controller.emotionActionChips,
              ),
              if (controller.emergencyStateCounts.values.any(
                (count) => count > 0,
              )) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.emergencyStateCounts.entries
                      .where((entry) => entry.value > 0)
                      .map(
                        (entry) =>
                            _Tag(text: '${entry.key.label} ${entry.value}次'),
                      )
                      .toList(),
                ),
              ],
              if (controller.emotionTrendAnalysis != null) ...<Widget>[
                const SizedBox(height: 12),
                _MiniRecord(
                  title: 'AI状态分析',
                  body: controller.emotionTrendAnalysis!,
                  chips: const <String>['状态库', '综合分析', '调整建议'],
                ),
              ],
            ],
          ),
        ),
        _Panel(
          title: '隐私与系统',
          subtitle: '',
          // subtitle: '管理提醒、访问控制和个人记录。',
          icon: Icons.privacy_tip_rounded,
          child: Column(
            children: <Widget>[
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: controller.profile.accessControlEnabled,
                onChanged: controller.setAccessControlEnabled,
                title: const Text('访问控制'),
                subtitle: const Text('开启后，进入 App 前需要验证身份'),
              ),
              const Divider(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: controller.schedule.reminderEnabled,
                onChanged: controller.setReminderEnabled,
                title: const Text('夜间提醒'),
                subtitle: Text('${controller.schedule.bedtimeLabel} 推送睡前提醒'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: controller.clearAccountData,
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: const Text('清空个人内容'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.controller, required this.onSettings});

  final SleepAppController controller;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final account = controller.account;
    final signature = account.signature?.trim().isNotEmpty == true
        ? account.signature!.trim()
        : '今晚也慢慢来。';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AccountAvatar(path: account.avatarPath, radius: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      account.nickname,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      signature,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: '设置',
                onPressed: onSettings,
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _ProfilePill(
                icon: Icons.psychology_rounded,
                label: account.emotionStage.label,
              ),
              const SizedBox(width: 8),
              _ProfilePill(
                icon: Icons.favorite_border_rounded,
                label: '${controller.emergencyLogs.length} 次心声',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.path, required this.radius});

  final String? path;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imagePath = path;
    final file = imagePath == null || imagePath.isEmpty
        ? null
        : File(imagePath);
    final hasImage = file != null && file.existsSync();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.accent.withValues(alpha: 0.18),
      backgroundImage: hasImage ? FileImage(file) : null,
      child: hasImage
          ? null
          : Icon(Icons.person_rounded, size: radius, color: AppTheme.accent),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppTheme.accent),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

Future<void> _showSettingsPage(
  BuildContext context,
  SleepAppController controller,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _SettingsPage(controller: controller),
    ),
  );
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage({required this.controller});

  final SleepAppController controller;

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  bool _albumPermission = true;
  bool _microphonePermission = true;
  bool _locationPermission = false;
  _AppThemeMode _themeMode = _AppThemeMode.dark;
  double _fontScale = 1.0;

  SleepAppController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final account = controller.account;
    final phoneBound = account.phone?.trim().isNotEmpty == true;
    final emailBound = account.email?.trim().isNotEmpty == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: <Widget>[
          _SettingsSection(
            title: '账户与个人信息',
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _AccountAvatar(path: account.avatarPath, radius: 24),
                title: Text(account.nickname),
                subtitle: Text(
                  account.signature?.trim().isNotEmpty == true
                      ? account.signature!.trim()
                      : '还没有签名',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _editProfile(context),
              ),
              _SettingsActionTile(
                icon: Icons.lock_outline_rounded,
                title: '更改密码',
                subtitle: account.passwordHint,
                onTap: () => _showSoftSnack(context, '密码修改功能已预留。'),
              ),
              _SettingsActionTile(
                icon: Icons.phone_iphone_rounded,
                title: phoneBound ? '解绑/更改手机' : '绑定手机',
                subtitle: phoneBound ? account.phone! : '未绑定',
                onTap: () => _editContact(context, isPhone: true),
              ),
              _SettingsActionTile(
                icon: Icons.alternate_email_rounded,
                title: emailBound ? '解绑/更改邮箱' : '绑定邮箱',
                subtitle: emailBound ? account.email! : '未绑定',
                onTap: () => _editContact(context, isPhone: false),
              ),
            ],
          ),
          _SettingsSection(
            title: '通知与提醒',
            children: <Widget>[
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: controller.schedule.reminderEnabled,
                onChanged: controller.setReminderEnabled,
                title: const Text('推送通知'),
                subtitle: Text('${controller.schedule.bedtimeLabel} 睡前提醒'),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _emailNotifications,
                onChanged: (value) =>
                    setState(() => _emailNotifications = value),
                title: const Text('邮件通知'),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _smsNotifications,
                onChanged: (value) => setState(() => _smsNotifications = value),
                title: const Text('短信通知'),
              ),
            ],
          ),
          _SettingsSection(
            title: '显示与界面',
            children: <Widget>[
              SegmentedButton<_AppThemeMode>(
                segments: const <ButtonSegment<_AppThemeMode>>[
                  ButtonSegment<_AppThemeMode>(
                    value: _AppThemeMode.light,
                    label: Text('亮色'),
                  ),
                  ButtonSegment<_AppThemeMode>(
                    value: _AppThemeMode.dark,
                    label: Text('暗色'),
                  ),
                ],
                selected: <_AppThemeMode>{_themeMode},
                onSelectionChanged: (selection) =>
                    setState(() => _themeMode = selection.first),
              ),
              const SizedBox(height: 12),
              Text('字体大小 ${(_fontScale * 100).round()}%'),
              Slider(
                value: _fontScale,
                min: 0.85,
                max: 1.25,
                divisions: 4,
                label: '${(_fontScale * 100).round()}%',
                onChanged: (value) => setState(() => _fontScale = value),
              ),
            ],
          ),
          _SettingsSection(
            title: '隐私与安全',
            children: <Widget>[
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: controller.profile.accessControlEnabled,
                onChanged: controller.setAccessControlEnabled,
                title: const Text('访问控制'),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _albumPermission,
                onChanged: (value) => setState(() => _albumPermission = value),
                title: const Text('相册权限'),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _microphonePermission,
                onChanged: (value) =>
                    setState(() => _microphonePermission = value),
                title: const Text('麦克风权限'),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _locationPermission,
                onChanged: (value) =>
                    setState(() => _locationPermission = value),
                title: const Text('位置权限'),
              ),
            ],
          ),
          _SettingsSection(
            title: '关于与帮助',
            children: <Widget>[
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline_rounded),
                title: Text('版本信息'),
                subtitle: Text('SkyDogs 0.1.0'),
              ),
              _SettingsActionTile(
                icon: Icons.system_update_alt_rounded,
                title: '更新检查',
                subtitle: '当前已是本地构建版本',
                onTap: () => _showSoftSnack(context, '当前已是最新版本。'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final account = controller.account;
    final nicknameController = TextEditingController(text: account.nickname);
    final signatureController = TextEditingController(
      text: account.signature ?? '',
    );
    var avatarPath = account.avatarPath;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('个人资料'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GestureDetector(
                  onTap: () async {
                    final image = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setDialogState(() => avatarPath = image.path);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: <Widget>[
                      _AccountAvatar(path: avatarPath, radius: 38),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.accent,
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nicknameController,
                  decoration: const InputDecoration(labelText: '昵称'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: signatureController,
                  decoration: const InputDecoration(labelText: '签名'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (shouldSave == true) {
      await controller.updateAccountProfile(
        nickname: nicknameController.text.trim().isEmpty
            ? account.nickname
            : nicknameController.text.trim(),
        signature: signatureController.text.trim(),
        avatarPath: avatarPath,
      );
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _editContact(
    BuildContext context, {
    required bool isPhone,
  }) async {
    final account = controller.account;
    final current = isPhone ? account.phone : account.email;
    final fieldController = TextEditingController(text: current ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPhone ? '绑定手机' : '绑定邮箱'),
        content: TextField(
          controller: fieldController,
          keyboardType: isPhone
              ? TextInputType.phone
              : TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: isPhone ? '输入手机号，留空表示解绑' : '输入邮箱，留空表示解绑',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(fieldController.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (value == null) {
      return;
    }
    final trimmed = value.trim();
    await controller.updateAccountProfile(
      phone: isPhone ? (trimmed.isEmpty ? null : trimmed) : account.phone,
      email: isPhone ? account.email : (trimmed.isEmpty ? null : trimmed),
      clearPhone: isPhone && trimmed.isEmpty,
      clearEmail: !isPhone && trimmed.isEmpty,
    );
    if (mounted) {
      setState(() {});
    }
  }
}

enum _AppThemeMode { light, dark }

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.controller, required this.children});

  final SleepAppController controller;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: <Widget>[
        ...children.map(
          (child) =>
              Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.action,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(eyebrow, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          if (body.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 18),
          action,
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: AppTheme.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    if (subtitle.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.active,
    required this.playing,
    required this.onPlay,
    this.onQueue,
    this.onRemove,
  });

  final MediaTrack track;
  final bool active;
  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback? onQueue;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.accent.withValues(alpha: 0.12)
            : AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? AppTheme.accent : AppTheme.outline),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: Color(track.accentColor),
            child: const Icon(Icons.music_note_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  track.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  track.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (onQueue != null)
                IconButton(
                  tooltip: '加入播放列表',
                  onPressed: onQueue,
                  icon: const Icon(Icons.playlist_add_rounded),
                ),
              if (onRemove != null)
                IconButton(
                  tooltip: '移出播放列表',
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
              FilledButton.tonal(
                onPressed: onPlay,
                child: Text(active && playing ? '暂停' : '播放'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showPlaylistSheet(BuildContext context, SleepAppController controller) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppTheme.surface,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) =>
                _PlaylistSheetContent(controller: controller),
          ),
        ),
      );
    },
  );
}

class _PlaylistSheetContent extends StatelessWidget {
  const _PlaylistSheetContent({required this.controller});

  final SleepAppController controller;

  @override
  Widget build(BuildContext context) {
    final queue = controller.playbackQueue;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SoundSectionTitle(
          icon: Icons.queue_music_rounded,
          title: '播放列表',
          trailing: queue.isEmpty
              ? null
              : TextButton.icon(
                  onPressed: controller.clearPlaylist,
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('清空'),
                ),
        ),
        const SizedBox(height: 12),
        _PlaylistModeControl(controller: controller),
        const SizedBox(height: 12),
        if (queue.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: _EmptyState(text: '还没有添加音频。'),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: queue.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final track = queue[index];
                return _TrackTile(
                  track: track,
                  active: controller.isActiveTrack(track),
                  playing: controller.isPlaying,
                  onPlay: () => controller.playQueueFrom(track),
                  onRemove: () => controller.removeTrackFromPlaylist(track),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PlaylistModeControl extends StatelessWidget {
  const _PlaylistModeControl({required this.controller});

  final SleepAppController controller;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PlaylistPlaybackMode>(
      showSelectedIcon: false,
      segments: const <ButtonSegment<PlaylistPlaybackMode>>[
        ButtonSegment<PlaylistPlaybackMode>(
          value: PlaylistPlaybackMode.sequence,
          icon: Icon(Icons.format_list_numbered_rounded),
          label: Text('顺序'),
        ),
        ButtonSegment<PlaylistPlaybackMode>(
          value: PlaylistPlaybackMode.repeat,
          icon: Icon(Icons.repeat_rounded),
          label: Text('循环'),
        ),
        ButtonSegment<PlaylistPlaybackMode>(
          value: PlaylistPlaybackMode.shuffle,
          icon: Icon(Icons.shuffle_rounded),
          label: Text('随机'),
        ),
      ],
      selected: <PlaylistPlaybackMode>{controller.playlistPlaybackMode},
      onSelectionChanged: (selection) {
        controller.setPlaylistPlaybackMode(selection.first);
      },
    );
  }
}

class _MiniRecord extends StatelessWidget {
  const _MiniRecord({
    required this.title,
    required this.body,
    required this.chips,
  });

  final String title;
  final String body;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          if (chips.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((chip) => _Tag(text: chip)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

void _showStateLibrarySheet(
  BuildContext context,
  SleepAppController controller,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppTheme.surface,
    builder: (context) {
      final logs = controller.emergencyLogs;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _SoundSectionTitle(
                icon: Icons.inventory_2_outlined,
                title: '状态库',
              ),
              const SizedBox(height: 12),
              if (logs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: _EmptyState(text: '还没有状态记录。'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: logs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _MiniRecord(
                        title: log.state.label,
                        body: controller.formatStateLogTime(log.createdAt),
                        chips: const <String>[],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppTheme.background,
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _OnlineAudioSearch extends StatefulWidget {
  const _OnlineAudioSearch({required this.controller});

  final SleepAppController controller;

  @override
  State<_OnlineAudioSearch> createState() => _OnlineAudioSearchState();
}

class _OnlineAudioSearchState extends State<_OnlineAudioSearch> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(
      text: widget.controller.onlineAudioQuery,
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _queryController,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: '试试 rain、ocean、sleep、ambient',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onSubmitted: controller.searchOnlineAudio,
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: controller.searchingOnlineAudio
                  ? null
                  : () => controller.searchOnlineAudio(_queryController.text),
              child: controller.searchingOnlineAudio
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('搜索'),
            ),
          ],
        ),
        if (controller.onlineSearchResults.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          ...controller.onlineSearchResults.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SearchResultTile(
                item: item,
                selected: _isPlayingItem(controller, item),
                onTap: () => _playSearchResult(controller, item),
                onQueue: item.files.isEmpty
                    ? null
                    : () => controller.addSearchResultToPlaylist(item),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: controller.searchingOnlineAudio
                  ? null
                  : controller.loadMoreOnlineAudio,
              icon: const Icon(Icons.expand_more_rounded),
              label: Text('加载第 ${controller.onlineAudioPage + 1} 页'),
            ),
          ),
        ],
      ],
    );
  }

  bool _isPlayingItem(SleepAppController controller, SearchResultItem item) {
    if (item.files.isEmpty) {
      return false;
    }
    final track = controller.trackFromAudioFile(item.files.first);
    return controller.isActiveTrack(track);
  }

  Future<void> _playSearchResult(
    SleepAppController controller,
    SearchResultItem item,
  ) async {
    if (item.files.isEmpty) {
      await controller.selectOnlineSearchResult(item);
      if (controller.selectedAudioFiles.isEmpty) {
        return;
      }
      await controller.playOnlineAudioFile(controller.selectedAudioFiles.first);
      return;
    }
    await controller.playOnlineAudioFile(item.files.first);
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onQueue,
  });

  final SearchResultItem item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onQueue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.accent.withValues(alpha: 0.12)
            : AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppTheme.accent : AppTheme.outline,
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: selected ? AppTheme.accent : AppTheme.accentWarm,
            child: Icon(
              selected ? Icons.check_circle_rounded : Icons.archive_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.creator.isEmpty ? item.identifier : item.creator,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '加入播放列表',
            onPressed: onQueue,
            icon: const Icon(Icons.playlist_add_rounded),
          ),
        ],
      ),
    );
  }
}

class _PersonalAudioBar extends StatelessWidget {
  const _PersonalAudioBar({
    required this.controller,
    required this.scene,
    required this.file,
  });

  final SleepAppController controller;
  final PersonalScene scene;
  final PersonalAudioFile file;

  @override
  Widget build(BuildContext context) {
    final path = file.localPath ?? '';
    final trackId =
        'personal_${('${scene.id}_${file.fileName}').replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}';
    final active =
        path.isNotEmpty &&
        controller.isActiveTrack(
          MediaTrack(
            id: trackId,
            title: file.fileName,
            subtitle: scene.sceneName,
            kind: TrackKind.soundscape,
            category: '个人数据库',
            accentColor: 0xFF9B8ED8,
            cachedFilePath: path,
            builtIn: false,
          ),
        );
    final progress = active && controller.duration.inMilliseconds > 0
        ? controller.position.inMilliseconds /
              controller.duration.inMilliseconds
        : 0.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.playPersonalAudio(scene, file),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0F8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFC7D3E4)),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                active && controller.isPlaying
                    ? Icons.pause_circle_rounded
                    : Icons.play_circle_rounded,
                color: const Color(0xFF426895),
                size: 40,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      file.fileName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress.clamp(0, 1)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                active && controller.isPlaying
                    ? Icons.volume_up_rounded
                    : Icons.volume_mute_rounded,
                color: const Color(0xFF426895),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiAssistPanel extends StatefulWidget {
  const _AiAssistPanel({required this.controller});

  final SleepAppController controller;

  @override
  State<_AiAssistPanel> createState() => _AiAssistPanelState();
}

class _AiAssistPanelState extends State<_AiAssistPanel> {
  final _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return _Panel(
      title: '陪伴对话',
      subtitle: '',
      icon: Icons.mode_comment_outlined,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: '清空对话',
            onPressed: controller.aiChatMessages.isEmpty
                ? null
                : controller.clearAiChatMessages,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (controller.aiChatMessages.isNotEmpty)
            ...controller.aiChatMessages.map(
              (message) => _AiChatBubble(message: message),
            ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _chatController,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: '继续和 AI 说说你的感受...',
                    prefixIcon: Icon(Icons.mode_comment_outlined),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: controller.isBusy ? null : _sendMessage,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text;
    if (text.trim().isEmpty) {
      return;
    }
    _chatController.clear();
    await widget.controller.sendAiChatMessage(text);
  }
}

class _AiChatBubble extends StatelessWidget {
  const _AiChatBubble({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.fromUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.fromUser ? AppTheme.accent : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: message.fromUser ? AppTheme.accent : AppTheme.outline,
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: message.fromUser ? Colors.white : AppTheme.textPrimary,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

Future<void> _showCreatePersonalSceneDialog(
  BuildContext context,
  SleepAppController controller,
) async {
  final nameController = TextEditingController();
  var selectedStyle = _notebookStyles.first;
  final name = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('新建日记本'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(hintText: '例如：雨夜睡眠、别回头'),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _notebookStyles.map((style) {
                  return ChoiceChip(
                    selected: selectedStyle.key == style.key,
                    label: Text(style.name),
                    avatar: Icon(style.icon, size: 18),
                    selectedColor: style.softColor,
                    onSelected: (_) =>
                        setDialogState(() => selectedStyle = style),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(nameController.text),
            child: const Text('创建'),
          ),
        ],
      ),
    ),
  );
  if (name != null && name.trim().isNotEmpty) {
    await controller.createPersonalScene(
      name,
      styleKey: selectedStyle.key,
      moodLabel: selectedStyle.mood,
    );
  }
}

Future<void> _confirmDeletePersonalScene(
  BuildContext context,
  SleepAppController controller,
  PersonalScene scene,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除日记本'),
      content: Text('确定删除《${scene.sceneName}》吗？里面的内容会从个人数据库移除。'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.deletePersonalScene(scene.id);
    if (context.mounted) {
      _showSoftSnack(context, '日记本已删除');
    }
  }
}

Future<void> _showPersonalSceneNotebook(
  BuildContext context,
  SleepAppController controller,
  PersonalScene scene,
) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => _NotebookPage(sceneId: scene.id, initialScene: scene),
    ),
  );
}

class _NotebookPage extends StatefulWidget {
  const _NotebookPage({required this.sceneId, required this.initialScene});

  final String sceneId;
  final PersonalScene initialScene;

  @override
  State<_NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<_NotebookPage> {
  late final TextEditingController _textController;
  late final TextEditingController _weekdayController;
  late final TextEditingController _moodController;
  bool _seeded = false;
  late DateTime _entryDate;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _weekdayController = TextEditingController();
    _moodController = TextEditingController();
    _entryDate = widget.initialScene.entryDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _textController.dispose();
    _weekdayController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepAppController>(
      builder: (context, controller, _) {
        final scene = controller.personalScenes.firstWhere(
          (item) => item.id == widget.sceneId,
          orElse: () => widget.initialScene,
        );
        if (!_seeded) {
          _textController.text = scene.textEntries.isEmpty
              ? ''
              : scene.textEntries.first.content;
          _entryDate = scene.entryDate ?? DateTime.now();
          _weekdayController.text =
              scene.weekdayLabel ?? _weekdayLabel(_entryDate.weekday);
          _moodController.text =
              scene.moodLabel ?? _styleForKey(scene.styleKey).mood;
          _seeded = true;
        }

        final style = _styleForKey(scene.styleKey);
        return Scaffold(
          backgroundColor: style.pageColor,
          body: SafeArea(
            child: Stack(
              children: <Widget>[
                Positioned(left: -26, bottom: -18, child: _MoonPatch()),
                Column(
                  children: <Widget>[
                    _NotebookTopBar(
                      onBack: () => Navigator.of(context).pop(),
                      onSave: () => _saveNotebook(controller, scene),
                      onDelete: () => _deleteNotebook(controller, scene),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                        child: _NotebookPaper(
                          controller: controller,
                          scene: scene,
                          entryDate: _entryDate,
                          weekdayController: _weekdayController,
                          moodController: _moodController,
                          textController: _textController,
                          onEditDate: _editDate,
                          onEditWeekday: _editWeekday,
                          onEditMood: _editMood,
                          onAddImage: () => _pickPersonalImagesForScene(
                            context,
                            controller,
                            scene,
                          ),
                          onAddAudio: () => _pickPersonalAudioForScene(
                            context,
                            controller,
                            scene,
                          ),
                          onSaveText: () => _saveNotebook(controller, scene),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: style.patchColor,
            foregroundColor: Colors.white,
            onPressed: () => _saveNotebook(controller, scene),
            child: const Icon(Icons.draw_rounded),
          ),
        );
      },
    );
  }

  Future<void> _saveNotebook(
    SleepAppController controller,
    PersonalScene scene,
  ) async {
    final text = _textController.text.trim();
    if (scene.textEntries.isEmpty) {
      await controller.addPersonalTextToScene(scene.id, text);
    } else {
      await controller.updatePersonalTextInScene(
        sceneId: scene.id,
        index: 0,
        content: text,
      );
    }
    await controller.updatePersonalSceneMeta(
      sceneId: scene.id,
      entryDate: _entryDate,
      weekdayLabel: _weekdayController.text,
      moodLabel: _moodController.text,
    );
    if (mounted) {
      _showSoftSnack(context, '已保存');
    }
  }

  Future<void> _editDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _entryDate = picked;
      _weekdayController.text = _weekdayLabel(picked.weekday);
    });
  }

  Future<void> _editWeekday() async {
    final result = await _showNotebookFieldDialog(
      context: context,
      title: '编辑星期',
      initialValue: _weekdayController.text,
      hintText: '例如：星期日',
    );
    if (result != null) {
      setState(() => _weekdayController.text = result);
    }
  }

  Future<void> _editMood() async {
    final result = await _showNotebookFieldDialog(
      context: context,
      title: '编辑心情标签',
      initialValue: _moodController.text,
      hintText: '例如：平静 · 放松',
    );
    if (result != null) {
      setState(() => _moodController.text = result);
    }
  }

  Future<void> _deleteNotebook(
    SleepAppController controller,
    PersonalScene scene,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日记本'),
        content: Text('确定删除《${scene.sceneName}》吗？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await controller.deletePersonalScene(scene.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    _showSoftSnack(context, '日记本已删除');
  }
}

class _NotebookTopBar extends StatelessWidget {
  const _NotebookTopBar({
    required this.onBack,
    required this.onSave,
    required this.onDelete,
  });

  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 18, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: '返回',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFF6E461C),
          ),
          const Spacer(),
          Text(
            '日记本',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF4C321D),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined),
            label: const Text('保存'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF79511F),
            ),
          ),
          IconButton(
            tooltip: '删除日记本',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFF8A5D2A),
          ),
        ],
      ),
    );
  }
}

class _NotebookPaper extends StatelessWidget {
  const _NotebookPaper({
    required this.controller,
    required this.scene,
    required this.entryDate,
    required this.weekdayController,
    required this.moodController,
    required this.textController,
    required this.onEditDate,
    required this.onEditWeekday,
    required this.onEditMood,
    required this.onAddImage,
    required this.onAddAudio,
    required this.onSaveText,
  });

  final SleepAppController controller;
  final PersonalScene scene;
  final DateTime entryDate;
  final TextEditingController weekdayController;
  final TextEditingController moodController;
  final TextEditingController textController;
  final VoidCallback onEditDate;
  final VoidCallback onEditWeekday;
  final VoidCallback onEditMood;
  final VoidCallback onAddImage;
  final VoidCallback onAddAudio;
  final VoidCallback onSaveText;

  @override
  Widget build(BuildContext context) {
    final style = _styleForKey(scene.styleKey);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(left: -25, top: 35, bottom: 55, child: _NotebookRings()),
        Container(
          margin: const EdgeInsets.only(left: 12),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
          decoration: BoxDecoration(
            color: style.paperColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: style.accentColor.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(5, 8),
              ),
            ],
            border: Border.all(color: style.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Icon(Icons.calendar_month_outlined, color: style.footerColor),
                  _NotebookMetaChip(
                    text:
                        '${entryDate.year}年${entryDate.month}月${entryDate.day}日',
                    onTap: onEditDate,
                  ),
                  _NotebookMetaChip(
                    text: weekdayController.text,
                    onTap: onEditWeekday,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _MoodChip(text: moodController.text, onTap: onEditMood),
              const SizedBox(height: 22),
              _LinedTextEditor(
                controller: textController,
                onSaveText: onSaveText,
              ),
              const SizedBox(height: 24),
              _NotebookSectionHeader(
                icon: Icons.image_outlined,
                title: '照片',
                actionLabel: '添加图片',
                onAction: onAddImage,
              ),
              const SizedBox(height: 12),
              _PhotoStrip(images: scene.images),
              const SizedBox(height: 22),
              _NotebookSectionHeader(
                icon: Icons.music_note_rounded,
                title: '语音记录',
                actionLabel: '添加音频',
                onAction: onAddAudio,
              ),
              const SizedBox(height: 12),
              if (scene.audioFiles.isEmpty)
                const _EmptyState(text: '还没有音频。')
              else
                ...scene.audioFiles.map(
                  (file) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PersonalAudioBar(
                      controller: controller,
                      scene: scene,
                      file: file,
                    ),
                  ),
                ),
              const SizedBox(height: 26),
              Center(
                child: Text(
                  '记录 · 倾听 · 疗愈 ♡',
                  style: TextStyle(color: style.footerColor, letterSpacing: 0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotebookMetaChip extends StatelessWidget {
  const _NotebookMetaChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: const Color(0xFF4C321D)),
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFDCEDE3),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x223B5F4A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.sentiment_satisfied_alt_rounded,
              size: 20,
              color: Color(0xFF315E4A),
            ),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Color(0xFF315E4A))),
          ],
        ),
      ),
    );
  }
}

class _LinedTextEditor extends StatelessWidget {
  const _LinedTextEditor({required this.controller, required this.onSaveText});

  final TextEditingController controller;
  final VoidCallback onSaveText;

  @override
  Widget build(BuildContext context) {
    const fontSize = 17.0;
    const lineHeight = 1.78;
    const topPadding = 18.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, topPadding, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0C9A9)),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: _NotebookLinePainter(
                fontSize: fontSize,
                lineHeight: lineHeight,
                topPadding: topPadding,
              ),
            ),
          ),
          TextField(
            controller: controller,
            minLines: 7,
            maxLines: 12,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(
              fontSize: fontSize,
              height: lineHeight,
              color: Color(0xFF3F2D1F),
            ),
            decoration: const InputDecoration(
              hintText: '点击输入，记录你的心情...',
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.only(right: 44),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton(
              tooltip: '保存文字',
              onPressed: onSaveText,
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF8A5D2A)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookLinePainter extends CustomPainter {
  const _NotebookLinePainter({
    required this.fontSize,
    required this.lineHeight,
    required this.topPadding,
  });

  final double fontSize;
  final double lineHeight;
  final double topPadding;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8DBC7)
      ..strokeWidth = 1;
    final step = fontSize * lineHeight;
    for (double y = topPadding + step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NotebookSectionHeader extends StatelessWidget {
  const _NotebookSectionHeader({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: const Color(0xFF6E461C)),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF4C321D),
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add_rounded),
          label: Text(actionLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF79511F),
            side: const BorderSide(color: Color(0xFFD1B58E)),
          ),
        ),
      ],
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.images});

  final List<PersonalImageEntry> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const _EmptyState(text: '还没有图片。');
    }
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final image = images[index];
          final path = image.localPath ?? image.annotations;
          return Transform.rotate(
            angle: index.isEven ? -0.035 : 0.025,
            child: Container(
              width: 112,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x338A5F2A),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: path.isNotEmpty
                  ? Image.file(File(path), fit: BoxFit.cover)
                  : Center(child: Text(image.fileName)),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemCount: images.length,
      ),
    );
  }
}

class _NotebookRings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List<Widget>.generate(
        7,
        (_) => Container(
          width: 34,
          height: 12,
          margin: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF8B6A3C), width: 3),
          ),
        ),
      ),
    );
  }
}

class _MoonPatch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 90,
      decoration: const BoxDecoration(
        color: Color(0xFF7892B0),
        borderRadius: BorderRadius.only(topRight: Radius.circular(80)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.nightlight_round,
        color: Color(0xFFFFE59D),
        size: 42,
      ),
    );
  }
}

Future<String?> _showNotebookFieldDialog({
  required BuildContext context,
  required String title,
  required String initialValue,
  required String hintText,
}) async {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hintText),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}

Future<void> _pickPersonalAudioForScene(
  BuildContext context,
  SleepAppController controller,
  PersonalScene scene,
) async {
  final source = await showModalBottomSheet<_AudioAddSource>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppTheme.surface,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.folder_open_rounded),
              title: const Text('本地音频'),
              onTap: () => Navigator.of(context).pop(_AudioAddSource.localFile),
            ),
            ListTile(
              leading: const Icon(Icons.mic_rounded),
              title: const Text('直接录音'),
              onTap: () => Navigator.of(context).pop(_AudioAddSource.recording),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || source == null) {
    return;
  }
  switch (source) {
    case _AudioAddSource.localFile:
      await _pickLocalAudioForScene(context, controller, scene);
    case _AudioAddSource.recording:
      await _recordPersonalAudioForScene(context, controller, scene);
  }
}

enum _AudioAddSource { localFile, recording }

Future<void> _pickLocalAudioForScene(
  BuildContext context,
  SleepAppController controller,
  PersonalScene scene,
) async {
  const channel = MethodChannel('skydogs/media_picker');
  final result = await channel.invokeMethod<List<dynamic>>('pickAudio');
  if (result == null || result.isEmpty) {
    return;
  }
  for (final item in result) {
    final mapped = Map<String, dynamic>.from(item as Map);
    final path = mapped['uri'] as String?;
    if (path == null || path.isEmpty) {
      continue;
    }
    await controller.addPersonalAudioToScene(
      sceneId: scene.id,
      fileName: mapped['name'] as String? ?? 'audio',
      fileType: mapped['mimeType'] as String? ?? 'audio/*',
      duration: 0,
      localPath: path,
    );
  }
}

Future<void> _recordPersonalAudioForScene(
  BuildContext context,
  SleepAppController controller,
  PersonalScene scene,
) async {
  const channel = MethodChannel('skydogs/media_picker');
  try {
    await channel.invokeMapMethod<String, dynamic>('startRecording');
  } on PlatformException catch (error) {
    if (context.mounted) {
      _showSoftSnack(context, '无法开始录音：${error.message ?? error.code}');
    }
    return;
  }
  if (!context.mounted) {
    await channel.invokeMethod<void>('cancelRecording');
    return;
  }

  final shouldSave = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('正在录音'),
      content: const Row(
        children: <Widget>[
          Icon(Icons.mic_rounded),
          SizedBox(width: 12),
          Expanded(child: Text('说完后点击保存录音。')),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('保存录音'),
        ),
      ],
    ),
  );

  if (shouldSave != true) {
    await channel.invokeMethod<void>('cancelRecording');
    return;
  }

  try {
    final result = await channel.invokeMapMethod<String, dynamic>(
      'stopRecording',
    );
    final path = result?['path'] as String?;
    if (path == null || path.isEmpty) {
      return;
    }
    final durationMs = result?['durationMs'] as int? ?? 0;
    await controller.addPersonalAudioToScene(
      sceneId: scene.id,
      fileName: result?['name'] as String? ?? '录音.m4a',
      fileType: result?['mimeType'] as String? ?? 'audio/mp4',
      duration: (durationMs / 1000).round(),
      localPath: path,
    );
  } on PlatformException catch (error) {
    if (context.mounted) {
      _showSoftSnack(context, '保存录音失败：${error.message ?? error.code}');
    }
  }
}

Future<void> _pickPersonalImagesForScene(
  BuildContext context,
  SleepAppController controller,
  PersonalScene scene,
) async {
  final picker = ImagePicker();
  final images = await picker.pickMultiImage();
  for (final image in images) {
    await controller.addPersonalImageToScene(
      sceneId: scene.id,
      fileName: image.name,
      annotations: image.path,
      localPath: image.path,
    );
  }
}

Future<void> _showRelationshipEventDialog(
  BuildContext context,
  SleepAppController controller,
) async {
  final contentController = TextEditingController();
  var type = RelationshipEventType.repeated;
  var emotion = RelationshipEmotion.sad;
  var factOrFantasy = FactOrFantasy.fantasy;

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('记录关系片段'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<RelationshipEventType>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: '事件类型'),
                    items: RelationshipEventType.values
                        .map(
                          (item) => DropdownMenuItem<RelationshipEventType>(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => type = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RelationshipEmotion>(
                    initialValue: emotion,
                    decoration: const InputDecoration(labelText: '情绪'),
                    items: RelationshipEmotion.values
                        .map(
                          (item) => DropdownMenuItem<RelationshipEmotion>(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => emotion = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<FactOrFantasy>(
                    segments: FactOrFantasy.values
                        .map(
                          (item) => ButtonSegment<FactOrFantasy>(
                            value: item,
                            label: Text(item.label),
                          ),
                        )
                        .toList(),
                    selected: <FactOrFantasy>{factOrFantasy},
                    onSelectionChanged: (selection) {
                      setDialogState(() => factOrFantasy = selection.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    enableSuggestions: true,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: '内容',
                      hintText: '写下发生了什么，或你脑子里反复出现的片段',
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    },
  );
  final content = contentController.text.trim();
  if (shouldSave == true && content.isNotEmpty) {
    await controller.addRelationshipEvent(
      type: type,
      emotion: emotion,
      factOrFantasy: factOrFantasy,
      content: content,
    );
  }
}

IconData _emergencyIcon(NightEmergencyState state) {
  switch (state) {
    case NightEmergencyState.wantToContact:
      return Icons.chat_bubble_outline_rounded;
    case NightEmergencyState.cannotSleep:
      return Icons.bedtime_off_rounded;
    case NightEmergencyState.startThinkingAgain:
      return Icons.psychology_alt_rounded;
    case NightEmergencyState.furious:
      return Icons.local_fire_department_rounded;
    case NightEmergencyState.wronged:
      return Icons.water_drop_outlined;
    case NightEmergencyState.missThem:
      return Icons.favorite_border_rounded;
    case NightEmergencyState.selfBlame:
      return Icons.replay_circle_filled_rounded;
    case NightEmergencyState.panic:
      return Icons.monitor_heart_outlined;
    case NightEmergencyState.numb:
      return Icons.blur_on_rounded;
  }
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
  return labels[weekday] ?? '';
}

void _showSoftSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(36, 0, 36, 26),
      backgroundColor: const Color(0xFFF7F1E3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFD7B98A)),
      ),
      content: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, color: Color(0xFF6A8E5F)),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF6B4B23),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
