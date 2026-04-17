import UIKit

class RecordListViewController: UIViewController {

    // MARK: - 数据

    private var records: [BookRecord] = []

    // MARK: - UI 元素

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let emptyLabel = UIFactory.label(
        text: "暂无记录\n点击右下角按钮开始记账",
        font: .systemFont(ofSize: 16),
        color: .secondaryLabel
    )

    // 汇总卡片
    private let summaryView = UIView()
    private let incomeValueLabel = UIFactory.label(font: .systemFont(ofSize: 20, weight: .semibold), color: .systemGreen)
    private let expenseValueLabel = UIFactory.label(font: .systemFont(ofSize: 20, weight: .semibold), color: .systemRed)
    private let balanceValueLabel = UIFactory.label(font: .systemFont(ofSize: 20, weight: .semibold))

    // 浮动添加按钮
    private let fabButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("+", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 28, weight: .medium)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 28
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowRadius = 4
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "记账本"
        setupNavBar()
        setupSummaryView()
        setupTableView()
        setupFAB()
        setupEmptyState()
        setupLoading()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchRecords()
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

    // MARK: - 汇总卡片

    private func setupSummaryView() {
        summaryView.backgroundColor = .secondarySystemBackground
        summaryView.layer.cornerRadius = 12

        let incomeTitleLabel = UIFactory.label(text: "收入", font: .systemFont(ofSize: 13), color: .secondaryLabel)
        let expenseTitleLabel = UIFactory.label(text: "支出", font: .systemFont(ofSize: 13), color: .secondaryLabel)
        let balanceTitleLabel = UIFactory.label(text: "结余", font: .systemFont(ofSize: 13), color: .secondaryLabel)

        // 收入列
        let incomeStack = UIStackView(arrangedSubviews: [incomeTitleLabel, incomeValueLabel])
        incomeStack.axis = .vertical
        incomeStack.alignment = .center
        incomeStack.spacing = 4

        // 支出列
        let expenseStack = UIStackView(arrangedSubviews: [expenseTitleLabel, expenseValueLabel])
        expenseStack.axis = .vertical
        expenseStack.alignment = .center
        expenseStack.spacing = 4

        // 结余列
        let balanceStack = UIStackView(arrangedSubviews: [balanceTitleLabel, balanceValueLabel])
        balanceStack.axis = .vertical
        balanceStack.alignment = .center
        balanceStack.spacing = 4

        let hStack = UIStackView(arrangedSubviews: [incomeStack, expenseStack, balanceStack])
        hStack.axis = .horizontal
        hStack.distribution = .fillEqually
        hStack.translatesAutoresizingMaskIntoConstraints = false

        summaryView.addSubview(hStack)
        hStack.pinToEdges(of: summaryView, insets: UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8))

        summaryView.frame = CGRect(x: 16, y: 0, width: view.bounds.width - 32, height: 80)

        // 包装成 tableHeaderView
        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 96))
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(summaryView)

        NSLayoutConstraint.activate([
            summaryView.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 8),
            summaryView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            summaryView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            summaryView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -8),
        ])

        tableView.tableHeaderView = headerContainer

        updateSummary()
    }

    // MARK: - 表格

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RecordCell.self, forCellReuseIdentifier: RecordCell.reuseID)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        tableView.pinToSafeArea(of: view)
    }

    // MARK: - 浮动按钮

    private func setupFAB() {
        view.addSubview(fabButton)
        NSLayoutConstraint.activate([
            fabButton.widthAnchor.constraint(equalToConstant: 56),
            fabButton.heightAnchor.constraint(equalToConstant: 56),
            fabButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            fabButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
        fabButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
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

    private func fetchRecords() {
        loadingIndicator.startAnimating()

        Task {
            do {
                records = try await RecordService.getRecords()
            } catch is APIClient.APIError {
                // 401 已由 APIClient 处理，其他错误忽略并保持当前列表
            } catch {
                showAlert(message: "网络错误，请稍后重试")
            }
            loadingIndicator.stopAnimating()
            updateUI()
        }
    }

    private func updateUI() {
        tableView.reloadData()
        emptyLabel.isHidden = !records.isEmpty
        updateSummary()
    }

    private func updateSummary() {
        let income = records.filter { $0.isIncome == 1 }.reduce(0) { $0 + $1.amount }
        let expense = records.filter { $0.isIncome == 0 }.reduce(0) { $0 + $1.amount }
        let balance = income - expense

        incomeValueLabel.text = "+\(AmountFormatter.centsToYuan(income))"
        expenseValueLabel.text = "-\(AmountFormatter.centsToYuan(expense))"
        balanceValueLabel.text = (balance >= 0 ? "+" : "") + AmountFormatter.centsToYuan(balance)
        balanceValueLabel.textColor = balance >= 0 ? .systemGreen : .systemRed
    }

    // MARK: - 操作

    @objc private func addTapped() {
        let vc = RecordFormViewController(mode: .create)
        navigationController?.pushViewController(vc, animated: true)
    }

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
                    self?.fetchRecords()
                } catch let error as APIClient.APIError {
                    self?.showAlert(message: error.message)
                } catch {
                    self?.showAlert(message: "删除失败，请稍后重试")
                }
            }
        })
        present(alert, animated: true)
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
