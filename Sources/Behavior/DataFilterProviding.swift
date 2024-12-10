import Foundation
import Fuse

@MainActor
public protocol DataFilterProviding where Self: AnyObject {
    associatedtype FilterableType: Comparable, Filterable
    
    var searchTerm: String { get set }
}

public protocol Filterable {
    var filterId: String { get }
}

public extension DataFilterProviding {
    
    func updateSearchTerm(_ s: String?) {
        self.searchTerm = s?
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .lowercased()
            .passThrough({ !$0.isEmpty }) ?? ""
    }
    
    func filter(data: [FilterableType]) -> [FilterableType] {
        
        guard !self.searchTerm.isEmpty else {
            return data.sorted()
        }
        
        let fuse = Fuse(tokenize:true)
        let pattern = fuse.createPattern(from: self.searchTerm)
        return data.compactMap { (item) -> (FilterableType, Double)? in
                guard let score = fuse.search(pattern, in: item.filterId)?.score else { return nil }
                return score <= 45 ? (item, score) : nil
            }.lazy.sorted(by: { $0.1 < $1.1 }).map { $0.0 }
    }
}
