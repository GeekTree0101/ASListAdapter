import Foundation
import AsyncDisplayKit
import RxCocoa
import RxSwift

import ASListAdapter

class RxBaseTableNodeController: ASViewController<ASTableNode>, ASTableDelegate {
    
    lazy var listAdapter = ASListAdapter(self.node)
    private var lastIndex: Int = 0
    var modelItemRelay = PublishRelay<[TestModel]>()
    let disposeBag = DisposeBag()
    
    init() {
        super.init(node: .init())
        self.node.backgroundColor = .white
        
        // make cellFactory
        self.listAdapter.cellFactory(type: TestModel.self, { model -> ASCellNode in
            let cellNode = TestCellNode(model)
            
            return cellNode
        })
        
        // bind fetch-binder with item list relay
        modelItemRelay
            .bind(to: listAdapter.rx.fetch(type: TestModel.self,
                                           section: 0,
                                           scope: .append))
            .disposed(by: disposeBag)
        
        // did select cell with indexPath
        listAdapter.rx
            .didSelect(type: TestModel.self, section: 0, { [weak self] model in
                self?.appendMore()
            }).disposed(by: disposeBag)
        
        self.appendMore()
    }
    
    func appendMore() {
        modelItemRelay.accept(createItems())
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
