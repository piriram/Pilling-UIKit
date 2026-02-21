import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class SettingCompleteFloatingView: UIView {
    
    // MARK: - Properties
    private typealias str = AppStrings.SettingFloating
    var onAutoDismiss: (() -> Void)?

    private let disposeBag = DisposeBag()

    private let titleText: String
    private let subtitleText: String
    
    // MARK: - UI Components
    
    private let dimmedBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
    private let floatingCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 30
        view.layer.masksToBounds = true
        return view
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = AppColor.pillGreen200
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.headline2(.bold)
        label.textColor = AppColor.textBlack
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body2(.regular)
        label.textColor = AppColor.secondary
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Initialization

    init(title: String? = nil, subtitle: String? = nil) {
        self.titleText = title ?? str.titleLabel
        self.subtitleText = subtitle ?? str.subTitleLabel
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    override init(frame: CGRect) {
        self.titleText = str.titleLabel
        self.subtitleText = str.subTitleLabel
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = .clear

        titleLabel.text = titleText
        subtitleLabel.text = subtitleText

        addSubview(dimmedBackgroundView)
        addSubview(floatingCardView)

        [checkmarkImageView, titleLabel, subtitleLabel].forEach {
            floatingCardView.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        dimmedBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        floatingCardView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalToSuperview().inset(50)
            $0.height.equalTo(240)
        }
        
        checkmarkImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(40)
            $0.size.equalTo(80)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(checkmarkImageView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
    }
    
    // MARK: - Public Methods
    
    func show(in container: UIView) {
        container.addSubview(self)
        self.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        layoutIfNeeded()
        
        // 초기 상태 설정
        dimmedBackgroundView.alpha = 0
        floatingCardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        floatingCardView.alpha = 0
        
        // 애니메이션으로 등장
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.dimmedBackgroundView.alpha = 1
            self.floatingCardView.transform = .identity
            self.floatingCardView.alpha = 1
        }
        
        // 2초 후 자동으로 사라짐
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.dismiss()
        }
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.dimmedBackgroundView.alpha = 0
            self.floatingCardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.floatingCardView.alpha = 0
        }) { _ in
            self.onAutoDismiss?()
            self.removeFromSuperview()
        }
    }
}
