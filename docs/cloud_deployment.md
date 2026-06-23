# Skydogs cloud deployment

Domain:

```text
skydogs.top -> 115.29.232.99
```

The Flutter app currently defaults to:

```text
http://115.29.232.99:8787
```

Required server behavior:

```text
http://115.29.232.99:8787/health           -> Dart backend /health
http://115.29.232.99:8787/api/audio/search -> Dart backend /api/audio/search
http://115.29.232.99:8787/api/chat         -> Dart backend /api/chat
```

Recommended setup:

1. Run the Dart backend on `127.0.0.1:8787`.
2. Put `server/.env` on the server with the SiliconFlow and OpenAI keys.
3. Use Nginx to terminate HTTPS and reverse proxy to `127.0.0.1:8787`.
4. Keep port `8787` closed to the public internet; expose only `80` and `443`.
5. Verify:

```bash
curl -i http://115.29.232.99:8787/health
curl -i "http://115.29.232.99:8787/api/audio/search?q=rain&page=1&limit=3"
```

Templates:

```text
server/deploy/skydogs.nginx.conf
server/deploy/skydogs-backend.service
```
