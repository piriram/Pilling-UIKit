import UIKit
import SnapKit

final class TooltipView: UIView {
    
    enum ArrowDirection {
        case top
        case bottom
    }
    
    enum ArrowPosition {
        case leading(offset: CGFloat = 16)
        case center
        case trailing(offset: CGFloat = 16)
    }
    
    // MARK: - UI Components
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    private let contentContainer = UIView()
    private let arrowView = UIView()
    
    // MARK: - Properties
    
    private let arrowDirection: ArrowDirection
    private let arrowPosition: ArrowPosition
    private let tooltipBackgroundColor: UIColor
    private let arrowSize: CGSize = CGSize(width: 12, height: 6)
    private let cornerRadius: CGFloat = 8
    private let contentPadding: UIEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    
    // MARK: - Initialization
    
    init(message: String,
         backgroundColor: UIColor,
         textColor: UIColor = .black,
         arrowDirection: ArrowDirection,
         arrowPosition: ArrowPosition = .center) {
        self.arrowDirection = arrowDirection
        self.arrowPosition = arrowPosition
        self.tooltipBackgroundColor = backgroundColor
        super.init(frame: .zero)

        messageLabel.text = message
        messageLabel.textColor = textColor
        contentContainer.backgroundColor = backgroundColor
        arrowView.backgroundColor = .clear

        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        addSubview(contentContainer)
        addSubview(arrowView)
        contentContainer.addSubview(messageLabel)
        
        contentContainer.layer.cornerRadius = cornerRadius
        contentContainer.clipsToBounds = true
        
        setupConstraints()
        setupArrowShape()
    }
    
    private func setupConstraints() {
        switch arrowDirection {
        case .top:
            arrowView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.height.equalTo(arrowSize.height)
                make.width.equalTo(arrowSize.width)
                setupArrowHorizontalPosition(make)
            }
            
            contentContainer.snp.makeConstraints { make in
                make.top.equalTo(arrowView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            
        case .bottom:
            contentContainer.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
            }
            
            arrowView.snp.makeConstraints { make in
                make.top.equalTo(contentContainer.snp.bottom)
                make.bottom.equalToSuperview()
                make.height.equalTo(arrowSize.height)
                make.width.equalTo(arrowSize.width)
                setupArrowHorizontalPosition(make)
            }
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(contentPadding.top)
            make.leading.equalToSuperview().offset(contentPadding.left)
            make.trailing.equalToSuperview().offset(-contentPadding.right)
            make.bottom.equalToSuperview().offset(-contentPadding.bottom)
        }
    }
    
    private func setupArrowHorizontalPosition(_ make: ConstraintMaker) {
        switch arrowPosition {
        case .leading(let offset):
            make.leading.equalToSuperview().offset(offset)
        case .center:
            make.centerX.equalToSuperview()
        case .trailing(let offset):
            make.trailing.equalToSuperview().offset(-offset)
        }
    }
    
    private func setupArrowShape() {
        arrowView.layoutIfNeeded()
        
        let path = UIBezierPath()
        
        switch arrowDirection {
        case .top:
            path.move(to: CGPoint(x: 0, y: arrowSize.height))
            path.addLine(to: CGPoint(x: arrowSize.width / 2, y: 0))
            path.addLine(to: CGPoint(x: arrowSize.width, y: arrowSize.height))
            
        case .bottom:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: arrowSize.width / 2, y: arrowSize.height))
            path.addLine(to: CGPoint(x: arrowSize.width, y: 0))
        }
        
        path.close()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = tooltipBackgroundColor.cgColor

        arrowView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        arrowView.layer.addSublayer(shapeLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupArrowShape()
    }
}
