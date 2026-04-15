import Foundation
import WeatherKit
import CoreLocation

@MainActor
final class WeatherService {
    static let shared = WeatherService()
    private let service = WeatherKit.WeatherService.shared
    private init() {}

    // 天气查询结果
    struct WeatherResult {
        let temperature: Double  // 摄氏度
        let condition: String    // 天气状况描述
        let wind: String         // 风力描述
    }

    // 获取指定位置和日期的天气
    func fetchWeather(latitude: Double, longitude: Double, date: Date) async -> WeatherResult? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let calendar = Calendar.current

        do {
            if calendar.isDateInToday(date) {
                // 当天：获取当前天气
                let weather = try await service.weather(for: location, including: .current)
                return WeatherResult(
                    temperature: weather.temperature.converted(to: .celsius).value,
                    condition: conditionName(weather.condition),
                    wind: formatWind(weather.wind.speed.converted(to: .kilometersPerHour).value)
                )
            } else {
                // 非当天：获取日级预报
                let weather = try await service.weather(for: location, including: .daily)
                if let dayWeather = weather.forecast.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                    let avgTemp = (dayWeather.highTemperature.converted(to: .celsius).value
                                 + dayWeather.lowTemperature.converted(to: .celsius).value) / 2
                    return WeatherResult(
                        temperature: avgTemp,
                        condition: conditionName(dayWeather.condition),
                        wind: formatWind(dayWeather.wind.speed.converted(to: .kilometersPerHour).value)
                    )
                }
            }
        } catch {
            print("WeatherKit 获取失败: \(error)")
        }
        return nil
    }

    // 天气状况中文名
    private func conditionName(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return "晴"
        case .mostlyClear: return "晴间多云"
        case .partlyCloudy: return "多云"
        case .mostlyCloudy: return "阴"
        case .cloudy: return "阴天"
        case .rain: return "雨"
        case .heavyRain: return "大雨"
        case .drizzle: return "小雨"
        case .snow: return "雪"
        case .heavySnow: return "大雪"
        case .sleet: return "雨夹雪"
        case .thunderstorms: return "雷暴"
        case .strongStorms: return "强风暴"
        case .windy: return "大风"
        case .foggy: return "雾"
        case .haze: return "霾"
        case .hot: return "高温"
        case .blowingDust: return "扬尘"
        default: return "未知"
        }
    }

    // 风力等级中文描述
    private func formatWind(_ kmh: Double) -> String {
        switch kmh {
        case 0..<12: return "微风"
        case 12..<39: return "轻风"
        case 39..<62: return "中风"
        case 62..<88: return "大风"
        default: return "强风"
        }
    }
}
