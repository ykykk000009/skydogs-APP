# Audio backend

Online audio search now uses this flow:

```text
Flutter App
  -> GET /api/audio/search
  -> backend requests Internet Archive and Jamendo
  -> backend normalizes results
  -> Flutter plays audioUrl/url
```

Start the backend:

```powershell
E:\APPs\flutter\bin\cache\dart-sdk\bin\dart.exe run server\audio_backend.dart
```

Production backend URL:

```text
https://skydogs.top
```

Health check:

```text
GET https://skydogs.top/health
GET https://skydogs.top/api/health
```

Optional Jamendo support needs a Jamendo client id:

```powershell
$env:JAMENDO_CLIENT_ID="your_jamendo_client_id"
E:\APPs\flutter\bin\cache\dart-sdk\bin\dart.exe run server\audio_backend.dart
```

The Flutter app defaults to the production HTTPS backend. To override it for local debugging:

```powershell
E:\APPs\flutter\bin\cache\dart-sdk\bin\dart.exe E:\APPs\flutter\bin\cache\flutter_tools.snapshot run --dart-define=AUDIO_BACKEND_URL=http://10.0.2.2:8787
```

For a real Android phone on local debugging, replace `10.0.2.2` with the computer LAN IP.

## AI backend

AI assist uses the same backend process:

```text
Flutter App
  -> POST /api/ai/assist or /api/chat
  -> backend calls SiliconFlow first
  -> if SiliconFlow is unavailable, backend calls OpenAI
  -> backend returns safe app-facing JSON
```

Do not put model keys in Flutter or commit them to the repository. Set them only in the backend terminal.

Preferred SiliconFlow setup:

```powershell
$env:SILICONFLOW_API_KEY="your_siliconflow_key"
$env:SILICONFLOW_BASE_URL="https://api.siliconflow.cn/v1"
$env:SILICONFLOW_MODELS="deepseek-ai/DeepSeek-V4-Flash,Pro/moonshotai/Kimi-K2.6,Qwen/Qwen2.5-7B-Instruct"
E:\APPs\flutter\bin\cache\dart-sdk\bin\dart.exe run server\audio_backend.dart
```

Optional OpenAI fallback:

```powershell
$env:OPENAI_API_KEY="your_openai_key"
$env:OPENAI_MODEL="gpt-4.1-mini"
E:\APPs\flutter\bin\cache\dart-sdk\bin\dart.exe run server\audio_backend.dart
```

`SILICONFLOW_MODELS` is tried from left to right. You can also set a single
`SILICONFLOW_MODEL` if you only want one model.
