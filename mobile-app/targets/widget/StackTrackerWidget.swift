import WidgetKit
import SwiftUI

/// Main widget bundle containing all widget sizes
@main
struct StackTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        StackTrackerWidget()
    }
}

/// Stack Tracker Portfolio Widget
struct StackTrackerWidget: Widget {
    let kind: String = "StackTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StackTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Stack Tracker Gold")
        .description("View your precious metals portfolio value and live spot prices.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Timeline provider for widget data
/// Fetches fresh prices from backend cache and creates multiple timeline entries
struct Provider: TimelineProvider {
    private let appGroupId = "group.com.stacktrackerpro.shared"
    private let backendCacheUrl = "https://stack-tracker-pro-production.up.railway.app/api/spot-prices"

    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            data: WidgetData.placeholder
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let entry = WidgetEntry(
            date: Date(),
            data: loadWidgetData()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        // Fetch fresh prices from our backend cache
        fetchFromBackendCache { freshPrices in
            let currentDate = Date()

            // Load existing widget data from App Group
            var data = loadWidgetData()

            // If we got fresh prices, update the data
            if let prices = freshPrices {
                data.goldSpot = prices.gold
                data.silverSpot = prices.silver
                data.goldChangeAmount = prices.goldChange
                data.goldChangePercent = prices.goldChangePercent
                data.silverChangeAmount = prices.silverChange
                data.silverChangePercent = prices.silverChangePercent
                data.lastUpdated = currentDate

                // Recalculate portfolio value if we have holdings data
                // (portfolioValue uses oz from App Group, just needs fresh spot prices)

                // Save updated data back to App Group so app benefits too
                saveWidgetData(data)
            }

            // Create multiple timeline entries for the next 2 hours (every 15 min = 8 entries)
            // This ensures the widget updates visually even if iOS delays the refresh
            var entries: [WidgetEntry] = []

            for minuteOffset in stride(from: 0, to: 120, by: 15) {
                let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
                // Each entry uses the same data but with updated lastUpdated for display
                var entryData = data
                entryData.lastUpdated = currentDate // Keep original fetch time for "X min ago"
                entries.append(WidgetEntry(date: entryDate, data: entryData))
            }

            // After all entries expire, request a new timeline (triggers new fetch)
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }

    /// Fetch spot prices from our backend cache
    /// This hits our Railway server's cached prices, NOT MetalpriceAPI directly
    private func fetchFromBackendCache(completion: @escaping (SpotPrices?) -> Void) {
        guard let url = URL(string: backendCacheUrl) else {
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ [Widget] Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let gold = json["gold"] as? Double,
                   let silver = json["silver"] as? Double {

                    var goldChange: Double = 0
                    var goldChangePercent: Double = 0
                    var silverChange: Double = 0
                    var silverChangePercent: Double = 0

                    if let change = json["change"] as? [String: Any] {
                        if let goldData = change["gold"] as? [String: Any] {
                            goldChange = goldData["amount"] as? Double ?? 0
                            goldChangePercent = goldData["percent"] as? Double ?? 0
                        }
                        if let silverData = change["silver"] as? [String: Any] {
                            silverChange = silverData["amount"] as? Double ?? 0
                            silverChangePercent = silverData["percent"] as? Double ?? 0
                        }
                    }

                    let prices = SpotPrices(
                        gold: gold,
                        silver: silver,
                        goldChange: goldChange,
                        goldChangePercent: goldChangePercent,
                        silverChange: silverChange,
                        silverChangePercent: silverChangePercent
                    )
                    completion(prices)
                } else {
                    completion(nil)
                }
            } catch {
                print("❌ [Widget] JSON parsing error: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }

    /// Save widget data to App Group storage
    private func saveWidgetData(_ data: WidgetData) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                userDefaults.set(jsonString, forKey: "widgetData")
            }
        } catch {
            print("❌ [Widget] Failed to save data: \(error)")
        }
    }

    /// Load widget data from shared App Group storage
    private func loadWidgetData() -> WidgetData {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            return WidgetData.placeholder
        }

        guard let jsonString = userDefaults.string(forKey: "widgetData") else {
            return WidgetData.placeholder
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            return WidgetData.placeholder
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data = try decoder.decode(WidgetData.self, from: jsonData)
            return data
        } catch {
            return WidgetData.placeholder
        }
    }
}

/// Spot prices from backend cache
struct SpotPrices {
    let gold: Double
    let silver: Double
    let goldChange: Double
    let goldChangePercent: Double
    let silverChange: Double
    let silverChangePercent: Double
}

/// Timeline entry containing widget data
struct WidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

/// Preview provider for widget
struct StackTrackerWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StackTrackerWidgetEntryView(entry: WidgetEntry(
                date: Date(),
                data: WidgetData.preview
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            StackTrackerWidgetEntryView(entry: WidgetEntry(
                date: Date(),
                data: WidgetData.preview
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
