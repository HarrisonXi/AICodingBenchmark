import UIKit

// MARK: - Auto Layout 便捷扩展

extension UIView {
    /// 固定到父视图边缘
    func pinToEdges(of view: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
        ])
    }

    /// 固定到父视图安全区域
    func pinToSafeArea(of view: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -insets.bottom),
        ])
    }

    /// 居中
    func centerIn(_ view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    /// 设置固定尺寸
    func setSize(width: CGFloat? = nil, height: CGFloat? = nil) {
        translatesAutoresizingMaskIntoConstraints = false
        if let w = width {
            widthAnchor.constraint(equalToConstant: w).isActive = true
        }
        if let h = height {
            heightAnchor.constraint(equalToConstant: h).isActive = true
        }
    }
}

// MARK: - UI 工厂方法

enum UIFactory {
    /// 标准文本输入框
    static func textField(placeholder: String, isSecure: Bool = false) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.isSecureTextEntry = isSecure
        if isSecure {
            tf.textContentType = .oneTimeCode
        }
        tf.borderStyle = .none
        tf.font = .systemFont(ofSize: 16)
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.layer.borderColor = UIColor.systemGray4.cgColor
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 8
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.rightViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return tf
    }

    /// 主按钮（蓝底白字）
    static func primaryButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return btn
    }

    /// 标签
    static func label(text: String = "", font: UIFont = .systemFont(ofSize: 14), color: UIColor = .label) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = font
        lbl.textColor = color
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }

    /// 错误提示标签（红色小字，默认隐藏）
    static func errorLabel() -> UILabel {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 13)
        lbl.textColor = .systemRed
        lbl.numberOfLines = 0
        lbl.isHidden = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }

    /// 字段标签（表单用）
    static func fieldLabel(_ text: String) -> UILabel {
        return label(text: text, font: .systemFont(ofSize: 14, weight: .medium), color: .secondaryLabel)
    }

    /// 链接按钮（蓝色文字）
    static func linkButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }
}
