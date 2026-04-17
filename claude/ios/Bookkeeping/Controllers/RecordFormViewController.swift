import UIKit

// MARK: - 表单模式

enum RecordFormMode {
    case create
    case edit(BookRecord)
}

class RecordFormViewController: UIViewController {

    private let mode: RecordFormMode

    init(mode: RecordFormMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - 数据

    private var selectedCategoryId: Int?
    private var currentCategories: [Category] = []

    // MARK: - UI 元素

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let typeSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["支出", "收入"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private let categoryLabel = UIFactory.fieldLabel("分类")
    private let categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize(width: 60, height: 36)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    private let categoryError = UIFactory.errorLabel()

    private let amountLabel = UIFactory.fieldLabel("金额（元）")
    private let amountField: UITextField = {
        let tf = UIFactory.textField(placeholder: "0.00")
        tf.keyboardType = .decimalPad
        return tf
    }()
    private let amountError = UIFactory.errorLabel()

    private let dateLabel = UIFactory.fieldLabel("日期")
    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        if #available(iOS 13.4, *) {
            dp.preferredDatePickerStyle = .compact
        }
        dp.translatesAutoresizingMaskIntoConstraints = false
        return dp
    }()

    private let noteLabel = UIFactory.fieldLabel("备注（可选，最多200字）")
    private let noteField: UITextField = {
        let tf = UIFactory.textField(placeholder: "添加备注...")
        return tf
    }()

    private let saveButton = UIFactory.primaryButton(title: "保存")

    private let apiErrorLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = .white
        lbl.backgroundColor = .systemRed.withAlphaComponent(0.85)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.layer.cornerRadius = 8
        lbl.clipsToBounds = true
        lbl.isHidden = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        switch mode {
        case .create:
            title = "新增记录"
        case .edit:
            title = "编辑记录"
        }

        setupUI()
        setupActions()
        setupKeyboardDismiss()
        loadCategories()
        populateForEdit()
    }

    // MARK: - UI 布局

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.pinToSafeArea(of: view)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        categoryCollectionView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        categoryCollectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseID)
        categoryCollectionView.dataSource = self
        categoryCollectionView.delegate = self

        let dateRow = UIStackView(arrangedSubviews: [dateLabel, datePicker])
        dateRow.axis = .horizontal
        dateRow.spacing = 12
        dateRow.alignment = .center

        apiErrorLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true

        let stack = UIStackView(arrangedSubviews: [
            typeSegment,
            spacer(16),
            categoryLabel, categoryCollectionView, categoryError,
            spacer(12),
            amountLabel, amountField, amountError,
            spacer(12),
            dateRow,
            spacer(12),
            noteLabel, noteField,
            spacer(8),
            apiErrorLabel,
            spacer(24),
            saveButton,
        ])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
        ])
    }

    // MARK: - 事件绑定

    private func setupActions() {
        typeSegment.addTarget(self, action: #selector(typeChanged), for: .valueChanged)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        noteField.delegate = self
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - 分类加载

    private func loadCategories() {
        // 如果缓存已有数据则直接用，否则异步拉取
        if !CategoryService.expenseCategories().isEmpty || !CategoryService.incomeCategories().isEmpty {
            reloadCategoryList()
        } else {
            Task {
                _ = try? await CategoryService.fetchCategories()
                reloadCategoryList()
            }
        }
    }

    private func reloadCategoryList() {
        let isIncome = typeSegment.selectedSegmentIndex == 1
        currentCategories = isIncome ? CategoryService.incomeCategories() : CategoryService.expenseCategories()
        categoryCollectionView.reloadData()
    }

    // MARK: - 编辑模式填充

    private func populateForEdit() {
        guard case .edit(let record) = mode else { return }

        typeSegment.selectedSegmentIndex = record.isIncome
        reloadCategoryList()
        selectedCategoryId = record.categoryId

        amountField.text = AmountFormatter.centsToYuan(record.amount)

        if let date = DateHelper.parseDate(record.date) {
            datePicker.date = date
        }

        noteField.text = record.note

        // 选中对应分类
        DispatchQueue.main.async { [weak self] in
            self?.categoryCollectionView.reloadData()
        }
    }

    // MARK: - 校验

    private func validate() -> Bool {
        var valid = true

        // 金额校验
        let amountText = amountField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        if amountText.isEmpty {
            amountError.text = "请输入金额"
            amountError.isHidden = false
            valid = false
        } else if AmountFormatter.yuanToCents(amountText) == nil {
            amountError.text = "请输入有效的正数金额"
            amountError.isHidden = false
            valid = false
        } else {
            amountError.isHidden = true
        }

        // 分类校验
        if selectedCategoryId == nil {
            categoryError.text = "请选择分类"
            categoryError.isHidden = false
            valid = false
        } else {
            categoryError.isHidden = true
        }

        return valid
    }

    // MARK: - 操作

    @objc private func typeChanged() {
        // 切换收入/支出时重新加载分类，并清除选中
        selectedCategoryId = nil
        reloadCategoryList()
    }

    @objc private func saveTapped() {
        apiErrorLabel.isHidden = true
        guard validate() else { return }

        let amountCents = AmountFormatter.yuanToCents(amountField.text!)!
        let isIncome = typeSegment.selectedSegmentIndex
        let categoryId = selectedCategoryId!
        let date = DateHelper.formatDate(datePicker.date)
        let note = noteField.text?.trimmingCharacters(in: .whitespaces)

        let payload = CreateRecordPayload(
            amount: amountCents,
            isIncome: isIncome,
            categoryId: categoryId,
            note: (note?.isEmpty ?? true) ? nil : note,
            date: date
        )

        setLoading(true)

        Task {
            do {
                switch mode {
                case .create:
                    _ = try await RecordService.createRecord(payload)
                case .edit(let record):
                    _ = try await RecordService.updateRecord(id: record.id, payload)
                }
                navigationController?.popViewController(animated: true)
            } catch let error as APIClient.APIError {
                apiErrorLabel.text = "  \(error.message)  "
                apiErrorLabel.isHidden = false
            } catch {
                apiErrorLabel.text = "  网络错误，请稍后重试  "
                apiErrorLabel.isHidden = false
            }
            setLoading(false)
        }
    }

    // MARK: - 辅助

    private func setLoading(_ loading: Bool) {
        saveButton.isEnabled = !loading
        saveButton.setTitle(loading ? "保存中..." : "保存", for: .normal)
        saveButton.alpha = loading ? 0.7 : 1.0
    }

    private func spacer(_ height: CGFloat) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }
}

// MARK: - UITextField Delegate（备注字数限制）

extension RecordFormViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == noteField else { return true }
        let current = textField.text ?? ""
        let newLength = current.count + string.count - range.length
        return newLength <= 200
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension RecordFormViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentCategories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseID, for: indexPath) as! CategoryCell
        let cat = currentCategories[indexPath.item]
        cell.configure(name: cat.name, isSelected: cat.id == selectedCategoryId)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCategoryId = currentCategories[indexPath.item].id
        categoryError.isHidden = true
        collectionView.reloadData()
    }
}

// MARK: - CategoryCell（pill 样式分类选择）

class CategoryCell: UICollectionViewCell {
    static let reuseID = "CategoryCell"

    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 18
        contentView.layer.borderWidth = 1
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, isSelected: Bool) {
        nameLabel.text = name
        if isSelected {
            contentView.backgroundColor = .systemBlue
            contentView.layer.borderColor = UIColor.systemBlue.cgColor
            nameLabel.textColor = .white
        } else {
            contentView.backgroundColor = .systemBackground
            contentView.layer.borderColor = UIColor.systemGray4.cgColor
            nameLabel.textColor = .label
        }
    }
}
