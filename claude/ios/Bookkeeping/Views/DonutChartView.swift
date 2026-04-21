import UIKit

// MARK: - CoreGraphics 环形图

class DonutChartView: UIView {

    /// 环形图数据段
    struct Segment {
        let value: Double
        let color: UIColor
    }

    // MARK: - 固定调色板

    static let palette: [UIColor] = [
        UIColor(red: 0.97, green: 0.44, blue: 0.44, alpha: 1),  // #f87171
        UIColor(red: 0.98, green: 0.57, blue: 0.24, alpha: 1),  // #fb923c
        UIColor(red: 0.98, green: 0.75, blue: 0.14, alpha: 1),  // #fbbf24
        UIColor(red: 0.65, green: 0.55, blue: 0.98, alpha: 1),  // #a78bfa
        UIColor(red: 0.29, green: 0.68, blue: 0.50, alpha: 1),  // #4ade80
        UIColor(red: 0.38, green: 0.65, blue: 1.00, alpha: 1),  // #60a5fa
        UIColor(red: 0.96, green: 0.48, blue: 0.68, alpha: 1),  // #f472b6
        UIColor(red: 0.51, green: 0.85, blue: 0.82, alpha: 1),  // #82d9d1
    ]

    // MARK: - 属性

    var segments: [Segment] = [] {
        didSet { setNeedsDisplay() }
    }

    var centerText: String = "" {
        didSet { centerLabel.text = centerText }
    }

    var centerSubtext: String = "" {
        didSet { centerSubLabel.text = centerSubtext }
    }

    var emptyText: String = "暂无数据" {
        didSet { emptyLabel.text = emptyText }
    }

    /// 环形宽度
    private let ringWidth: CGFloat = 28

    private let centerLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 18, weight: .bold)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let centerSubLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12)
        lbl.textColor = .secondaryLabel
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let emptyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "暂无数据"
        lbl.font = .systemFont(ofSize: 15)
        lbl.textColor = .tertiaryLabel
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .clear

        let stack = UIStackView(arrangedSubviews: [centerLabel, centerSubLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    // MARK: - 绘制

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let hasData = segments.contains { $0.value > 0 }
        emptyLabel.isHidden = hasData
        centerLabel.isHidden = !hasData
        centerSubLabel.isHidden = !hasData

        guard hasData else {
            drawEmptyRing(rect)
            return
        }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - ringWidth / 2
        let total = segments.reduce(0) { $0 + $1.value }
        guard total > 0 else { return }

        var startAngle: CGFloat = -.pi / 2  // 从12点方向开始

        for segment in segments {
            let proportion = CGFloat(segment.value / total)
            let endAngle = startAngle + proportion * 2 * .pi

            let path = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )
            path.lineWidth = ringWidth
            path.lineCapStyle = .butt
            segment.color.setStroke()
            path.stroke()

            startAngle = endAngle
        }
    }

    /// 空状态灰色环
    private func drawEmptyRing(_ rect: CGRect) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - ringWidth / 2

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        path.lineWidth = ringWidth
        UIColor.systemGray5.setStroke()
        path.stroke()
    }
}
