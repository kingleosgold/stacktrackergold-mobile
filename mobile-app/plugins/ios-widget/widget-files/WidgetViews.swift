import SwiftUI
import WidgetKit

// MARK: - Design Constants

private let bgGradient = LinearGradient(
    colors: [Color(hex: "#1a1a1a"), Color(hex: "#0d0d0d")],
    startPoint: .top,
    endPoint: .bottom
)
private let goldAccent = Color(hex: "#D4A843")
private let greenColor = Color(hex: "#4CAF50")
private let redColor = Color(hex: "#F44336")
private let mutedColor = Color(hex: "#71717a")
private let silverColor = Color(hex: "#9ca3af")
private let platinumColor = Color(hex: "#7BB3D4")
private let palladiumColor = Color(hex: "#6BBF8A")

// MARK: - SparklineView

struct SparklineView: View {
    let data: [Double]
    let color: Color
    let lineWidth: CGFloat
    let showFill: Bool

    init(data: [Double], color: Color, lineWidth: CGFloat = 1.5, showFill: Bool = false) {
        self.data = data
        self.color = color
        self.lineWidth = lineWidth
        self.showFill = showFill
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let points = normalizedPoints(width: w, height: h)

            if points.count >= 2 {
                // Line
                Path { path in
                    path.move(to: points[0])
                    for i in 1..<points.count {
                        path.addLine(to: points[i])
                    }
                }
                .stroke(color, lineWidth: lineWidth)

                // Optional gradient fill under the line
                if showFill {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: h))
                        for pt in points {
                            path.addLine(to: pt)
                        }
                        path.addLine(to: CGPoint(x: points.last!.x, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
    }

    private func normalizedPoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard data.count >= 2 else { return [] }
        let minVal = data.min() ?? 0
        let maxVal = data.max() ?? 1
        let range = maxVal - minVal
        let safeRange = range > 0 ? range : 1

        let padding: CGFloat = 2
        let drawHeight = height - padding * 2

        return data.enumerated().map { i, val in
            let x = width * CGFloat(i) / CGFloat(data.count - 1)
            let y = padding + drawHeight * (1 - CGFloat((val - minVal) / safeRange))
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Helpers

private func privacyText(_ text: String, _ hide: Bool) -> String {
    hide ? "••••••" : text
}

private func changeColor(_ value: Double) -> Color {
    value >= 0 ? greenColor : redColor
}

private func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? "$0"
}

private func formatSpotPrice(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
}

private func formatChange(_ value: Double) -> String {
    let prefix = value >= 0 ? "+" : ""
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 0
    return prefix + (formatter.string(from: NSNumber(value: value)) ?? "$0")
}

private func formatPercent(_ value: Double) -> String {
    let prefix = value >= 0 ? "+" : ""
    return "\(prefix)\(String(format: "%.1f", value))%"
}

/// Gold shimmer accent line at top of widget (flush at 0px)
private func goldAccentLine() -> some View {
    Rectangle()
        .fill(goldAccent)
        .frame(height: 2)
}

// MARK: - Main Entry View

struct StackTrackerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: WidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let data: WidgetData

    var body: some View {
        Group {
            if data.hasSubscription {
                VStack(alignment: .leading, spacing: 0) {
                    goldAccentLine()

                    VStack(alignment: .leading, spacing: 0) {
                        // Logo + label
                        HStack(spacing: 6) {
                            Image("AppIcon")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .cornerRadius(4)
                            Text("PORTFOLIO")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(mutedColor)
                                .kerning(1.2)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 4)

                        // Portfolio value
                        Text(privacyText(formatCurrency(data.portfolioValue), data.hideValues))
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .padding(.bottom, 2)

                        // Daily change
                        HStack(spacing: 3) {
                            Text(data.dailyChangeAmount >= 0 ? "▲" : "▼")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(changeColor(data.dailyChangeAmount))
                            Text(privacyText(formatChange(data.dailyChangeAmount), data.hideValues))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(changeColor(data.dailyChangeAmount))
                            Text("(\(formatPercent(data.dailyChangePercent)))")
                                .font(.system(size: 9))
                                .foregroundColor(changeColor(data.dailyChangeAmount))
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                        Spacer()

                        // Full-width sparkline at bottom
                        let sparkline = data.portfolioSparkline()
                        if sparkline.count >= 2 {
                            SparklineView(
                                data: sparkline,
                                color: data.dailyChangeAmount >= 0 ? greenColor : redColor,
                                lineWidth: 1.5,
                                showFill: true
                            )
                            .frame(height: 32)
                            .padding(.bottom, 6)
                        } else {
                            // Fallback: colored dots for held metals
                            HStack(spacing: 6) {
                                if data.goldValue > 0 { Circle().fill(goldAccent).frame(width: 8, height: 8) }
                                if data.silverValue > 0 { Circle().fill(silverColor).frame(width: 8, height: 8) }
                                if data.platinumValue > 0 { Circle().fill(platinumColor).frame(width: 8, height: 8) }
                                if data.palladiumValue > 0 { Circle().fill(palladiumColor).frame(width: 8, height: 8) }
                            }
                            .padding(.bottom, 6)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            } else {
                VStack(spacing: 4) {
                    Spacer()
                    Text("Upgrade to Gold")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(goldAccent)
                    Text("for widget access")
                        .font(.system(size: 11))
                        .foregroundColor(mutedColor)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentMarginsDisabled()
        .containerBackground(for: .widget) { bgGradient }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let data: WidgetData

    var body: some View {
        Group {
            if data.hasSubscription {
                VStack(alignment: .leading, spacing: 0) {
                    goldAccentLine()

                    HStack(spacing: 0) {
                        // LEFT HALF: Portfolio + sparkline
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 5) {
                                Image("AppIcon")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .cornerRadius(3)
                                Text("PORTFOLIO")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(mutedColor)
                                    .kerning(1.0)
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                            Text(privacyText(formatCurrency(data.portfolioValue), data.hideValues))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .padding(.bottom, 2)

                            HStack(spacing: 3) {
                                Text(data.dailyChangeAmount >= 0 ? "▲" : "▼")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(changeColor(data.dailyChangeAmount))
                                Text(privacyText(formatChange(data.dailyChangeAmount), data.hideValues))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(changeColor(data.dailyChangeAmount))
                                Text("(\(formatPercent(data.dailyChangePercent)))")
                                    .font(.system(size: 9))
                                    .foregroundColor(changeColor(data.dailyChangeAmount))
                            }
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                            Spacer()

                            let sparkline = data.portfolioSparkline()
                            if sparkline.count >= 2 {
                                SparklineView(
                                    data: sparkline,
                                    color: data.dailyChangeAmount >= 0 ? greenColor : redColor,
                                    lineWidth: 1.5,
                                    showFill: true
                                )
                                .frame(height: 30)
                                .padding(.bottom, 8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Vertical divider
                        Rectangle()
                            .fill(goldAccent.opacity(0.15))
                            .frame(width: 1)
                            .padding(.vertical, 10)

                        // RIGHT HALF: Au + Ag with inline sparklines
                        VStack(spacing: 6) {
                            Spacer(minLength: 4)
                            metalRowMedium(
                                symbol: "Au",
                                price: data.goldSpot,
                                changePercent: data.goldChangePercent,
                                changeAmount: data.goldChangeAmount,
                                sparkline: data.goldSparkline,
                                color: goldAccent
                            )
                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                            metalRowMedium(
                                symbol: "Ag",
                                price: data.silverSpot,
                                changePercent: data.silverChangePercent,
                                changeAmount: data.silverChangeAmount,
                                sparkline: data.silverSparkline,
                                color: silverColor
                            )
                            Spacer(minLength: 4)
                        }
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28))
                        .foregroundColor(mutedColor)
                    Text("Upgrade to Gold")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(goldAccent)
                    Text("Get portfolio widgets on your home screen")
                        .font(.system(size: 12))
                        .foregroundColor(mutedColor)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentMarginsDisabled()
        .containerBackground(for: .widget) { bgGradient }
    }

    private func metalRowMedium(symbol: String, price: Double, changePercent: Double, changeAmount: Double, sparkline: [Double], color: Color) -> some View {
        HStack(spacing: 6) {
            // Symbol + price
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Circle().fill(color).frame(width: 6, height: 6)
                    Text(symbol)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(formatSpotPrice(price))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(formatPercent(changePercent))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(changeColor(changeAmount))
            }

            Spacer()

            // Inline sparkline
            if sparkline.count >= 2 {
                SparklineView(
                    data: sparkline,
                    color: changeAmount >= 0 ? greenColor : redColor,
                    lineWidth: 1.0
                )
                .frame(width: 48, height: 22)
            }
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let data: WidgetData

    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        Group {
            if data.hasSubscription {
                VStack(alignment: .leading, spacing: 0) {
                    goldAccentLine()

                    VStack(alignment: .leading, spacing: 0) {
                        // Logo + portfolio value
                        HStack(spacing: 8) {
                            Image("AppIcon")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .cornerRadius(4)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(privacyText(formatCurrency(data.portfolioValue), data.hideValues))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.top, 10)

                        // Daily change
                        HStack(spacing: 4) {
                            Text(data.dailyChangeAmount >= 0 ? "▲" : "▼")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(changeColor(data.dailyChangeAmount))
                            Text(privacyText(formatChange(data.dailyChangeAmount), data.hideValues))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(changeColor(data.dailyChangeAmount))
                            Text("(\(formatPercent(data.dailyChangePercent)))")
                                .font(.system(size: 11))
                                .foregroundColor(changeColor(data.dailyChangeAmount))
                        }
                        .padding(.top, 2)

                        // Portfolio sparkline
                        let sparkline = data.portfolioSparkline()
                        if sparkline.count >= 2 {
                            SparklineView(
                                data: sparkline,
                                color: data.dailyChangeAmount >= 0 ? greenColor : redColor,
                                lineWidth: 1.5,
                                showFill: true
                            )
                            .frame(height: 40)
                            .padding(.top, 6)
                        }

                        // Divider
                        Rectangle()
                            .fill(goldAccent.opacity(0.15))
                            .frame(height: 1)
                            .padding(.vertical, 8)

                        // LIVE SPOT section header
                        Text("LIVE SPOT")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(mutedColor)
                            .kerning(1.2)
                            .padding(.bottom, 6)

                        // 2x2 grid of spot price cards with sparklines
                        LazyVGrid(columns: gridColumns, spacing: 8) {
                            spotCardLarge(symbol: "Au", price: data.goldSpot, changePercent: data.goldChangePercent, changeAmount: data.goldChangeAmount, sparkline: data.goldSparkline, color: goldAccent)
                            spotCardLarge(symbol: "Ag", price: data.silverSpot, changePercent: data.silverChangePercent, changeAmount: data.silverChangeAmount, sparkline: data.silverSparkline, color: silverColor)
                            spotCardLarge(symbol: "Pt", price: data.platinumSpot, changePercent: data.platinumChangePercent, changeAmount: data.platinumChangeAmount, sparkline: data.platinumSparkline, color: platinumColor)
                            spotCardLarge(symbol: "Pd", price: data.palladiumSpot, changePercent: data.palladiumChangePercent, changeAmount: data.palladiumChangeAmount, sparkline: data.palladiumSparkline, color: palladiumColor)
                        }

                        Spacer(minLength: 4)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundColor(mutedColor)
                    Text("Upgrade to Gold")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(goldAccent)
                    Text("Get portfolio widgets on your home screen")
                        .font(.system(size: 13))
                        .foregroundColor(mutedColor)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentMarginsDisabled()
        .containerBackground(for: .widget) { bgGradient }
    }

    private func spotCardLarge(symbol: String, price: Double, changePercent: Double, changeAmount: Double, sparkline: [Double], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Circle().fill(color).frame(width: 6, height: 6)
                        Text(symbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(color)
                    }
                    Text(formatSpotPrice(price))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(formatPercent(changePercent))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(changeColor(changeAmount))
                }
                Spacer()
            }

            // Sparkline in each card
            if sparkline.count >= 2 {
                SparklineView(
                    data: sparkline,
                    color: changeAmount >= 0 ? greenColor : redColor,
                    lineWidth: 1.0
                )
                .frame(height: 20)
                .padding(.top, 4)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
