import AsyncDisplayKit
import Foundation

struct ASListAdapterDiffHelper {
    
    enum DiffOperation: Equatable {
        case insert(Int)
        case delete(Int)
        case move(Int, Int)
        case update(Int)
        
        public static func == (lhs: DiffOperation, rhs: DiffOperation) -> Bool {
            switch (lhs, rhs) {
            case let (.insert(l), .insert(r)),
                 let (.delete(l), .delete(r)),
                 let (.update(l), .update(r)): return l == r
            case let (.move(l), .move(r)): return l == r
            default: return false
            }
        }
    }
    
    enum DiffCounter {
        case zero
        case one
        case many
        
        mutating func increment() {
            switch self {
            case .zero:
                self = .one
            case .one:
                self = .many
            case .many:
                break
            }
        }
    }
    
    class SymbolDiffEntry {
        var oc: DiffCounter = .zero
        var nc: DiffCounter = .zero
        var olno = [Int]()
        
        var occursInBoth: Bool {
            return oc != .zero && nc != .zero
        }
    }
    
    enum DiffEntry {
        case symbol(SymbolDiffEntry)
        case index(Int)
    }
    
    static func diff<T: Swift.Collection>(_ old: T, _ new: T)
        -> [DiffOperation] where T.Iterator.Element: Hashable, T.Index == Int {
            var table = [Int: SymbolDiffEntry]()
            var oldArray = [DiffEntry]()
            var newArray = [DiffEntry]()
            
            for item in new {
                let diffEntry = table[item.hashValue] ?? SymbolDiffEntry()
                table[item.hashValue] = diffEntry
                diffEntry.nc.increment()
                newArray.append(.symbol(diffEntry))
            }
            
            for (index, item) in old.enumerated() {
                let diffEntry = table[item.hashValue] ?? SymbolDiffEntry()
                table[item.hashValue] = diffEntry
                diffEntry.oc.increment()
                diffEntry.olno.append(index)
                oldArray.append(.symbol(diffEntry))
            }
            
            for (index, item) in newArray.enumerated() {
                if case let .symbol(diffEntry) = item, diffEntry.occursInBoth, !diffEntry.olno.isEmpty {
                    
                    let oldIndex = diffEntry.olno.removeFirst()
                    newArray[index] = .index(oldIndex)
                    oldArray[oldIndex] = .index(index)
                }
            }
            
            var iter = 1
            while iter < newArray.count - 1 {
                if case let .index(arrayItem) = newArray[iter], arrayItem + 1 < oldArray.count,
                    case let .symbol(newDiffEntry) = newArray[iter + 1],
                    case let .symbol(oldDiffEntry) = oldArray[arrayItem + 1], newDiffEntry === oldDiffEntry {
                    newArray[iter + 1] = .index(arrayItem + 1)
                    oldArray[arrayItem + 1] = .index(iter + 1)
                }
                
                iter += 1
            }
            
            iter = newArray.count - 1
            while iter > 0 {
                if case let .index(j) = newArray[iter], j - 1 >= 0,
                    case let .symbol(newDiffEntry) = newArray[iter - 1],
                    case let .symbol(oldDiffEntry) = oldArray[j - 1], newDiffEntry === oldDiffEntry {
                    newArray[iter - 1] = .index(j - 1)
                    oldArray[j - 1] = .index(iter - 1)
                }
                
                iter -= 1
            }
            
            var steps = [DiffOperation]()
            
            var deleteOffsets = Array(repeating: 0, count: old.count)
            var runningOffset = 0
            for (index, item) in oldArray.enumerated() {
                deleteOffsets[index] = runningOffset
                if case .symbol = item {
                    steps.append(.delete(index))
                    runningOffset += 1
                }
            }
            
            runningOffset = 0
            
            for (index, item) in newArray.enumerated() {
                switch item {
                case .symbol:
                    steps.append(.insert(index))
                    runningOffset += 1
                case let .index(oldIndex):
                    if old[oldIndex] != new[index] {
                        steps.append(.update(index))
                    }
                    
                    let deleteOffset = deleteOffsets[oldIndex]
                    if (oldIndex - deleteOffset + runningOffset) != index {
                        steps.append(.move(oldIndex, index))
                    }
                }
            }
            
            return steps
    }
    
}

struct ASListAdpaterUpdateContext {
    
    var deletions = [IndexPath]()
    var insertions = [IndexPath]()
    var updates = [IndexPath]()
    var moves = [(from: IndexPath, to: IndexPath)]()
    
    init(_ result: [ASListAdapterDiffHelper.DiffOperation],
         _ section: Int) {
        
        for step in result {
            switch step {
            case .delete(let index):
                deletions.append(IndexPath(row: index, section: section))
            case .insert(let index):
                insertions.append(IndexPath(row: index, section: section))
            case .update(let index):
                updates.append(IndexPath(row: index, section: section))
            case let .move(fromIndex, toIndex):
                moves.append((from: IndexPath(row: fromIndex, section: section), to: IndexPath(row: toIndex, section: section)))
            }
        }
    }
}

extension ASTableNode {

    func applyDiff(update: ASListAdpaterUpdateContext,
                   withAnimation animation: UITableView.RowAnimation = .automatic,
                   reloadUpdated: Bool = true) {
        
        deleteRows(at: update.deletions, with: animation)
        insertRows(at: update.insertions, with: animation)
        for move in update.moves {
            moveRow(at: move.from, to: move.to)
        }
        
        if reloadUpdated && update.updates.count > 0 {
            reloadRows(at: update.updates, with: animation)
        }
    }
}

extension ASCollectionNode {
    
    func applyDiff(update: ASListAdpaterUpdateContext,
                   reloadUpdated: Bool = true,
                   completion: ((Bool) -> Void)?,
                   animated: Bool = true) {
        
        performBatch(animated: animated, updates: {
            self.deleteItems(at: update.deletions)
            self.insertItems(at: update.insertions)
            for move in update.moves {
                self.moveItem(at: move.from, to: move.to)
            }
        }, completion: reloadUpdated ? nil : completion)
        
        if reloadUpdated {
            performBatch(animated: animated, updates: {
                self.reloadItems(at: update.updates)
            }, completion: completion)
        }
    }
}
