import UIKit
import SnapKit

final class DashboardCalendarView: UIView {
    
    // MARK: - Section Definition
    
    enum Section: Hashable {
        case calendar
    }
    
    // MARK: - Properties
    
    private typealias str = AppStrings.Dashboard
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, DayItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DayItem>
    
    private var dataSource: DataSource!
    private var currentItems: [DayItem] = []
    
    var onCellSelected: ((Int, DayItem) -> Void)?
    
    // MARK: - UI Components
    
    private let weekdayStackView = UIStackView()
    
    private lazy var collectionView: UICollectionView = {
        let layout = makeCompositionalLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.contentInset = .zero
        cv.isScrollEnabled = false
        cv.showsVerticalScrollIndicator = false
        cv.showsHorizontalScrollIndicator = false
        cv.register(DashboardCalendarCell.self, forCellWithReuseIdentifier: DashboardCalendarCell.identifier)
        cv.delegate = self
        return cv
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        configureDiffableDataSource()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        setupWeekdayStackView()
        
        addSubview(weekdayStackView)
        addSubview(collectionView)
    }
    
    private func setupWeekdayStackView() {
        weekdayStackView.axis = .horizontal
        weekdayStackView.alignment = .fill
        weekdayStackView.distribution = .fillEqually
        weekdayStackView.spacing = 0
        
        str.weekdays.forEach { weekdayText in
            let containerView = UIView()
            let label = UILabel()
            label.text = weekdayText
            label.textAlignment = .center
            label.textColor = AppColor.weekdayText
            label.font = Typography.caption(.medium)
            containerView.addSubview(label)
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.leading.trailing.equalToSuperview()
            }
            weekdayStackView.addArrangedSubview(containerView)
        }
    }
    
    private func setupConstraints() {
        weekdayStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(weekdayStackView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Diffable DataSource
    
    private func configureDiffableDataSource() {
        dataSource = DataSource(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DashboardCalendarCell.identifier,
                for: indexPath
            ) as? DashboardCalendarCell else {
                return UICollectionViewCell()
            }
            
            cell.configure(with: item)
            return cell
        }
    }
    
    // MARK: - Public Methods - Smart Updates
    
    /// Initial data load or complete refresh
    func applySnapshot(with items: [DayItem], animated: Bool = true) {
        currentItems = items
        
        var snapshot = Snapshot()
        snapshot.appendSections([.calendar])
        snapshot.appendItems(items, toSection: .calendar)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    /// Update single item - most efficient for pill status changes
    func updateItem(_ updatedItem: DayItem, animated: Bool = true) {
        guard let existingIndex = currentItems.firstIndex(where: { $0.id == updatedItem.id }) else { return }
        
        currentItems[existingIndex] = updatedItem
        
        var snapshot = dataSource.snapshot()
        
        // Use reconfigureItems for optimal performance
        if snapshot.itemIdentifiers.contains(where: { $0.id == updatedItem.id }) {
            snapshot.reconfigureItems([updatedItem])
        }
        
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    /// Update multiple items - efficient for batch changes
    func updateItems(_ updatedItems: [DayItem], animated: Bool = true) {
        var snapshot = dataSource.snapshot()
        var itemsToReconfigure: [DayItem] = []
        
        for updatedItem in updatedItems {
            if let existingIndex = currentItems.firstIndex(where: { $0.id == updatedItem.id }) {
                currentItems[existingIndex] = updatedItem
                
                if snapshot.itemIdentifiers.contains(where: { $0.id == updatedItem.id }) {
                    itemsToReconfigure.append(updatedItem)
                }
            }
        }
        
        if !itemsToReconfigure.isEmpty {
            snapshot.reconfigureItems(itemsToReconfigure)
        }
        
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    /// Update item by date - convenient for pill recording
    func updateItemForDate(_ date: Date, with newStatus: PillStatus, animated: Bool = true) {
        guard let existingItem = currentItems.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }) else { return }
        
        let updatedItem = DayItem(
            id: existingItem.id,  // Preserve ID for reconfigureItems to work
            cycleDay: existingItem.cycleDay,
            date: existingItem.date,
            status: newStatus,
            scheduledDateTime: existingItem.scheduledDateTime
        )
        
        updateItem(updatedItem, animated: animated)
    }
    
    /// Reload all items - use when structure changes
    func reloadAllItems(_ items: [DayItem], animated: Bool = false) {
        applySnapshot(with: items, animated: animated)
    }
    
    func updateWeekdayStart(from startDate: Date) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: startDate)
        
        let baseWeekdays = str.weekdays
        
        let startIndex: Int = {
            switch weekday {
            case 2: return 0
            case 3: return 1
            case 4: return 2
            case 5: return 3
            case 6: return 4
            case 7: return 5
            case 1: fallthrough
            default: return 6
            }
        }()
        
        let rotatedWeekdays = Array(baseWeekdays[startIndex...]) + Array(baseWeekdays[..<startIndex])
        
        guard weekdayStackView.arrangedSubviews.count == 7 else { return }
        
        for (index, view) in weekdayStackView.arrangedSubviews.enumerated() {
            if let label = view.subviews.first(where: { $0 is UILabel }) as? UILabel {
                label.text = rotatedWeekdays[index]
            }
        }
    }
    
    func updateLayout() {
        collectionView.setCollectionViewLayout(makeCompositionalLayout(), animated: false)
        layoutIfNeeded()
    }
    
    // MARK: - Layout
    
    private func calculateOptimalLayout() -> (cellSize: CGFloat, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        let availableWidth = bounds.width
        let columns: CGFloat = 7
        let minCellSize: CGFloat = 40
        let minHorizontalSpacing: CGFloat = 2
        let maxHorizontalSpacing: CGFloat = 16
        let minVerticalSpacing: CGFloat = 12
        let maxVerticalSpacing: CGFloat = 24
        
        var bestCellSize: CGFloat = minCellSize
        var bestHorizontalSpacing: CGFloat = minHorizontalSpacing
        
        for horizontalSpacing in stride(from: minHorizontalSpacing, through: maxHorizontalSpacing, by: 1) {
            let totalHorizontalSpacing = horizontalSpacing * (columns - 1)
            let cellSize = (availableWidth - totalHorizontalSpacing) / columns
            
            if cellSize >= minCellSize {
                bestCellSize = cellSize
                bestHorizontalSpacing = horizontalSpacing
            }
        }
        
        let verticalSpacing: CGFloat = {
            if bestCellSize < 45 {
                return minVerticalSpacing
            } else if bestCellSize < 50 {
                return 18
            } else if bestCellSize < 55 {
                return 20
            } else if bestCellSize < 60 {
                return 22
            } else {
                return maxVerticalSpacing
            }
        }()
        
        return (bestCellSize, bestHorizontalSpacing, verticalSpacing)
    }
    
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let layout = calculateOptimalLayout()
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(layout.cellSize),
            heightDimension: .absolute(layout.cellSize)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(layout.cellSize)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        group.interItemSpacing = .fixed(layout.horizontalSpacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = layout.verticalSpacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - UICollectionViewDelegate

extension DashboardCalendarView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        if case .scheduled = item.status { return }
        if case .rest = item.status { return }
        
        let calendar = Calendar.current
        let isToday = calendar.isDate(item.date, inSameDayAs: Date())

        if !isToday || item.status.isTaken {
            DIContainer.shared.getAnalyticsService().logEvent(.calendarCellTapped(cycleDay: item.cycleDay))
            onCellSelected?(indexPath.item, item)
        }
    }
}
