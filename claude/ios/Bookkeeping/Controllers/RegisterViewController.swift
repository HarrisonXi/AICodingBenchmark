import UIKit

class RegisterViewController: UIViewController {

    // MARK: - UI 元素

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel = UIFactory.label(
        text: "注册",
        font: .systemFont(ofSize: 28, weight: .bold)
    )

    private let usernameLabel = UIFactory.fieldLabel("用户名")
    private let usernameField = UIFactory.textField(placeholder: "请输入用户名（3-32个字符）")
    private let usernameError = UIFactory.errorLabel()

    private let passwordLabel = UIFactory.fieldLabel("密码")
    private let passwordField = UIFactory.textField(placeholder: "请输入密码（6-64个字符）", isSecure: true)
    private let passwordError = UIFactory.errorLabel()

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

    private let registerButton = UIFactory.primaryButton(title: "注册")
    private let goLoginButton = UIFactory.linkButton(title: "已有账号？去登录")

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        setupUI()
        setupActions()
        setupKeyboardDismiss()
    }

    // MARK: - UI 布局

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.pinToEdges(of: view)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            spacer(24),
            usernameLabel, usernameField, usernameError,
            spacer(16),
            passwordLabel, passwordField, passwordError,
            spacer(8),
            apiErrorLabel,
            spacer(24),
            registerButton,
            spacer(16),
            goLoginButton,
        ])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -32),
        ])

        titleLabel.textAlignment = .center
        goLoginButton.contentHorizontalAlignment = .center

        apiErrorLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
    }

    // MARK: - 事件绑定

    private func setupActions() {
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        goLoginButton.addTarget(self, action: #selector(goLoginTapped), for: .touchUpInside)
        usernameField.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - 校验

    private func validate() -> Bool {
        var valid = true
        let username = usernameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordField.text ?? ""

        if username.isEmpty {
            usernameError.text = "用户名不能为空"
            usernameError.isHidden = false
            valid = false
        } else if username.count < 3 {
            usernameError.text = "用户名至少 3 个字符"
            usernameError.isHidden = false
            valid = false
        } else if username.count > 32 {
            usernameError.text = "用户名最多 32 个字符"
            usernameError.isHidden = false
            valid = false
        } else {
            usernameError.isHidden = true
        }

        if password.isEmpty {
            passwordError.text = "密码不能为空"
            passwordError.isHidden = false
            valid = false
        } else if password.count < 6 {
            passwordError.text = "密码至少 6 个字符"
            passwordError.isHidden = false
            valid = false
        } else if password.count > 64 {
            passwordError.text = "密码最多 64 个字符"
            passwordError.isHidden = false
            valid = false
        } else {
            passwordError.isHidden = true
        }

        return valid
    }

    // MARK: - 操作

    @objc private func registerTapped() {
        apiErrorLabel.isHidden = true
        guard validate() else { return }

        let username = usernameField.text!.trimmingCharacters(in: .whitespaces)
        let password = passwordField.text!

        setLoading(true)

        Task {
            do {
                let response = try await AuthService.register(username: username, password: password)
                AuthManager.shared.setAuth(response: response)
                switchToMainScreen()
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

    @objc private func goLoginTapped() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            navigationController?.setViewControllers([LoginViewController()], animated: true)
        }
    }

    @objc private func fieldChanged() {
        apiErrorLabel.isHidden = true
    }

    // MARK: - 辅助

    private func setLoading(_ loading: Bool) {
        registerButton.isEnabled = !loading
        registerButton.setTitle(loading ? "注册中..." : "注册", for: .normal)
        registerButton.alpha = loading ? 0.7 : 1.0
    }

    private func switchToMainScreen() {
        guard let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate else { return }
        sceneDelegate.switchToMain()
    }

    private func spacer(_ height: CGFloat) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }
}
