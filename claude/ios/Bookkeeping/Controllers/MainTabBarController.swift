import UIKit

// MARK: - 底部导航（明细 + 统计 + 中央"+"按钮）

class MainTabBarController: UITabBarController {

    private let centerButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("+", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 26, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupCenterButton()
    }

    // MARK: - Tab 配置

    private func setupTabs() {
        let recordListVC = RecordListViewController()
        let recordNav = UINavigationController(rootViewController: recordListVC)
        recordNav.tabBarItem = UITabBarItem(title: "明细", image: UIImage(systemName: "list.bullet"), tag: 0)
        recordNav.navigationBar.prefersLargeTitles = false

        let statisticsVC = StatisticsViewController()
        let statsNav = UINavigationController(rootViewController: statisticsVC)
        statsNav.tabBarItem = UITabBarItem(title: "统计", image: UIImage(systemName: "chart.pie"), tag: 1)
        statsNav.navigationBar.prefersLargeTitles = false

        viewControllers = [recordNav, statsNav]

        // Tab bar 样式
        tabBar.tintColor = .systemBlue
    }

    // MARK: - 中央"+"按钮

    private func setupCenterButton() {
        // 渐变背景
        let size: CGFloat = 50
        centerButton.layer.cornerRadius = size / 2
        centerButton.clipsToBounds = true

        // 阴影（加在容器上，因为 clipsToBounds 会裁剪阴影）
        let shadowContainer = UIView()
        shadowContainer.translatesAutoresizingMaskIntoConstraints = false
        shadowContainer.layer.shadowColor = UIColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 0.4).cgColor
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowContainer.layer.shadowOpacity = 1
        shadowContainer.layer.shadowRadius = 8

        view.addSubview(shadowContainer)
        shadowContainer.addSubview(centerButton)

        NSLayoutConstraint.activate([
            centerButton.widthAnchor.constraint(equalToConstant: size),
            centerButton.heightAnchor.constraint(equalToConstant: size),
            centerButton.centerXAnchor.constraint(equalTo: shadowContainer.centerXAnchor),
            centerButton.centerYAnchor.constraint(equalTo: shadowContainer.centerYAnchor),

            shadowContainer.centerXAnchor.constraint(equalTo: tabBar.centerXAnchor),
            shadowContainer.centerYAnchor.constraint(equalTo: tabBar.topAnchor, constant: 0),
            shadowContainer.widthAnchor.constraint(equalToConstant: size),
            shadowContainer.heightAnchor.constraint(equalToConstant: size),
        ])

        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyGradient()
    }

    private var gradientApplied = false

    private func applyGradient() {
        guard !gradientApplied else { return }
        gradientApplied = true

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.49, green: 0.54, blue: 1.0, alpha: 1).cgColor,  // #7c8aff
            UIColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 1).cgColor, // #6366f1
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = centerButton.bounds.isEmpty
            ? CGRect(x: 0, y: 0, width: 50, height: 50)
            : centerButton.bounds
        gradient.cornerRadius = 25
        centerButton.layer.insertSublayer(gradient, at: 0)
    }

    // MARK: - 新增记录

    @objc private func centerButtonTapped() {
        let formVC = RecordFormViewController(mode: .create)
        formVC.onRecordSaved = { [weak self] in
            self?.handleRecordCreated()
        }
        let nav = UINavigationController(rootViewController: formVC)
        formVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "取消", style: .plain, target: self, action: #selector(dismissModal)
        )
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    @objc private func dismissModal() {
        dismiss(animated: true)
    }

    private func handleRecordCreated() {
        dismiss(animated: true)
        NotificationCenter.default.post(name: Notification.Name("RecordDidChange"), object: nil)
    }
}
