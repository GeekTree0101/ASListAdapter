import Foundation
import AsyncDisplayKit

import ASListAdapter

class CollectionNodeController: ASViewController<ASCollectionNode> {
    
    lazy var listAdapter = ASListAdapter(self.node)
    private var lastIndex: Int = 0
    
    init() {
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.scrollDirection = .vertical
        flowLayout.itemSize = .init(width: UIScreen.main.bounds.width, height: 300)
        super.init(node: .init(collectionViewLayout: flowLayout))
        self.node.backgroundColor = .white
        
        // make cellFactory
        self.listAdapter.cellFactory(type: TestModel.self, { [weak self] model -> ASCellNode in
            let cellNode = TestCellNode(model)
            cellNode.titleNode.addTarget(self,
                                         action: #selector(self?.appendMore),
                                         forControlEvents: .touchUpInside)
            return cellNode
        })
        
        // fetch items
        self.listAdapter.fetchItem(type: TestModel.self,
                                   section: 0,
                                   items: createItems(),
                                   scope: .append)
    }
    
    @objc func appendMore() {
        self.listAdapter.fetchItem(type: TestModel.self,
                                   section: 0,
                                   items: createItems(),
                                   scope: .append)
    }
    
    func createItems() -> [TestModel] {
        let items = (lastIndex ... lastIndex + 5).map({ TestModel.init("Item-\($0)") })
        lastIndex += items.count
        return items
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
