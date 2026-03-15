import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let channelName = "com.clipai.imgly/editor"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // FCM — register for remote notifications
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()

        // IMG.LY stub — full implementation is ready.
        // Uncomment VideoEditorSDK imports and full code once
        // imgly.license is added to the Xcode project.
        setupStubChannel()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupStubChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { _, result in
            result([
                "error": "IMG.LY license pending — editor will be available once the license is activated"
            ])
        }
    }
}
