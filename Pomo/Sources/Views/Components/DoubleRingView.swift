import SwiftUI

struct DoubleRingView: View {
    let timerProgress: Double
    let cycleProgress: Double
    let completedPomodoros: Int
    let totalPomodoros: Int
    let isBreak: Bool
    let size: CGFloat

    private var outerRadius: CGFloat { size / 2 - 4 }
    private var innerRadius: CGFloat { size / 2 - 20 }
    private var outerStrokeWidth: CGFloat { size * 0.03 }
    private var innerStrokeWidth: CGFloat { size * 0.06 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: outerStrokeWidth, dash: [4, 3]))
                .frame(width: outerRadius * 2, height: outerRadius * 2)

            ForEach(0..<completedPomodoros, id: \.self) { index in
                Circle()
                    .trim(
                        from: CGFloat(index) / CGFloat(totalPomodoros),
                        to: CGFloat(index + 1) / CGFloat(totalPomodoros) - 0.01
                    )
                    .stroke(
                        isBreak ? Color(hex: "4ecdc4").opacity(0.5) : Color(hex: "ff8e53").opacity(0.5),
                        lineWidth: outerStrokeWidth
                    )
                    .frame(width: outerRadius * 2, height: outerRadius * 2)
                    .rotationEffect(.degrees(-90))
            }

            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: innerStrokeWidth)
                .frame(width: innerRadius * 2, height: innerRadius * 2)

            Circle()
                .trim(from: 0, to: timerProgress)
                .stroke(
                    isBreak
                        ? AnyShapeStyle(Color(hex: "4ecdc4"))
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color(hex: "ff6b6b"), Color(hex: "ff8e53")],
                            startPoint: .leading,
                            endPoint: .trailing
                          )),
                    style: StrokeStyle(lineWidth: innerStrokeWidth, lineCap: .round)
                )
                .frame(width: innerRadius * 2, height: innerRadius * 2)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerProgress)
        }
        .frame(width: size, height: size)
    }
}
