import UIKit
import SnapKit

// MARK: - ChartContainerView
final class ChartContainerView: UIView {
    
    private let donutChartView = DonutChartView()
    
    let leftArrowButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        button.tintColor = AppColor.secondary
        return button
    }()

    let rightArrowButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.forward"), for: .normal)
        button.tintColor = AppColor.secondary
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(donutChartView)
        addSubview(leftArrowButton)
        addSubview(rightArrowButton)
        
        donutChartView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(ChartLayoutConstants.verticalInset)
        }
        
        leftArrowButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(ChartLayoutConstants.ArrowButton.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(ChartLayoutConstants.ArrowButton.width)
            make.height.equalTo(ChartLayoutConstants.ArrowButton.height)
        }
        
        rightArrowButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(ChartLayoutConstants.ArrowButton.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(ChartLayoutConstants.ArrowButton.width)
            make.height.equalTo(ChartLayoutConstants.ArrowButton.height)
        }
    }
    
    func configure(with data: PeriodRecordDTO) {
        donutChartView.configure(
            records: data.records,
            completionRate: data.completionRate,
            isEmpty: data.isEmpty
        )
    }
    
    func updateArrowButtons(isLeftEnabled: Bool, isRightEnabled: Bool) {
        leftArrowButton.isEnabled = isLeftEnabled
        leftArrowButton.tintColor = isLeftEnabled ? AppColor.secondary : AppColor.notYetGray
        
        rightArrowButton.isEnabled = isRightEnabled
        rightArrowButton.tintColor = isRightEnabled ? AppColor.secondary : AppColor.notYetGray
    }
}


