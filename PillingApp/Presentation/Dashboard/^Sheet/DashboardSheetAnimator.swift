import UIKit
import SnapKit

final class DashboardSheetAnimator {
    
    // MARK: - Properties
    
    private weak var viewController: UIViewController?
    private let sheetHeight: CGFloat
    
    private(set) var dimmedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        return view
    }()
    
    private(set) var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private(set) var handleBar: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.borderGray
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    // MARK: - Initialization
    
    init(viewController: UIViewController, sheetHeight: CGFloat) {
        self.viewController = viewController
        self.sheetHeight = sheetHeight
    }
    
    // MARK: - Setup
    
    func setupViews(in parentView: UIView) {
        parentView.addSubview(dimmedView)
        parentView.addSubview(containerView)
        containerView.addSubview(handleBar)
        
        dimmedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(sheetHeight)
            make.top.equalTo(parentView.snp.bottom)
        }
        
        handleBar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.width.equalTo(36)
            make.height.equalTo(5)
        }
    }
    
    // MARK: - Animations
    
    func show() {
        guard let view = viewController?.view else { return }
        
        containerView.snp.updateConstraints { make in
            make.top.equalTo(view.snp.bottom).offset(-sheetHeight)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.dimmedView.alpha = 1
            view.layoutIfNeeded()
        }
    }
    
    func hide(completion: (() -> Void)? = nil) {
        guard let view = viewController?.view else { return }
        
        containerView.snp.updateConstraints { make in
            make.top.equalTo(view.snp.bottom)
        }
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.dimmedView.alpha = 0
            view.layoutIfNeeded()
        } completion: { _ in
            self.viewController?.dismiss(animated: false) {
                completion?()
            }
        }
    }
    
    // MARK: - Gesture Handling
    
    func handlePanGesture(_ gesture: UIPanGestureRecognizer, onDismiss: @escaping () -> Void) {
        guard let view = viewController?.view else { return }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended:
            let shouldDismiss = translation.y > sheetHeight / 3 || velocity.y > 1000
            
            if shouldDismiss {
                onDismiss()
            } else {
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0.5
                ) {
                    self.containerView.transform = .identity
                }
            }
        default:
            break
        }
    }
}
