import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 1. Pluginleri kaydet (Bu zaten vardı)
    GeneratedPluginRegistrant.register(with: self)

    // 👇 2. BİLDİRİM İZNİ İÇİN GEREKLİ OLAN KOD BU 👇
    // (Bunu eklemezsen uygulama açıkken bildirim gelmeyebilir)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    // 3. Dönüş değeri (Senin yazdığın fazlalığı sildik)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}