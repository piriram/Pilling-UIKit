import Foundation

protocol CalculateDashboardMessageUseCaseProtocol {
    func execute(cycle: Cycle?) -> DashboardMessage
}

final class CalculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol {

    private let calculateMessageUseCase: CalculateMessageUseCase
    private let timeProvider: TimeProvider

    init(statusFactory: PillStatusFactory, timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
        self.calculateMessageUseCase = CalculateMessageUseCase(
            statusFactory: statusFactory,
            timeProvider: timeProvider
        )
    }

    func execute(cycle: Cycle?) -> DashboardMessage {
        let result = calculateMessageUseCase.execute(cycle: cycle, for: timeProvider.now)
        return result.toDashboardMessage()
    }
}

// MARK: - MessageResult + DashboardMessage

extension MessageResult {
    
    func toDashboardMessage() -> DashboardMessage {
        let characterImage = DashboardUI.CharacterImage(rawValue: characterImageName) ?? .rest
        let icon = DashboardUI.MessageIconImage(rawValue: iconImageName) ?? .rest

        return DashboardMessage(
            text: text,
            imageName: characterImage,
            icon: icon,
            backgroundImageName: backgroundImageName
        )
    }
}
