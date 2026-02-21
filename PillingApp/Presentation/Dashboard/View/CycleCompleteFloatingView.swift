import UIKit
import SnapKit

final class CycleCompleteFloatingView: UIView {

    // MARK: - Properties
    var onStartNewCycle: (() -> Void)?
    var onDismiss: (() -> Void)?

    private let pillName: String

    // MARK: - UI Components

    private let dimmedBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        return view
    }()

    private let floatingCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 30
        view.layer.masksToBounds = true
        return view
    }()

    private let illustrationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "cycle_complete_illustration")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let congratulationLabel: UILabel = {
        let label = UILabel()
        label.text = "잔디를 꽉 채워주셨군요!"
        label.font = Typography.body1(.medium)
        label.textColor = AppColor.gray600
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.headline3(.bold)
        label.textColor = AppColor.textBlack
        label.textAlignment = .center
        return label
    }()

    private let startNewCycleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("새 약 복용 시작하기", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = Typography.body2(.semibold)
        button.backgroundColor = AppColor.pillGreen300
        button.layer.cornerRadius = 8
        return button
    }()

    // MARK: - Initialization

    init(pillName: String) {
        self.pillName = pillName
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        titleLabel.text = (pillName.isEmpty || pillName == "") ?  "복용 완료" : "[\(pillName)] 복용 완료"

        addSubview(dimmedBackgroundView)
        addSubview(floatingCardView)

        [illustrationImageView, congratulationLabel, titleLabel, startNewCycleButton].forEach {
            floatingCardView.addSubview($0)
        }
    }

    private func setupConstraints() {
        dimmedBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        floatingCardView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(316)
            $0.height.equalTo(371)
        }

        illustrationImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(45)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(140)
        }

        congratulationLabel.snp.makeConstraints {
            $0.top.equalTo(illustrationImageView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(congratulationLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        startNewCycleButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(24)
            $0.height.equalTo(52)
        }
    }

    private func setupActions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dimmedBackgroundTapped))
        dimmedBackgroundView.addGestureRecognizer(tapGesture)

        startNewCycleButton.addTarget(self, action: #selector(startNewCycleButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func dimmedBackgroundTapped() {
        dismiss()
    }

    @objc private func startNewCycleButtonTapped() {
        dismiss {
            self.onStartNewCycle?()
        }
    }

    // MARK: - Public Methods

    func show(in container: UIView) {
        container.addSubview(self)
        self.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        layoutIfNeeded()

        dimmedBackgroundView.alpha = 0
        floatingCardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        floatingCardView.alpha = 0

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.dimmedBackgroundView.alpha = 1
            self.floatingCardView.transform = .identity
            self.floatingCardView.alpha = 1
        }
    }

    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.dimmedBackgroundView.alpha = 0
            self.floatingCardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.floatingCardView.alpha = 0
        }) { _ in
            self.onDismiss?()
            self.removeFromSuperview()
            completion?()
        }
    }
}
