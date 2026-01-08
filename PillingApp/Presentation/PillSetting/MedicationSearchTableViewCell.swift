import UIKit
import SnapKit
import Kingfisher

final class MedicationSearchTableViewCell: UITableViewCell {

    static let identifier = "MedicationSearchTableViewCell"

    // MARK: - Layout Constants

    private enum Layout {
        static let verticalSpacing: CGFloat = 0     // 셀 간 간격 (상하 각각)
        static let horizontalInset: CGFloat = 16     // 좌우 여백
        static let cellHeight: CGFloat = 60          // 최소 셀 높이
        static let imageSize: CGFloat = 48           // 이미지 크기
        static let checkmarkSize: CGFloat = 20       // 체크마크 크기
    }

    private let medicationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.tintColor = .lightGray
        imageView.image = UIImage(systemName: "pills")
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body1()
        label.textColor = AppColor.textBlack
        return label
    }()

    private let dosageLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.caption()
        label.textColor = AppColor.secondary
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark")
        imageView.tintColor = UIColor(hex: "#7FDD1C")
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.clear.cgColor
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        medicationImageView.kf.cancelDownloadTask()
        medicationImageView.image = UIImage(systemName: "pills")
        setSelected(false)
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(medicationImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(dosageLabel)
        containerView.addSubview(checkmarkImageView)

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(
                top: Layout.verticalSpacing,
                left: Layout.horizontalInset,
                bottom: Layout.verticalSpacing,
                right: Layout.horizontalInset
            ))
            $0.height.greaterThanOrEqualTo(Layout.cellHeight)
        }

        medicationImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(Layout.imageSize)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(medicationImageView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }

        dosageLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-8)
        }

        checkmarkImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(Layout.checkmarkSize)
        }
    }

    func configure(with medication: MedicationInfo, isSelected: Bool = false) {
        nameLabel.text = medication.name
        let pillInfo = medication.toPillInfo()
        dosageLabel.text = "\(pillInfo.takingDays)일 복용 / \(pillInfo.breakDays)일 휴약"
        setImage(urlString: medication.imageURL)
        setSelected(isSelected)
    }

    private func setSelected(_ selected: Bool) {
        if selected {
            containerView.backgroundColor = UIColor(hex: "#7FDD1C")?.withAlphaComponent(0.1)
            containerView.layer.borderColor = UIColor(hex: "#7FDD1C")?.cgColor
            checkmarkImageView.isHidden = false
        } else {
            containerView.backgroundColor = .white
            containerView.layer.borderColor = UIColor.clear.cgColor
            checkmarkImageView.isHidden = true
        }
    }

    private func setImage(urlString: String) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            medicationImageView.image = UIImage(systemName: "pills")
            return
        }

        medicationImageView.kf.setImage(
            with: url,
            placeholder: UIImage(systemName: "pills"),
            options: [
                .cacheOriginalImage,
                .transition(.fade(0.2))
            ]
        )
    }
}
