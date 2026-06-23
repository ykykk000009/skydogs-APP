import '../models/media_track.dart';

class SampleCatalog {
  static List<MediaTrack> seedTracks() {
    const musicLibraryUrl = 'https://115.29.232.99/music-library';
    return const <MediaTrack>[
      MediaTrack(
        id: 'rain_loop',
        title: '屋檐雨声',
        subtitle: '细密雨点与低频底噪，适合快速放松。',
        kind: TrackKind.soundscape,
        category: '自然音',
        accentColor: 0xFF4F7FA4,
        remoteUrl: '$musicLibraryUrl/rain_loop.mp3',
        builtIn: false,
        loop: true,
      ),
      MediaTrack(
        id: 'ocean_drift',
        title: '海浪漂浮',
        subtitle: '缓慢起伏的海浪声，适合配合呼吸。',
        kind: TrackKind.soundscape,
        category: '自然音',
        accentColor: 0xFF2A8B92,
        remoteUrl: '$musicLibraryUrl/ocean_drift.mp3',
        builtIn: false,
        loop: true,
      ),
      MediaTrack(
        id: 'forest_night',
        title: '林间夜色',
        subtitle: '轻柔连续的林间夜声，减少环境空洞感。',
        kind: TrackKind.soundscape,
        category: '助眠音',
        accentColor: 0xFF557B4A,
        remoteUrl: '$musicLibraryUrl/forest_night.wav',
        builtIn: false,
        loop: true,
      ),
      MediaTrack(
        id: 'brown_noise',
        title: '深棕噪声',
        subtitle: '厚重的连续底噪，适合遮蔽外界干扰。',
        kind: TrackKind.soundscape,
        category: '白噪音',
        accentColor: 0xFF8A6B57,
        remoteUrl: '$musicLibraryUrl/brown_noise.mp3',
        builtIn: false,
        loop: true,
      ),
      MediaTrack(
        id: 'breath_reset',
        title: '4 分钟呼吸重置',
        subtitle: '吸气、停顿、呼气的温和引导。',
        kind: TrackKind.meditation,
        category: '冥想',
        accentColor: 0xFF7C9B6D,
        assetPath: 'assets/audio/meditation/breath_reset.wav',
        builtIn: true,
        loop: false,
        script: '吸气四拍，停留一拍，呼气六拍，让肩膀慢慢放松。',
      ),
      MediaTrack(
        id: 'body_scan',
        title: '身体扫描',
        subtitle: '从额头到脚尖逐段放松，更适合入睡前收尾。',
        kind: TrackKind.meditation,
        category: '冥想',
        accentColor: 0xFFB2865B,
        assetPath: 'assets/audio/meditation/body_scan.wav',
        builtIn: true,
        loop: false,
        script: '把注意力放到额头、下颌、肩膀，再慢慢下移到胸口和腹部。',
      ),
    ];
  }
}
