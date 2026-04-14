import Charts
import SwiftUI

struct SeasonalChartView: View {
    let data: SeasonalData?
    @Binding var selectedYear: Int

    private let monthAbbr = ["1月","2月","3月","4月","5月","6月",
                             "7月","8月","9月","10月","11月","12月"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("月度出行趋势")
                    .font(.flHeadline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                // 年份 Picker（当年和去年）
                Picker("年份", selection: $selectedYear) {
                    let y = Calendar.current.component(.year, from: Date())
                    Text(String(y)).tag(y)
                    Text(String(y - 1)).tag(y - 1)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }

            if let months = data?.months {
                Chart(months) { item in
                    // 面积填充（半透明 AccentBlue）
                    AreaMark(
                        x: .value("月份", monthAbbr[item.month - 1]),
                        y: .value("次数", item.count)
                    )
                    .foregroundStyle(Color.accentBlue.opacity(0.15))
                    // 折线
                    LineMark(
                        x: .value("月份", monthAbbr[item.month - 1]),
                        y: .value("次数", item.count)
                    )
                    .foregroundStyle(Color.accentBlue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    // 数据点
                    PointMark(
                        x: .value("月份", monthAbbr[item.month - 1]),
                        y: .value("次数", item.count)
                    )
                    .foregroundStyle(Color.accentBlue)
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.textTertiary)
                        AxisGridLine()
                            .foregroundStyle(Color.cardElevated)
                    }
                }
                .frame(height: 160)
            } else {
                // 骨架占位
                RoundedRectangle(cornerRadius: FLMetrics.cornerRadius)
                    .fill(Color.cardElevated)
                    .frame(height: 160)
            }
        }
        .padding(FLMetrics.cardPadding)
        .background(Color.cardBackground)
        .cornerRadius(FLMetrics.cornerRadius)
    }
}
