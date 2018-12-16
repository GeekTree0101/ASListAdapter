import RxSwift
import RxCocoa
import AsyncDisplayKit.ASCellNode

protocol ASListAdapterProtocol {
    
    var itemCount: Int { get }
    func generateCellNode(_ indexPath: IndexPath) -> ASCellNode
}

public struct ASListAdapterContext<Item: Hashable>: ASListAdapterProtocol {
    
    typealias CellFactory = (Item) -> ASCellNode
    
    var items: [Item] {
        set {
            let beforeItems = _itemsRelay.value
            let diff = ASListAdapterDiffHelper.diff(beforeItems, newValue)
            let context = ASListAdpaterUpdateContext(diff, section)
            _itemsRelay.accept(newValue)
            self.fetchUpdateWithDiffContext(context)
        }
        get {
            return _itemsRelay.value
        }
    }
    
    var itemCount: Int {
        return items.count
    }
    
    public var section: Int
    private let _itemsRelay = BehaviorRelay<[Item]>(value: [])
    private var factory: CellFactory
    let disposeBag = DisposeBag()
    
    let fetchUpdateWithDiffContextRelay = PublishRelay<ASListAdpaterUpdateContext>()
    
    init(_ section: Int, items: [Item], factory: @escaping CellFactory) {
        self.section = section
        self.factory = factory
        self.items = items
    }
    
    internal func generateCellNode(_ indexPath: IndexPath) -> ASCellNode {
        guard indexPath.row < items.count else { return ASCellNode() }
        return self.factory(items[indexPath.row])
    }
    
    private func fetchUpdateWithDiffContext(_ context: ASListAdpaterUpdateContext) {
        self.fetchUpdateWithDiffContextRelay.accept(context)
    }
}

public struct ASSingleListItem: Hashable {
    static let single: [ASSingleListItem] = [.init()]
}
