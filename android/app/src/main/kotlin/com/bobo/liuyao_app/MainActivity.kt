package com.bobo.liuyao_app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bobo.liuyao_app/share"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getSharedFileContent") {
                val content = readSharedFileContent(intent)
                result.success(content)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        // App已在运行时收到新的分享intent，主动通知Flutter端
        val content = readSharedFileContent(intent)
        if (content != null && methodChannel != null) {
            // 向Flutter端发送新的分享内容
            methodChannel?.invokeMethod("getSharedFileContent", content)
        }
    }

    private fun readSharedFileContent(intent: Intent?): String? {
        if (intent == null) return null

        val action = intent.action
        val type = intent.type

        return when (action) {
            Intent.ACTION_SEND -> {
                if (type == "text/plain" || type == "text/markdown") {
                    intent.getStringExtra(Intent.EXTRA_TEXT)
                } else {
                    val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                    uri?.let { readUriContent(it) }
                }
            }
            Intent.ACTION_VIEW -> {
                intent.data?.let { readUriContent(it) }
            }
            else -> null
        }
    }

    private fun readUriContent(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val reader = BufferedReader(InputStreamReader(inputStream))
            val text = reader.readText()
            reader.close()
            text
        } catch (e: Exception) {
            null
        }
    }
}
