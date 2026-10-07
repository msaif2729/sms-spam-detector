package com.spamdetector.sms_spam_detector_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    private val SMS_CHANNEL = "com.spamdetector.sms_spam_detector_app/incoming_sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    SmsReceiver.smsListener = { sender, body ->
                        val data = mapOf(
                            "sender" to sender,
                            "body" to body,
                            "timestamp" to System.currentTimeMillis()
                        )
                        events?.success(data)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    SmsReceiver.smsListener = null
                }
            }
        )
    }
}
