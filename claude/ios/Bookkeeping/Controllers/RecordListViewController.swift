import UIKit

class RecordListViewController: UIViewController {

    // MARK: - 数据

    private var records: [BookRecord] = []
    private var currentPage = 1
    private var totalPages = 1
    private var isLoadingMore = false
    private var filters = RecordFilters()

    // MARK: - UI 元素

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let emptyLabel = UIFactory.label(
        text: "暂无记录",
        font: .systemFont(ofSize: 16),
        color: .secondaryLabel
    )

    // 筛选栏
    private let typeButton = UIButton(type: .system)
    private let categoryButton = UIButton(type: .system)
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let startDateLabel = UIFactory.label(text: "开始", font: .systemFont(ofSize: 13), color: .secondaryLabel)
    private let endDateLabel = UIFactory.label(text: "结束", font: .systemFont(ofSize: 13), color: .secondaryLabel)
    private let clearStartButton = UIButton(type: .system)
    private let clearEndButton = UIButton(type: .system)
    private var startDateSet = false
    private var endDateSet = false

    // 分页加载指示器
    private let footerSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.frame = CGRect(x: 0, y: 0, width: 0, height: 44)
        spinner.hidesWhenStopped = true
        return spinner
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "记账本"
        setupNavBar()
        setupFilterBar()
        setupTableView()
        setupEmptyState()
        setupLoading()

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleRecordChanged),
            name: Notification.Name("RecordDidChange"), object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            // 确保分类数据已加载，再刷新菜单
            _ = try? await CategoryService.fetchCategories()
            updateTypeMenu()
            updateCategoryMenu()
            resetAndFetch()
        }
    }

    // MARK: - 导航栏

    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "退出",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
        if let username = AuthManager.shared.username {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: username,
                style: .plain,
                target: nil,
                action: nil
            )
            navigationItem.leftBarButtonItem?.isEnabled = false
            navigationItem.leftBarButtonItem?.setTitleTextAttributes(
                [.foregroundColor: UIColor.secondaryLabel], for: .disabled
            )
        }
    }

    // MARK: - 筛选栏

    private func setupFilterBar() {
        // 类型按钮
        configureMenuButton(typeButton, title: "全部")
        updateTypeMenu()

        // 分类按钮
        configureMenuButton(categoryButton, title: "全部")
        updateCategoryMenu()

        // 日期选择器
        for dp in [startDatePicker, endDatePicker] {
            dp.datePickerMode = .date
            if #available(iOS 13.4, *) {
                dp.preferredDatePickerStyle = .compact
            }
            dp.translatesAutoresizingMaskIntoConstraints = false
            dp.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
            // 初始隐藏选中状态
            dp.alpha = 0.3
        }

        // 清除日期按钮
        for btn in [clearStartButton, clearEndButton] {
            btn.setTitle("✕", for: .normal)
            btn.setTitleColor(.secondaryLabel, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.setSize(width: 20, height: 20)
            btn.isHidden = true
        }
        clearStartButton.addTarget(self, action: #selector(clearStartDate), for: .touchUpInside)
        clearEndButton.addTarget(self, action: #selector(clearEndDate), for: .touchUpInside)

        // 第一行：类型 + 分类
        let row1 = UIStackView(arrangedSubviews: [typeButton, categoryButton])
        row1.axis = .horizontal
        row1.distribution = .fillEqually
        row1.spacing = 8

        // 第二行：开始日期 + 结束日期
        let startStack = UIStackView(arrangedSubviews: [startDateLabel, startDatePicker, clearStartButton])
        startStack.axis = .horizontal
        startStack.alignment = .center
        startStack.spacing = 4

        let endStack = UIStackView(arrangedSubviews: [endDateLabel, endDatePicker, clearEndButton])
        endStack.axis = .horizontal
        endStack.alignment = .center
        endStack.spacing = 4

        let row2 = UIStackView(arrangedSubviews: [startStack, endStack])
        row2.axis = .horizontal
        row2.distribution = .fillEqually
        row2.spacing = 8

        let filterStack = UIStackView(arrangedSubviews: [row1, row2])
        filterStack.axis = .vertical
        filterStack.spacing = 8
        filterStack.translatesAutoresizingMaskIntoConstraints = false

        let headerContainer = UIView()
        headerContainer.addSubview(filterStack)

        NSLayoutConstraint.activate([
            filterStack.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 8),
            filterStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            filterStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            filterStack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -8),
        ])

        // 计算 header 高度
        headerContainer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 100)
        headerContainer.layoutIfNeeded()
        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let fittingSize = headerContainer.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        headerContainer.frame.size.height = fittingSize.height
        tableView.tableHeaderView = headerContainer
    }

    private func configureMenuButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 6
        button.contentHorizontalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.showsMenuAsPrimaryAction = true
    }

    private func updateTypeMenu() {
        let allAction = UIAction(title: "全部", state: filters.isIncome == nil ? .on : .off) { [weak self] _ in
            self?.filters.isIncome = nil
            self?.typeButton.setTitle("全部", for: .normal)
            self?.filters.categoryId = nil
            self?.categoryButton.setTitle("全部", for: .normal)
            self?.updateTypeMenu()
            self?.updateCategoryMenu()
            self?.resetAndFetch()
        }
        let expenseAction = UIAction(title: "支出", state: filters.isIncome == 0 ? .on : .off) { [weak self] _ in
            self?.filters.isIncome = 0
            self?.typeButton.setTitle("支出", for: .normal)
            self?.filters.categoryId = nil
            self?.categoryButton.setTitle("全部", for: .normal)
            self?.updateTypeMenu()
            self?.updateCategoryMenu()
            self?.resetAndFetch()
        }
        let incomeAction = UIAction(title: "收入", state: filters.isIncome == 1 ? .on : .off) { [weak self] _ in
            self?.filters.isIncome = 1
            self?.typeButton.setTitle("收入", for: .normal)
            self?.filters.categoryId = nil
            self?.categoryButton.setTitle("全部", for: .normal)
            self?.updateTypeMenu()
            self?.updateCategoryMenu()
            self?.resetAndFetch()
        }
        typeButton.menu = UIMenu(children: [allAction, expenseAction, incomeAction])
    }

    private func updateCategoryMenu() {
        var categories: [Category]
        switch filters.isIncome {
        case 0:
            categories = CategoryService.expenseCategories()
        case 1:
            categories = CategoryService.incomeCategories()
        default:
            categories = CategoryService.expenseCategories() + CategoryService.incomeCategories()
        }

        var actions: [UIAction] = []
        actions.append(UIAction(title: "全部", state: filters.categoryId == nil ? .on : .off) { [weak self] _ in
            self?.filters.categoryId = nil
            self?.categoryButton.setTitle("全部", for: .normal)
            self?.updateCategoryMenu()
            self?.resetAndFetch()
        })

        for cat in categories {
            let state: UIMenuElement.State = filters.categoryId == cat.id ? .on : .off
            actions.append(UIAction(title: cat.name, state: state) { [weak self] _ in
                self?.filters.categoryId = cat.id
                self?.categoryButton.setTitle(cat.name, for: .normal)
                self?.updateCategoryMenu()
                self?.resetAndFetch()
            })
        }

        categoryButton.menu = UIMenu(children: actions)
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        let dateStr = DateHelper.formatDate(sender.date)

        if sender == startDatePicker {
            filters.startDate = dateStr
            startDateSet = true
            startDatePicker.alpha = 1.0
            clearStartButton.isHidden = false
        } else {
            filters.endDate = dateStr
            endDateSet = true
            endDatePicker.alpha = 1.0
            clearEndButton.isHidden = false
        }
        resetAndFetch()
    }

    @objc private func clearStartDate() {
        filters.startDate = nil
        startDateSet = false
        startDatePicker.alpha = 0.3
        clearStartButton.isHidden = true
        resetAndFetch()
    }

    @objc private func clearEndDate() {
        filters.endDate = nil
        endDateSet = false
        endDatePicker.alpha = 0.3
        clearEndButton.isHidden = true
        resetAndFetch()
    }

    // MARK: - 表格

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RecordCell.self, forCellReuseIdentifier: RecordCell.reuseID)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = footerSpinner

        view.addSubview(tableView)
        tableView.pinToSafeArea(of: view)
    }

    // MARK: - 空状态

    private func setupEmptyState() {
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.centerIn(view)
    }

    // MARK: - 加载指示器

    private func setupLoading() {
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.centerIn(view)
    }

    // MARK: - 数据获取

    private func resetAndFetch() {
        currentPage = 1
        totalPages = 1
        records = []
        tableView.reloadData()
        fetchPage(page: 1)
    }

    private func fetchPage(page: Int) {
        if page == 1 {
            loadingIndicator.startAnimating()
        } else {
            footerSpinner.startAnimating()
        }
        isLoadingMore = true

        Task {
            do {
                let response = try await RecordService.getRecords(
                    page: page, pageSize: 20, filters: filters
                )
                if page == 1 {
                    self.records = response.items
                } else {
                    self.records.append(contentsOf: response.items)
                }
                self.currentPage = response.pagination.page
                self.totalPages = response.pagination.totalPages
            } catch is APIClient.APIError {
                // 401 已由 APIClient 处理
            } catch {
                if page == 1 {
                    showAlert(message: "网络错误，请稍后重试")
                }
            }
            isLoadingMore = false
            loadingIndicator.stopAnimating()
            footerSpinner.stopAnimating()
            updateUI()
        }
    }

    private func updateUI() {
        tableView.reloadData()
        emptyLabel.isHidden = !records.isEmpty
    }

    // MARK: - 操作

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

    private func deleteRecord(at indexPath: IndexPath) {
        let record = records[indexPath.row]
        let alert = UIAlertController(title: "确认删除", message: "确定要删除这条记录吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            Task {
                do {
                    try await RecordService.deleteRecord(id: record.id)
                    NotificationCenter.default.post(name: Notification.Name("RecordDidChange"), object: nil)
                } catch let error as APIClient.APIError {
                    self?.showAlert(message: error.message)
                } catch {
                    self?.showAlert(message: "删除失败，请稍后重试")
                }
            }
        })
        present(alert, animated: true)
    }

    @objc private func handleRecordChanged() {
        resetAndFetch()
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension RecordListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecordCell.reuseID, for: indexPath) as! RecordCell
        cell.configure(with: records[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let record = records[indexPath.row]
        let vc = RecordFormViewController(mode: .edit(record))
        vc.onRecordSaved = { [weak self] in
            NotificationCenter.default.post(name: Notification.Name("RecordDidChange"), object: nil)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            self?.deleteRecord(at: indexPath)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }

    // 无限滚动：接近底部时加载下一页
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row >= records.count - 3,
           !isLoadingMore,
           currentPage < totalPages {
            fetchPage(page: currentPage + 1)
        }
    }
}

// MARK: - RecordCell

class RecordCell: UITableViewCell {
    static let reuseID = "RecordCell"

    private let categoryLabel = UIFactory.label(font: .systemFont(ofSize: 16, weight: .semibold))
    private let noteLabel = UIFactory.label(font: .systemFont(ofSize: 13), color: .secondaryLabel)
    private let amountLabel = UIFactory.label(font: .systemFont(ofSize: 18, weight: .semibold))
    private let dateLabel = UIFactory.label(font: .systemFont(ofSize: 12), color: .tertiaryLabel)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        noteLabel.lineBreakMode = .byTruncatingTail
        amountLabel.textAlignment = .right
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let leftStack = UIStackView(arrangedSubviews: [categoryLabel, noteLabel, dateLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 2
        leftStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(leftStack)
        contentView.addSubview(amountLabel)

        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leftStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            leftStack.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -12),

            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            amountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    func configure(with record: BookRecord) {
        categoryLabel.text = CategoryService.categoryName(for: record.categoryId)
        noteLabel.text = record.note ?? ""
        noteLabel.isHidden = (record.note ?? "").isEmpty
        dateLabel.text = record.date

        let yuan = AmountFormatter.centsToYuan(record.amount)
        if record.isIncome == 1 {
            amountLabel.text = "+\(yuan)"
            amountLabel.textColor = .systemGreen
        } else {
            amountLabel.text = "-\(yuan)"
            amountLabel.textColor = .systemRed
        }
    }
}
