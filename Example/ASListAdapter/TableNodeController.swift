import Foundation
import AsyncDisplayKit

import ASListAdapter

class TableNodeController: ASViewController<ASTableNode> {
    
    lazy var listAdapter = ASListAdapter(self.node)
    private var lastIndex: Int = 0
    
    init() {
        super.init(node: .init())
        self.node.backgroundColor = .white
        
        // make cellFactory
        self.listAdapter.cellFactory(type: TestModel.self, { model -> ASCellNode in
            let cellNode = TestCellNode(model)
            
            return cellNode
        })
        
        // fetch items
        self.listAdapter.fetchItem(type: TestModel.self,
                                   section: 0,
                                   items: createItems(),
                                   scope: .append)
    }
    
    func appendMore() {
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
