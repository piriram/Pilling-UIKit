import UIKit
import SnapKit

extension UIViewController {
    
    /// 기본 알림 표시 (확인 버튼만)
    func presentNotification(message: String) {
        let alert = UIAlertController(title: AppStrings.Common.alertTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.Common.okBtnTitle, style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    /// 에러 알림 표시 (설정 이동 옵션 포함 가능)
    func presentError(
        title: String = AppStrings.Common.errorTitle,
        message: String,
        includeSettingsOption: Bool = false,
        settingsHandler: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        if includeSettingsOption, let handler = settingsHandler {
            let settingsAction = UIAlertAction(
                title: AppStrings.Common.goToSettings,
                style: .default
            ) { _ in
                handler()
            }
            alert.addAction(settingsAction)
        }
        
        alert.addAction(UIAlertAction(
            title: AppStrings.Common.okBtnTitle,
            style: .default
        ))
        present(alert, animated: true)
    }
    
    /// 재시도 Alert 표시 (주 액션 + 취소)
    func presentRetryAlert(
        title: String = AppStrings.Error.dataLoadFailed,
        message: String = AppStrings.Error.retryLater,
        retryTitle: String = AppStrings.Common.retryTitle,
        cancelTitle: String = AppStrings.Common.cancelTitle,
        retryHandler: @escaping () -> Void
    ) {
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        // 재시도 액션
        let retryAction = UIAlertAction(
            title: retryTitle,
            style: .default
        ) { _ in
            retryHandler()
        }
        alert.addAction(retryAction)
        
        // 취소 액션
        let cancelAction = UIAlertAction(
            title: cancelTitle,
            style: .cancel
        )
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    /// 커스텀 액션 Alert 표시 (여러 버튼 지원)
    func presentAlert(
        title: String?,
        message: String?,
        actions: [UIAlertAction],
        style: UIAlertController.Style = .alert
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: style
        )
        
        actions.forEach { alert.addAction($0) }
        
        present(alert, animated: true)
    }
    
    /// Toast 메시지 표시
    func showToast(message: String, duration: TimeInterval = 1.5) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 16)
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        
        view.addSubview(toastLabel)
        
        toastLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            $0.leading.trailing.equalToSuperview().inset(40)
            $0.height.equalTo(44)
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1
        }) { _ in
            UIView.animate(
                withDuration: 0.3,
                delay: duration,
                options: .curveEaseOut,
                animations: {
                    toastLabel.alpha = 0
                }
            ) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}
