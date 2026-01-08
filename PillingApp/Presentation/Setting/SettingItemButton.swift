import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - SettingItemButton

final class SettingItemButton: UIButton {
    
    private let leadingIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = AppColor.cheveronGray
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()
    
    private let itemTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body2(.medium)
        label.textColor = AppColor.textGray
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body2(.regular)
        label.textColor = AppColor.textGray
        label.textAlignment = .natural
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.forward")
        imageView.tintColor = AppColor.cheveronGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = AppColor.grayBackground
        layer.cornerRadius = 12
        
        addSubview(leadingIconImageView)
        addSubview(itemTitleLabel)
        addSubview(valueLabel)
        addSubview(arrowImageView)
    }
    
    private func setupConstraints() {
        leadingIconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        
        itemTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(leadingIconImageView.snp.trailing).offset(10)
            $0.centerY.equalToSuperview()
        }
        
        arrowImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-14)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        
        valueLabel.snp.makeConstraints {
            $0.trailing.equalTo(arrowImageView.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(itemTitleLabel.snp.trailing).offset(16)
        }
    }
    
    func configure(title: String, iconSystemName: String? = nil) {
        itemTitleLabel.text = title
        if let name = iconSystemName {
            leadingIconImageView.image = UIImage(systemName: name)
            leadingIconImageView.isHidden = false
        } else {
            leadingIconImageView.image = nil
            leadingIconImageView.isHidden = true
        }
    }
    
    func setValue(_ value: String?) {
        valueLabel.text = value
    }
}
