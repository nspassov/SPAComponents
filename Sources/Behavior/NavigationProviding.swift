import Foundation
import Combine

@MainActor
public protocol NavigationProviding {
    associatedtype Action
    
    var navigation: any Publisher<Action, Never> { get }
}
