import Foundation
import WidgetKit

/// Native module to bridge React Native with WidgetKit
/// This module allows the app to update widget data and trigger refreshes
@objc(WidgetKitModule)
class WidgetKitModule: NSObject {
    private let appGroupId = "group.com.stacktrackerpro.shared"

    /// Set widget data in shared App Group storage
    /// - Parameter jsonData: JSON string containing widget data
    @objc
    func setWidgetData(_ jsonData: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            print("WidgetKit: Failed to access App Group")
            return
        }

        userDefaults.set(jsonData, forKey: "widgetData")
        userDefaults.synchronize()
        print("WidgetKit: Widget data updated")
    }

    /// Trigger a refresh of all widget timelines
    @objc
    func reloadAllTimelines() {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("WidgetKit: Timelines reloaded")
        }
    }

    /// Trigger a refresh of a specific widget timeline
    /// - Parameter kind: The widget kind identifier
    @objc
    func reloadTimeline(_ kind: String) {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
            print("WidgetKit: Timeline reloaded for \(kind)")
        }
    }

    /// Get current widget configurations
    @objc
    func getCurrentConfigurations(_ resolve: @escaping RCTPromiseResolveBlock,
                                   reject: @escaping RCTPromiseRejectBlock) {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.getCurrentConfigurations { result in
                switch result {
                case .success(let widgets):
                    let widgetInfo = widgets.map { widget -> [String: Any] in
                        return [
                            "kind": widget.kind,
                            "family": self.familyName(widget.family)
                        ]
                    }
                    resolve(widgetInfo)
                case .failure(let error):
                    reject("WIDGET_ERROR", error.localizedDescription, error)
                }
            }
        } else {
            resolve([])
        }
    }

    /// Helper to convert widget family to string
    @available(iOS 14.0, *)
    private func familyName(_ family: WidgetFamily) -> String {
        switch family {
        case .systemSmall:
            return "small"
        case .systemMedium:
            return "medium"
        case .systemLarge:
            return "large"
        case .systemExtraLarge:
            return "extraLarge"
        case .accessoryCircular:
            return "accessoryCircular"
        case .accessoryRectangular:
            return "accessoryRectangular"
        case .accessoryInline:
            return "accessoryInline"
        @unknown default:
            return "unknown"
        }
    }

    /// Required for React Native native modules
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return false
    }
}
