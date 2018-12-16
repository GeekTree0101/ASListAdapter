import Foundation
import AsyncDisplayKit

class TestCellNode: ASCellNode {
    
    let titleNode = ASButtonNode()
    
    init(_ model: TestModel) {
        super.init()
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
        titleNode.backgroundColor = UIColor.random()
        titleNode.cornerRadius = 10.0
        titleNode.style.height = .init(unit: .points, value: 120.0)
        titleNode.setTitle(model.title,
                           with: UIFont.systemFont(ofSize: 30.0, weight: .medium),
                           with: .white,
                           for: .normal)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec.init(insets: .init(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0),
                                      child: titleNode)
    }
}

extension UIColor {
    
    static func random() -> UIColor {
        let blue1 = UIColor.init(red: 20 / 255, green: 86 / 255, blue: 250 / 255, alpha: 1.0)
        let blue2 = UIColor.init(red: 13 / 255, green: 162 / 255, blue: 245 / 255, alpha: 1.0)
        let blue3 = UIColor.init(red: 0, green: 214 / 255, blue: 237 / 255, alpha: 1.0)
        let blue4 = UIColor.init(red: 0, green: 236 / 255, blue: 195 / 255, alpha: 1.0)
        let arr: [UIColor] = [blue1, blue2, blue3, blue4]
        return arr.randomElement() ?? .gray
    }
}
