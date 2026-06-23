package com.skydogs.skydogs

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "skydogs/media_picker"
    private val pickAudioRequest = 4102
    private val recordAudioPermissionRequest = 4103
    private var pendingPickResult: MethodChannel.Result? = null
    private var pendingRecordPermissionResult: MethodChannel.Result? = null
    private var recorder: MediaRecorder? = null
    private var recordingFile: File? = null
    private var recordingStartedAt: Long = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickAudio" -> pickAudio(result)
                    "startRecording" -> startRecording(result)
                    "stopRecording" -> stopRecording(result)
                    "cancelRecording" -> cancelRecording(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun pickAudio(result: MethodChannel.Result) {
        if (pendingPickResult != null) {
            result.error("busy", "Audio picker is already open.", null)
            return
        }
        pendingPickResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        startActivityForResult(intent, pickAudioRequest)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickAudioRequest) {
            return
        }
        val result = pendingPickResult ?: return
        pendingPickResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<Map<String, String>>())
            return
        }

        val uris = mutableListOf<Uri>()
        val clipData = data.clipData
        if (clipData != null) {
            for (index in 0 until clipData.itemCount) {
                uris.add(clipData.getItemAt(index).uri)
            }
        } else {
            data.data?.let { uris.add(it) }
        }

        val items = uris.map { uri ->
            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            } catch (_: SecurityException) {
            }
            mapOf(
                "uri" to uri.toString(),
                "name" to displayName(uri),
                "mimeType" to (contentResolver.getType(uri) ?: "audio/*")
            )
        }
        result.success(items)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != recordAudioPermissionRequest) {
            return
        }
        val result = pendingRecordPermissionResult ?: return
        pendingRecordPermissionResult = null
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        if (granted) {
            startRecording(result)
        } else {
            result.error("permission_denied", "Microphone permission was denied.", null)
        }
    }

    private fun startRecording(result: MethodChannel.Result) {
        if (recorder != null) {
            result.error("busy", "Recording is already active.", null)
            return
        }
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            pendingRecordPermissionResult = result
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                recordAudioPermissionRequest
            )
            return
        }

        try {
            val directory = File(getExternalFilesDir(null), "recordings")
            if (!directory.exists()) {
                directory.mkdirs()
            }
            val file = File(directory, "skydogs_recording_${System.currentTimeMillis()}.m4a")
            val mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }
            mediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC)
            mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            mediaRecorder.setAudioEncodingBitRate(128000)
            mediaRecorder.setAudioSamplingRate(44100)
            mediaRecorder.setOutputFile(file.absolutePath)
            mediaRecorder.prepare()
            mediaRecorder.start()
            recorder = mediaRecorder
            recordingFile = file
            recordingStartedAt = System.currentTimeMillis()
            result.success(
                mapOf(
                    "path" to file.absolutePath,
                    "name" to file.name,
                    "mimeType" to "audio/mp4"
                )
            )
        } catch (error: Exception) {
            cleanupRecorder(deleteFile = true)
            result.error("record_start_failed", error.message, null)
        }
    }

    private fun stopRecording(result: MethodChannel.Result) {
        val file = recordingFile
        val mediaRecorder = recorder
        if (file == null || mediaRecorder == null) {
            result.error("not_recording", "No recording is active.", null)
            return
        }
        val durationMs = (System.currentTimeMillis() - recordingStartedAt).coerceAtLeast(0L)
        try {
            mediaRecorder.stop()
            cleanupRecorder(deleteFile = false)
            result.success(
                mapOf(
                    "path" to file.absolutePath,
                    "name" to file.name,
                    "mimeType" to "audio/mp4",
                    "durationMs" to durationMs
                )
            )
        } catch (error: Exception) {
            cleanupRecorder(deleteFile = true)
            result.error("record_stop_failed", error.message, null)
        }
    }

    private fun cancelRecording(result: MethodChannel.Result) {
        cleanupRecorder(deleteFile = true)
        result.success(null)
    }

    private fun cleanupRecorder(deleteFile: Boolean) {
        try {
            recorder?.reset()
            recorder?.release()
        } catch (_: Exception) {
        }
        if (deleteFile) {
            try {
                recordingFile?.delete()
            } catch (_: Exception) {
            }
        }
        recorder = null
        recordingFile = null
        recordingStartedAt = 0L
    }

    private fun displayName(uri: Uri): String {
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) {
                return cursor.getString(index)
            }
        }
        return uri.lastPathSegment ?: "audio"
    }
}
