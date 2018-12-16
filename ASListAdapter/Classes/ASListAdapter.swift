import AsyncDisplayKit
import RxSwift
import RxCocoa

public protocol ASListTypeProtocol { }
extension ASTableNode: ASListTypeProtocol { }
extension ASCollectionNode: ASListTypeProtocol { }

extension Reactive where Base: ASListAdapter {
    
    public typealias FetchScope = ASListAdapter.ASListAdapterFetchScope
    
    public func didSelect<Item: Hashable>(type: Item.Type,
                                section: Int,
                                _ handler: @escaping (Item?) -> Void) -> Disposable {
        
        return base.didSelectIndexPathRelay
            .filter({ $0.section == section })
            .map { $0.row }
            .withLatestFrom(Observable.just(base.contexts)) { ($0, $1) }
            .map({ index, contexts -> Item? in
                guard let context = contexts[section] as? ASListAdapterContext<Item>,
                    index < context.items.count else {
                    return nil
                }
                return context.items[index]
            })
            .map(handler)
            .subscribe()
    }
    
    public func fetch<Item: Hashable>(type: Item.Type,
                                      section: Int,
                                      scope: FetchScope) -> Binder<[Item]> {
        return Binder(base) { adapter, items in
            adapter.fetchItem(type: type,
                              section: section,
                              items: items,
                              scope: scope)
        }
    }
}

public class ASListAdapter: NSObject {
    
    internal let didSelectIndexPathRelay = PublishRelay<IndexPath>()
    
    private let listTypeNode: ASListTypeProtocol
    fileprivate var contexts: [ASListAdapterProtocol] = []
    private let disposeBag = DisposeBag()
    
    public init(_ listTypeNode: ASListTypeProtocol) {
        self.listTypeNode = listTypeNode
        super.init()
        
        switch listTypeNode {
        case let tableNode as ASTableNode:
            tableNode.delegate = self
            tableNode.dataSource = self
        case let collectionNode as ASCollectionNode:
            collectionNode.delegate = self
            collectionNode.dataSource = self
        default:
            fatalError("listTypeNode should be ASTableNode or ASCollectionNode")
        }
    }
    
    public func reloadData() {
        
        switch listTypeNode {
        case let tableNode as ASTableNode:
            tableNode.reloadData()
        case let collectionNode as ASCollectionNode:
            collectionNode.reloadData()
        default:
            fatalError("listTypeNode should be ASTableNode or ASCollectionNode")
        }
    }
    
    public func reloadSection(_ indexSet: IndexSet,
                              animate: UITableView.RowAnimation = .none) {
        
        switch listTypeNode {
        case let tableNode as ASTableNode:
            tableNode.reloadSections(indexSet, with: animate)
        case let collectionNode as ASCollectionNode:
            collectionNode.reloadSections(indexSet)
        default:
            fatalError("listTypeNode should be ASTableNode or ASCollectionNode")
        }
    }
    
    fileprivate func fetchUpdateWithDiffContext(_ diffContext: ASListAdpaterUpdateContext) {
        
        switch listTypeNode {
        case let tableNode as ASTableNode:
            tableNode.applyDiff(update: diffContext)
        case let collectionNode as ASCollectionNode:
            collectionNode.applyDiff(update: diffContext, completion: nil)
        default:
            fatalError("listTypeNode should be ASTableNode or ASCollectionNode")
        }
    }
    
    public func layoutIfNeeds() {
        
        guard let node = listTypeNode as? ASDisplayNode else { return }
        node.layoutIfNeeded()
        node.invalidateCalculatedLayout()
    }
}

extension ASListAdapter: ASTableDataSource, ASTableDelegate  {
    
    public func numberOfSections(in tableNode: ASTableNode) -> Int {
        return self.contexts.count
    }
    
    public func tableNode(_ tableNode: ASTableNode,
                          numberOfRowsInSection section: Int) -> Int {
        guard section < self.contexts.count else { return 0 }
        return self.contexts[section].itemCount
    }
    
    public func tableNode(_ tableNode: ASTableNode,
                          nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            guard indexPath.section < self.contexts.count else {
                return ASCellNode()
            }
            return self.contexts[indexPath.section].generateCellNode(indexPath)
        }
    }
    
    public func tableNode(_ tableNode: ASTableNode,
                          didSelectRowAt indexPath: IndexPath) {
        self.didSelectIndexPathRelay.accept(indexPath)
    }
}

extension ASListAdapter: ASCollectionDataSource, ASCollectionDelegate  {
    
    public func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return self.contexts.count
    }

    public func collectionNode(_ collectionNode: ASCollectionNode,
                               numberOfItemsInSection section: Int) -> Int {
        guard section < self.contexts.count else { return 0 }
        return self.contexts[section].itemCount
    }

    public func collectionNode(_ collectionNode: ASCollectionNode,
                               nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            guard indexPath.section < self.contexts.count else {
                return ASCellNode()
            }
            return self.contexts[indexPath.section].generateCellNode(indexPath)
        }
    }

    public func collectionNode(_ collectionNode: ASCollectionNode,
                               didSelectItemAt indexPath: IndexPath) {
        self.didSelectIndexPathRelay.accept(indexPath)
    }
}

extension ASListAdapter {
    
    public enum ASListAdapterFetchScope {
        case append
        case prepend
        case reload
    }
    
    public func cellFactory<Item: Hashable>(type: Item.Type,
                                  items: [Item] = [],
                                  _ factory: @escaping ((Item) -> ASCellNode)) {
        
        let count = contexts.count
        let context = ASListAdapterContext<Item>(count, items: items, factory: factory)
        
        context.fetchUpdateWithDiffContextRelay
            .subscribe(onNext: { [weak self] context in
                self?.fetchUpdateWithDiffContext(context)
            }).disposed(by: context.disposeBag)
        
        contexts.append(context)
    }
    
    public func fetchItem<Item: Hashable>(type: Item.Type,
                                          section: Int,
                                          items: [Item],
                                          scope: ASListAdapterFetchScope) {
        guard section < self.contexts.count,
            var context = self.contexts[section]
                as? ASListAdapterContext<Item> else { return }
        switch scope {
        case .append:
            context.items = context.items + items
        case .prepend:
            context.items = items + context.items
        case .reload:
            context.items = items
        }
    }
}
