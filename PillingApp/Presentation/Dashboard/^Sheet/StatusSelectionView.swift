import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class StatusSelectionView: UIView {
    
    // MARK: - Properties
    
    private let disposeBag = DisposeBag()
    private var selectedButtonTag: Int = -1
    
    private typealias str = AppStrings.Dashboard
    
    // MARK: - Observables
    
    let notTakenTapped = PublishRelay<Void>()
    let takenTapped = PublishRelay<Void>()
    let takenDoubleTapped = PublishRelay<Void>()
    
    // MARK: - UI Components
    
    private let container: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.grayBackground
        view.layer.cornerRadius = 12
        view.isUserInteractionEnabled = true
        view.clipsToBounds = true
        return view
    }()
    
    private let buttonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        return stack
    }()
    
    private lazy var notTakenButton = createButton(title: str.guideMissed, tag: 0)
    private lazy var takenButton = createButton(title: str.taken, tag: 1)
    private lazy var takenDoubleButton = createButton(title: str.takenDouble, tag: 2)
    
    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        bindButtons()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    // MARK: - Setup
    
    private func setupViews() {
        addSubview(container)
        container.addSubview(buttonsStack)
        
        buttonsStack.addArrangedSubview(notTakenButton)
        buttonsStack.addArrangedSubview(takenButton)
        buttonsStack.addArrangedSubview(takenDoubleButton)
        
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(44)
        }
        
        buttonsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
    }
    
    private func bindButtons() {
        notTakenButton.rx.tap
            .do(onNext: { [weak self] in
                self?.selectButton(tag: 0)
            })
            .bind(to: notTakenTapped)
            .disposed(by: disposeBag)

        takenButton.rx.tap
            .do(onNext: { [weak self] in
                self?.selectButton(tag: 1)
            })
            .bind(to: takenTapped)
            .disposed(by: disposeBag)

        takenDoubleButton.rx.tap
            .do(onNext: { [weak self] in
                self?.selectButton(tag: 2)
            })
            .bind(to: takenDoubleTapped)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Button Creation
    
    private func createButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.tag = tag
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.isUserInteractionEnabled = true
        return button
    }
    
    // MARK: - Public Methods
    
    // StatusSelectionView.swift

    func setInitialSelection(buttonTag: StatusButtonTag) {
        let tag = buttonTag.rawValue
        
        guard tag >= 0 else { return }
        selectButton(tag: tag)
        
        // sendActions 대신 직접 relay를 트리거
        switch buttonTag {
        case .notTaken:
            notTakenTapped.accept(())
        case .taken:
            takenTapped.accept(())
        case .takenDouble:
            takenDoubleTapped.accept(())
        case .none:
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func selectButton(tag: Int) {
        let buttons = [notTakenButton, takenButton, takenDoubleButton]
        selectedButtonTag = tag
        
        buttons.forEach { button in
            let isSelected = button.tag == tag
            
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5
            ) {
                button.isSelected = isSelected
                button.backgroundColor = isSelected ? AppColor.pillWhite : .clear
                button.titleLabel?.font = isSelected
                ? .systemFont(ofSize: 16, weight: .semibold)
                : .systemFont(ofSize: 15, weight: .regular)
                
                if isSelected {
                    button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                    button.layer.shadowColor = AppColor.pillWhite.cgColor
                    button.layer.shadowOffset = CGSize(width: 0, height: 2)
                    button.layer.shadowOpacity = 0.3
                    button.layer.shadowRadius = 4
                } else {
                    button.transform = .identity
                    button.layer.shadowOpacity = 0
                }
            }
        }
    }
}
