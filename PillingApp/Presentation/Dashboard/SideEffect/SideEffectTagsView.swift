import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class SideEffectTagsView: UIView {
    
    // MARK: - Properties

    private let userDefaultsManager: UserDefaultsManagerProtocol
    private var sideEffectTags: [SideEffectTag] = []
    private var selectedTagIds: Set<String> = []

    // MARK: - Observables

    let addButtonTapped = PublishRelay<Void>()
    
    // MARK: - UI Components
    
    private let sectionLabel: UILabel = {
        let label = UILabel()
        label.text = AppStrings.SideEffectTag.sectionTitle
        label.font = Typography.body1(.semibold)
        label.textColor = AppColor.textBlack
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = createCollectionViewLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SideEffectTagCell.self, forCellWithReuseIdentifier: SideEffectTagCell.identifier)
        collectionView.register(SideEffectAddButtonCell.self, forCellWithReuseIdentifier: SideEffectAddButtonCell.identifier)
        return collectionView
    }()
    
    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    // MARK: - Initialization
    
    init(userDefaultsManager: UserDefaultsManagerProtocol) {
        self.userDefaultsManager = userDefaultsManager
        super.init(frame: .zero)
        setupViews()
        loadSideEffectTags()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        addSubview(containerStack)

        containerStack.addArrangedSubview(sectionLabel)
        containerStack.addArrangedSubview(collectionView)

        containerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 초기 최소 높이 설정 (1~2줄 정도)
        collectionView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // CollectionView의 컨텐츠 크기에 맞게 높이 조정
        collectionView.layoutIfNeeded()
        let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        if contentHeight > 0 {
            collectionView.snp.remakeConstraints { make in
                make.height.equalTo(contentHeight)
            }
        }
    }
    
  
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(80),
            heightDimension: .absolute(36)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(36)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        group.interItemSpacing = .fixed(8)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
        
        return layout
    }
    
    // MARK: - Public Methods

    func reloadTags() {
        loadSideEffectTags()
        collectionView.reloadData()
        setNeedsLayout()
        layoutIfNeeded()
    }

    func getSelectedTagIds() -> [String] {
        return Array(selectedTagIds)
    }

    func setSelectedTagIds(_ ids: [String]) {

        selectedTagIds = Set(ids)

        collectionView.reloadData()
        setNeedsLayout()
        layoutIfNeeded()
    }

    func clearSelection() {
        selectedTagIds.removeAll()
        collectionView.reloadData()
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    // MARK: - Private Methods
    
    private func loadSideEffectTags() {
        let allTags = userDefaultsManager.loadSideEffectTags()
        sideEffectTags = allTags.filter { $0.isVisible }.sorted { $0.order < $1.order }
    }
}

// MARK: - UICollectionViewDataSource

extension SideEffectTagsView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sideEffectTags.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == sideEffectTags.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SideEffectAddButtonCell.identifier, for: indexPath) as! SideEffectAddButtonCell
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SideEffectTagCell.identifier, for: indexPath) as! SideEffectTagCell
        let tag = sideEffectTags[indexPath.item]
        let isSelected = selectedTagIds.contains(tag.id)

        cell.configure(with: tag.name, isSelected: isSelected)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension SideEffectTagsView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == sideEffectTags.count {
            addButtonTapped.accept(())
            return
        }

        let tag = sideEffectTags[indexPath.item]
        if selectedTagIds.contains(tag.id) {
            selectedTagIds.remove(tag.id)
        } else {
            selectedTagIds.insert(tag.id)
        }

        collectionView.reloadItems(at: [indexPath])
    }
}
