import UIKit
import SnapKit

/// 마지막 아이템으로 노출되는 “+ 추가” 칩 셀
final class SideEffectAddButtonCell: UICollectionViewCell {

    // MARK: - Reuse Identifier
    static let identifier = "SideEffectAddButtonCell"

    // MARK: - UI

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "plus"))
        iv.contentMode = .scaleAspectFit
        iv.tintColor = AppColor.pillGreen800
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.caption(.semibold)
        label.textColor = AppColor.green800
        label.text = AppStrings.SideEffectTag.addButton
        return label
    }()

    private let stack: UIStackView = {
        let st = UIStackView()
        st.axis = .horizontal
        st.alignment = .center
        st.spacing = 6
        return st
    }()

    private let padding = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = AppColor.card
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = AppColor.pillGreen800.withAlphaComponent(0.9).cgColor

        contentView.addSubview(stack)
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)

        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(padding)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        let size = contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let newAttributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes
        newAttributes.size = CGSize(width: ceil(size.width), height: ceil(size.height))
        return newAttributes
    }
}
