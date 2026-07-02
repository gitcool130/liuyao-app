package com.bobo.liuyao_app

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val SHARE_CHANNEL = "com.bobo.liuyao_app/share"
    private val INSTALL_CHANNEL = "com.bobo.liuyao_app/install"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 分享文件通道
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getSharedFileContent") {
                val content = readSharedFileContent(intent)
                result.success(content)
            } else {
                result.notImplemented()
            }
        }

        // APK安装通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALL_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val path = call.argument<String>("path")
                if (path != null) {
                    val success = installApk(path)
                    result.success(success)
                } else {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val content = readSharedFileContent(intent)
        if (content != null && methodChannel != null) {
            methodChannel?.invokeMethod("getSharedFileContent", content)
        }
    }

    private fun installApk(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            val fileSize = file.length()
            android.util.Log.d("LiYaoInstall", "文件: path=$filePath exists=${file.exists()} size=${fileSize}")

            // 复制到外部缓存目录，确保 FileProvider 可访问
            val cacheFile = File(cacheDir, "update_${System.currentTimeMillis()}.apk")
            file.copyTo(cacheFile, overwrite = true)
            android.util.Log.d("LiYaoInstall", "缓存: path=${cacheFile.absolutePath}")

            val uri: Uri = FileProvider.getUriForFile(
                this,
                "${packageName}.fileprovider",
                cacheFile
            )
            android.util.Log.d("LiYaoInstall", "URI: $uri")

            // 优先使用 ACTION_INSTALL_PACKAGE (Android 5+ 推荐方式)
            val installIntent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
                data = uri
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            // 检查是否有安装未知应用的权限
            if (packageManager.canRequestPackageInstalls()) {
                startActivity(installIntent)
                android.util.Log.d("LiYaoInstall", "启动安装意图")
                true
            } else {
                // 引导用户去设置中开启权限
                android.util.Log.d("LiYaoInstall", "无安装权限，引导设置")
                val settingsIntent = Intent(
                    android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName")
                )
                settingsIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(settingsIntent)
                false
            }
        } catch (e: Exception) {
            android.util.Log.e("LiYaoInstall", "安装异常", e)
            false
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
            Intent.ACTION_VIEW -> intent.data?.let { readUriContent(it) }
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
        } catch (e: Exception) { null }
    }
}
