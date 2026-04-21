import UIKit

class StatisticsViewController: UIViewController {

    // MARK: - 数据

    private var currentMonth: String = ""  // "YYYY-MM"
    private var monthlySummary: MonthlyStatistics?
    private var categoryBreakdown: CategoryBreakdown?
    private var isExpenseTab = true  // true=支出, false=收入
    private var isLoading = false

    // MARK: - UI 元素

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // 月份选择器
    private let prevMonthButton = UIButton(type: .system)
    private let nextMonthButton = UIButton(type: .system)
    private let monthLabel = UIFactory.label(font: .systemFont(ofSize: 17, weight: .semibold))

    // 汇总卡片
    private let incomeCard = UIView()
    private let expenseCard = UIView()
    private let balanceCard = UIView()
    private let incomeValueLabel = UIFactory.label(font: .systemFont(ofSize: 18, weight: .bold), color: .systemGreen)
    private let expenseValueLabel = UIFactory.label(font: .systemFont(ofSize: 18, weight: .bold), color: .systemRed)
    private let balanceValueLabel = UIFactory.label(font: .systemFont(ofSize: 18, weight: .bold), color: .systemBlue)

    // 收支切换
    private let typeSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["支出", "收入"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    // 环形图
    private let donutChart = DonutChartView()

    // 分类列表
    private let categoryListStack = UIStackView()

    // 加载指示器
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "统计"

        setupNavBar()
        initCurrentMonth()
        setupUI()
        setupActions()

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleRecordChanged),
            name: Notification.Name("RecordDidChange"), object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchAllData()
    }

    // MARK: - 导航栏

    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "退出", style: .plain, target: self, action: #selector(logoutTapped)
        )
        if let username = AuthManager.shared.username {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: username, style: .plain, target: nil, action: nil
            )
            navigationItem.leftBarButtonItem?.isEnabled = false
            navigationItem.leftBarButtonItem?.setTitleTextAttributes(
                [.foregroundColor: UIColor.secondaryLabel], for: .disabled
            )
        }
    }

    // MARK: - 初始化月份

    private func initCurrentMonth() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        currentMonth = formatter.string(from: Date())
    }

    // MARK: - UI 布局

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.pinToSafeArea(of: view)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])

        setupMonthSelector()
        setupSummaryCards()
        contentStack.addArrangedSubview(typeSegment)
        setupDonutChart()
        setupCategoryList()
        setupLoading()
    }

    // MARK: - 月份选择器

    private func setupMonthSelector() {
        prevMonthButton.setTitle("◀", for: .normal)
        prevMonthButton.titleLabel?.font = .systemFont(ofSize: 20)
        nextMonthButton.setTitle("▶", for: .normal)
        nextMonthButton.titleLabel?.font = .systemFont(ofSize: 20)
        monthLabel.textAlignment = .center

        let row = UIStackView(arrangedSubviews: [prevMonthButton, monthLabel, nextMonthButton])
        row.axis = .horizontal
        row.distribution = .fill
        row.alignment = .center
        monthLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        prevMonthButton.setSize(width: 44)
        nextMonthButton.setSize(width: 44)

        contentStack.addArrangedSubview(row)
        updateMonthLabel()
    }

    // MARK: - 汇总卡片

    private func setupSummaryCards() {
        let cards = [
            (incomeCard, "收入", incomeValueLabel, UIColor.systemGreen.withAlphaComponent(0.1)),
            (expenseCard, "支出", expenseValueLabel, UIColor.systemRed.withAlphaComponent(0.1)),
            (balanceCard, "结余", balanceValueLabel, UIColor.systemBlue.withAlphaComponent(0.1)),
        ]

        var cardViews: [UIView] = []
        for (card, title, valueLabel, bgColor) in cards {
            card.backgroundColor = bgColor
            card.layer.cornerRadius = 8

            let titleLbl = UIFactory.label(text: title, font: .systemFont(ofSize: 12), color: .secondaryLabel)
            titleLbl.textAlignment = .center
            valueLabel.textAlignment = .center
            valueLabel.text = "¥0.00"

            let stack = UIStackView(arrangedSubviews: [titleLbl, valueLabel])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 4
            stack.translatesAutoresizingMaskIntoConstraints = false

            card.addSubview(stack)
            stack.pinToEdges(of: card, insets: UIEdgeInsets(top: 10, left: 4, bottom: 10, right: 4))

            cardViews.append(card)
        }

        let row = UIStackView(arrangedSubviews: cardViews)
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 8
        contentStack.addArrangedSubview(row)
    }

    // MARK: - 环形图

    private func setupDonutChart() {
        donutChart.translatesAutoresizingMaskIntoConstraints = false
        donutChart.heightAnchor.constraint(equalToConstant: 200).isActive = true
        contentStack.addArrangedSubview(donutChart)
    }

    // MARK: - 分类列表

    private func setupCategoryList() {
        categoryListStack.axis = .vertical
        categoryListStack.spacing = 6
        contentStack.addArrangedSubview(categoryListStack)
    }

    // MARK: - 加载指示器

    private func setupLoading() {
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.centerIn(view)
    }

    // MARK: - 事件绑定

    private func setupActions() {
        prevMonthButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        nextMonthButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)
        typeSegment.addTarget(self, action: #selector(typeChanged), for: .valueChanged)
    }

    // MARK: - 月份操作

    @objc private func prevMonth() {
        guard !isLoading else { return }
        if let newMonth = offsetMonth(currentMonth, by: -1) {
            currentMonth = newMonth
            updateMonthLabel()
            fetchAllData()
        }
    }

    @objc private func nextMonth() {
        guard !isLoading else { return }
        if let newMonth = offsetMonth(currentMonth, by: 1) {
            currentMonth = newMonth
            updateMonthLabel()
            fetchAllData()
        }
    }

    private func offsetMonth(_ month: String, by offset: Int) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: month),
              let newDate = Calendar.current.date(byAdding: .month, value: offset, to: date) else {
            return nil
        }
        // 不可超过当前月
        let now = Date()
        if newDate > now {
            let currentStr = formatter.string(from: now)
            if formatter.string(from: newDate) > currentStr { return nil }
        }
        return formatter.string(from: newDate)
    }

    private func updateMonthLabel() {
        // "2026-04" → "2026年4月"
        let parts = currentMonth.split(separator: "-")
        if parts.count == 2, let year = parts.first, let monthNum = Int(parts[1]) {
            monthLabel.text = "\(year)年\(monthNum)月"
        }

        // 禁用右箭头（不可超过当前月）
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let currentMonthStr = formatter.string(from: Date())
        nextMonthButton.isEnabled = currentMonth < currentMonthStr
        nextMonthButton.alpha = nextMonthButton.isEnabled ? 1.0 : 0.3
    }

    // MARK: - 收支切换

    @objc private func typeChanged() {
        isExpenseTab = typeSegment.selectedSegmentIndex == 0
        fetchCategoryBreakdown()
    }

    // MARK: - 数据获取

    private func fetchAllData() {
        isLoading = true
        loadingIndicator.startAnimating()
        prevMonthButton.isEnabled = false
        nextMonthButton.isEnabled = false

        Task {
            async let summaryResult = StatisticsService.getMonthlyStatistics(month: currentMonth)
            async let breakdownResult = StatisticsService.getCategoryBreakdown(
                month: currentMonth, isIncome: isExpenseTab ? 0 : 1
            )

            do {
                let summary = try await summaryResult
                let breakdown = try await breakdownResult
                self.monthlySummary = summary
                self.categoryBreakdown = breakdown
            } catch is APIClient.APIError {
                // 401 已处理
            } catch {
                // 网络错误：置空
                self.monthlySummary = nil
                self.categoryBreakdown = nil
            }

            isLoading = false
            loadingIndicator.stopAnimating()
            prevMonthButton.isEnabled = true
            updateMonthLabel()
            updateSummaryUI()
            updateChartUI()
        }
    }

    private func fetchCategoryBreakdown() {
        Task {
            do {
                let breakdown = try await StatisticsService.getCategoryBreakdown(
                    month: currentMonth, isIncome: isExpenseTab ? 0 : 1
                )
                self.categoryBreakdown = breakdown
            } catch {
                self.categoryBreakdown = nil
            }
            updateChartUI()
        }
    }

    // MARK: - UI 更新

    private func updateSummaryUI() {
        let income = monthlySummary?.income ?? 0
        let expense = monthlySummary?.expense ?? 0
        let balance = monthlySummary?.balance ?? (income - expense)

        incomeValueLabel.text = "¥" + AmountFormatter.centsToYuan(income)
        expenseValueLabel.text = "¥" + AmountFormatter.centsToYuan(expense)
        balanceValueLabel.text = "¥" + AmountFormatter.centsToYuan(abs(balance))

        if balance < 0 {
            balanceValueLabel.text = "-¥" + AmountFormatter.centsToYuan(abs(balance))
            balanceValueLabel.textColor = .systemRed
        } else {
            balanceValueLabel.text = "¥" + AmountFormatter.centsToYuan(balance)
            balanceValueLabel.textColor = .systemBlue
        }
    }

    private func updateChartUI() {
        guard let breakdown = categoryBreakdown else {
            donutChart.segments = []
            donutChart.centerText = ""
            donutChart.centerSubtext = ""
            rebuildCategoryList([])
            return
        }

        // 构建环形图数据
        var segments: [DonutChartView.Segment] = []
        for (i, item) in breakdown.items.enumerated() {
            let color = DonutChartView.palette[i % DonutChartView.palette.count]
            segments.append(.init(value: Double(item.amount), color: color))
        }
        donutChart.segments = segments

        let totalYuan = AmountFormatter.centsToYuan(breakdown.total)
        donutChart.centerText = "¥" + totalYuan
        donutChart.centerSubtext = isExpenseTab ? "总支出" : "总收入"

        rebuildCategoryList(breakdown.items)
    }

    private func rebuildCategoryList(_ items: [CategoryBreakdownItem]) {
        categoryListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (i, item) in items.enumerated() {
            let color = DonutChartView.palette[i % DonutChartView.palette.count]
            let row = buildCategoryRow(item: item, color: color)
            categoryListStack.addArrangedSubview(row)
        }
    }

    private func buildCategoryRow(item: CategoryBreakdownItem, color: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 6

        // 色点
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.setSize(width: 8, height: 8)

        // 分类名
        let nameLabel = UIFactory.label(text: item.categoryName, font: .systemFont(ofSize: 14))

        // 金额
        let amountLabel = UIFactory.label(
            text: "¥" + AmountFormatter.centsToYuan(item.amount),
            font: .systemFont(ofSize: 14, weight: .medium),
            color: color
        )

        // 百分比
        let percentLabel = UIFactory.label(
            text: String(format: "%.1f%%", item.percentage),
            font: .systemFont(ofSize: 12),
            color: .secondaryLabel
        )

        let leftStack = UIStackView(arrangedSubviews: [dot, nameLabel])
        leftStack.axis = .horizontal
        leftStack.alignment = .center
        leftStack.spacing = 8

        let rightStack = UIStackView(arrangedSubviews: [amountLabel, percentLabel])
        rightStack.axis = .horizontal
        rightStack.spacing = 6
        rightStack.alignment = .center

        let row = UIStackView(arrangedSubviews: [leftStack, rightStack])
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(row)
        row.pinToEdges(of: container, insets: UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12))

        return container
    }

    // MARK: - 通知

    @objc private func handleRecordChanged() {
        fetchAllData()
    }

    // MARK: - 退出

    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "确认退出", message: "确定要退出登录吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出", style: .destructive) { [weak self] _ in
            AuthManager.shared.logout()
            guard let sceneDelegate = self?.view.window?.windowScene?.delegate as? SceneDelegate else { return }
            sceneDelegate.switchToLogin()
        })
        present(alert, animated: true)
    }
}
