package com.clipai.clip_ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.clipai.imgly/editor"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // IMG.LY SDK stub — full implementation is ready in the platform channel.
        // Uncomment the full MainActivity implementation once IMG.LY license
        // and Maven credentials are received from img.ly.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openVideoEditor",
                    "openCamera",
                    "openAiClipping",
                    "openTemplates",
                    "openDrafts" -> {
                        // Return a stub error so the Dart layer shows
                        // a friendly "license pending" message
                        result.success(
                            mapOf("error" to "IMG.LY license pending — editor will be available once the license is activated")
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
