import UIKit
import Combine
import SPAExtensions

public enum ListSection: Int, CaseIterable, Sendable {
    case cards
    case list
}

@MainActor
public struct Item: Identifiable, Comparable, Hashable {
    
    public let id: String = UUID().uuidString
    
    /// Ensure uniqueness of elements by comparing UUIDs
    nonisolated public static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Ensure desired sorting order by providing appropriate `sortId`s.
    nonisolated public static func < (lhs: Item, rhs: Item) -> Bool {
        return lhs.sortId < rhs.sortId
    }
    
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public let sortId: String
    public let data: (any Hashable & Sendable)?
    
    public let isToggle: Bool
    
    public let title: String
    public let image: UIImage?
    
    public let cellRegistration: UICollectionView.CellRegistration<ListCell, Item>
    
    public let didSelectItem: (Item, IndexPath, ListCell)->()
    
    public let isSelected = CurrentValueSubject<Bool, Never>(false)
    
    public let widthDivisor: CGFloat
    public let height: CGFloat
    
    public init(sortId: String = "",
                data: (any Hashable & Sendable)? = nil,
                title: String,
                image: UIImage? = nil,
                isToggle: Bool = false,
                widthDivisor: CGFloat = 1,
                height: CGFloat = 44,
                cellRegistration: UICollectionView.CellRegistration<ListCell, Item> = Self.defaultCellRegistration,
                didSelectItem: @escaping(Item, IndexPath, ListCell)->() = Self.getDefaultAction()) {
        
        self.sortId = sortId
        self.data = data
        self.title = title
        self.image = image
        self.isToggle = isToggle
        self.widthDivisor = widthDivisor == 0 ? 1: widthDivisor
        self.height = height
        self.cellRegistration = cellRegistration
        self.didSelectItem = didSelectItem
    }
    
    public static func getDefaultAction() -> (Item, IndexPath, ListCell)->() {
        return { item, indexPath, cell in
            return
        }
    }
    
    public static func getCheckmarkAction() -> (Item, IndexPath, ListCell)->() {
        return { item, indexPath, cell in
            item.isSelected.send(cell.toggleCheckmark())
        }
    }
    
    public static let defaultCellRegistration: UICollectionView.CellRegistration<ListCell, Item> =
        .init(handler: { cell, indexPath, item in
            var contentConfiguration = UIListContentConfiguration.subtitleCell()
            contentConfiguration.text = item.title
            contentConfiguration.image = item.image
            contentConfiguration.imageProperties.maximumSize = CGSize(width: 28, height: 28)
            contentConfiguration.imageToTextPadding = 8
            
            cell.contentConfiguration = contentConfiguration
            cell.wrapperView.borders = Borders(top: Border(width: 1, color: .lightGray))
        })
}

open class ListViewController: UIViewController, DataFilterProviding, NavigationProviding {
    
    public typealias FilterableType = Item
    @Published public var searchTerm: String = ""
    
    public enum NavigationAction {
        case selected(Item, IndexPath)
        case toggled(Item, IndexPath)
        case dismissed
    }
    public var navigation: any Publisher<NavigationAction, Never> {
        _navigation.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    private let _navigation = PassthroughSubject<NavigationAction, Never>()
    
    public var cellSpacing: CGFloat = 0
    
    public var cache = [Item]()
    public var filtered = [Item]()
    
    public var cancellables = [AnyCancellable]()
    
    func showEmptyState(_ shouldShow: Bool) {
        shouldShow ? self.showEmptyState() : self.hideEmptyState()
        
        self.searchController.searchBar.isHidden = self.filtered.isEmpty && !self.searchController.isActive
    }
    
    final public func update(with items: [Item],
                completion: @escaping(UICollectionView)->() = { _ in }) {
//        if !items.isEmpty {
            self.cache = items
            self.filtered = items
//        }
        self.update(completion: completion)
    }
    
    open func update(completion: @escaping(UICollectionView)->() = { _ in }) {
        self.filtered = self.filter(data: self.cache)
//        Async.background {
            self.dataSource.apply(self.createSnapshot(), animatingDifferences: true, completion: {
                completion(self.collectionView)
            })
//        }
        self.showEmptyState(filtered.isEmpty)
    }
    
    open func createSnapshot() -> NSDiffableDataSourceSnapshot<ListSection, Item.ID> {
        var snapshot = NSDiffableDataSourceSnapshot<ListSection, Item.ID>()
        snapshot.appendSections([.list])
        snapshot.appendItems(self.filtered.map { $0.id }, toSection: .list)
        return snapshot
    }
    
    open func createLayout() -> UICollectionViewLayout {
        return UICollectionViewFlowLayout()
    }
    
    open func getItem(for indexPath: IndexPath) -> Item {
        return self.filtered[indexPath.row]
    }
    
    public private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactiveWithAccessory
//        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return collectionView
    }()
    
    public private(set) lazy var dataSource: UICollectionViewDiffableDataSource<ListSection, Item.ID> = {
        let dataSource = UICollectionViewDiffableDataSource<ListSection, Item.ID>(
            collectionView: collectionView) { collectionView, indexPath, identifier -> ListCell in
            
                let item = self.getItem(for: indexPath)
                let cell = collectionView.dequeueConfiguredReusableCell(using: item.cellRegistration,
                                                                        for: indexPath,
                                                                        item: item)
                return cell
        }
        return dataSource
    }()
    
    public private(set) lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = Localized.string("Search" ++ self.title?.lowercased())
        return searchController
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addEnclosedSubview(collectionView)
        collectionView.dataSource = dataSource
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        self.$searchTerm.receive(on: DispatchQueue.main).sink { term in
            self.update()
        }.store(in: &cancellables)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard previousTraitCollection != nil else { return }
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    public func addPullToRefresh(_ action: @escaping ()->Void) {
        let refreshControl = UIRefreshControl()
        refreshControl.addAction(for: .valueChanged, {
            refreshControl.endRefreshing()
            action()
        })
        self.collectionView.refreshControl = refreshControl
    }
    
    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if self.navigationItem.searchController?.isActive ?? false,
           self.presentingViewController != nil { // fix issue with navigation when presented
            self.navigationItem.searchController?.dismiss(animated: true)
        }
        super.dismiss(animated: flag, completion: completion)
    }
}

extension ListViewController: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let item = self.getItem(for: indexPath)
        if let cell = collectionView.cellForItem(at: indexPath) as? ListCell {
            item.didSelectItem(item, indexPath, cell)
            
            if item.isToggle {
                self._navigation.send(.toggled(item, indexPath))
            }
            else {
                self._navigation.send(.selected(item, indexPath))
            }
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension ListViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let divisor = filtered[indexPath.row].widthDivisor
        return CGSize(width: (collectionView.bounds.width / divisor) - (cellSpacing * (divisor + 1) / divisor),
                      height: filtered[indexPath.row].height)
    }

    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {

        return UIEdgeInsets(top: cellSpacing, left: cellSpacing, bottom: cellSpacing, right: cellSpacing)
    }

    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {

        return cellSpacing
    }

    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {

        return 0
    }
}

extension ListViewController: UISearchResultsUpdating {
    
    public func updateSearchResults(for searchController: UISearchController) {
        self.updateSearchTerm(searchController.searchBar.text)
        
        if self.navigationItem.searchController?.isActive ?? false, !self.filtered.isEmpty {
            self.collectionView.setContentOffset(CGPoint(x: 0, y: -self.view.safeAreaInsets.top), animated: true)
        }
    }
}

extension Item: Filterable {
    nonisolated public var filterId: String {
        return title
    }
}

extension ListViewController: UISearchBarDelegate {
}



public class ListCell: UICollectionViewListCell {
    
    public let wrapperView: StyleView
    
    public override init(frame: CGRect) {
        self.wrapperView = StyleView(frame: .zero)
        super.init(frame: frame)
        
        self.addEnclosedSubview(wrapperView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    public override func prepareForReuse() {
        contentConfiguration = nil
    }
}

public extension ListCell {
    
    @discardableResult
    func toggleCheckmark() -> Bool {
        if hasCheckmark() {
            self.wrapperView.backgroundColor = .clear
            self.accessories.removeAll(where: { $0.accessoryType == UICellAccessory.AccessoryType.checkmark })
            return false
        }
        else {
            self.wrapperView.backgroundColor = .lightGray.withAlphaComponent(0.5)
            self.accessories.append(UICellAccessory.checkmark())
            return true
        }
    }
    
    func hasCheckmark() -> Bool {
        return self.accessories.contains(where: { $0.accessoryType == UICellAccessory.AccessoryType.checkmark })
    }
}
