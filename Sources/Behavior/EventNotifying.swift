import UIKit
import SwiftMessages
import SPAExtensions

public protocol EventNotifying {
}

extension UIViewController: EventNotifying {
}

@MainActor
public extension EventNotifying where Self: UIViewController {
    
    func present(error: CommonError) {
        let vc = UIAlertController(title: error.title,
                                   message: error.reason,
                                   preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: Localized.string("OK"),
                                   style: .cancel,
                                   handler: { _ in vc.dismiss(animated: true) }))
        self.present(vc, animated: true)
    }
}


@MainActor
public extension EventNotifying {
    
    func notify(_ item: CommonEvent.Item) {
        CommonEvent.enqueue(item: item)
    }
    
    func notify(_ error: CommonError, kind: CommonEvent.Kind = .error) {
        CommonEvent.enqueue(error: error, kind: kind)
    }
    
    func dismiss(_ id: String) {
        if id.isEmpty {
            CommonEvent.dequeueAll()
        }
        else {
            CommonEvent.dequeue(id: id)
        }
    }
}

@MainActor
public enum CommonEvent {
    private static var primaryQueue = [CommonEvent.Item]() {
        didSet {
            if let item = primaryQueue.first, secondaryQueue.isEmpty {
                item.show()
                primaryQueue.removeFirst()
            }
        }
    }
    
    private static var secondaryQueue = [CommonEvent.Item]() {
        didSet {
            if let item = secondaryQueue.first {
                item.show()
                secondaryQueue.removeFirst()
            }
        }
    }
    
    public struct Item: Sendable {
        let id: String
        let title: String
        let message: String
        let kind: Kind
        let icon: UIImage?
        let action: (@MainActor() async->())?
        
        public init(id: String = UUID().uuidString,
                    title: String,
                    message: String,
                    kind: Kind = .info,
                    icon: UIImage? = nil,
                    action: (@MainActor() async->())? = nil) {
            self.id = id
            self.title = title
            self.message = message
            self.kind = kind
            self.icon = icon
            self.action = action
        }
        
        @MainActor func show() {
            let layout: MessageView.Layout = (UIView.safeAreaInsetsOfMainWindow.top == 20)
                ? .messageView
                : .cardView
            let view = MessageView.viewFromNib(layout: layout)
//            if UIView.safeAreaInsetsOfMainWindow.top == 20 {
//                view.topLayoutMarginAddition = 40
//            }
            view.configureContent(title: self.title,
                                  body: self.message)
            view.button?.isHidden = true
            view.tapHandler = { _ in
                Task {
                    await self.action?()
                }
                if self.kind != .persistentError {
                    SwiftMessages.hide(id: self.id)
                }
            }
            view.configureTheme(backgroundColor: self.kind.backgroundColor,
                                foregroundColor: .white,
                                iconImage: self.icon ?? self.kind.icon)
            view.defaultHaptic = self.kind.haptic
            view.id = self.id
            
            SwiftMessages.show(config: self.config, view: view)
        }
    }
    
    public enum Kind: Sendable {
        case info
        case success
        case warning
        case error
        case persistentError
        case persistentInfo
        
        var title: String? {
            switch self {
            case .info:
                return Localized.string("Notice")
            default:
                return nil
            }
        }
    }
    
    static func enqueue(item: CommonEvent.Item) {
        if item.kind == .persistentInfo {
            CommonEvent.secondaryQueue.append(item)
        }
        else if !CommonEvent.primaryQueue.contains(where: { $0.id == item.id}) {
            CommonEvent.primaryQueue.append(item)
        }
    }
    
    static func enqueue(error: CommonError, kind: CommonEvent.Kind) {
        if kind == .persistentError {
            self.dequeueAll()
        }
        self.enqueue(item: CommonEvent.Item(id: kind == .persistentError ? "" : error.reason,
                                             title: kind.title ?? error.title,
                                             message: error.reason,
                                             kind: kind))
    }
    
    static func dequeue(id: String) {
        CommonEvent.primaryQueue.removeAll(where: { $0.id == id })
        
        SwiftMessages.hide(id: id)
    }
    
    static func dequeueAll() {
        CommonEvent.primaryQueue.removeAll()
        
        SwiftMessages.hideAll()
    }
}


extension CommonEvent.Item {
    var config: SwiftMessages.Config {
        switch kind {
        case .error, .warning:
            var config = SwiftMessages.Config()
            config.presentationContext = .window(windowLevel: .normal)
            config.dimMode = .gray(interactive: true)
            config.duration = .forever
            config.interactiveHide = true
            return config
            
        case .persistentError:
            var config = SwiftMessages.Config()
            config.presentationContext = .window(windowLevel: .normal)
            config.dimMode = .gray(interactive: false)
            config.duration = .forever
            config.interactiveHide = false
            return config
        
        case .info, .success:
            var config = SwiftMessages.Config()
            config.presentationContext = .window(windowLevel: .normal)
            config.dimMode = .none
            config.duration = .seconds(seconds: 5)
            config.interactiveHide = true
            return config
        
        case .persistentInfo:
            var config = SwiftMessages.Config()
            config.presentationContext = .window(windowLevel: .normal)
            config.dimMode = .none
            config.duration = .forever
            config.interactiveHide = true
            return config
        }
    }
}


extension CommonEvent.Kind {
    var haptic: SwiftMessages.Haptic? {
        switch self {
        case .success:
            return .success
        case .warning:
            return .warning
        case .error, .persistentError:
            return .error
        default:
            return nil
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .info, .persistentInfo:
            return UIColor.systemBlue
        case .success:
            return UIColor(red: 97.0/255.0, green: 161.0/255.0, blue: 23.0/255.0, alpha: 1.0)
        case .warning:
            return UIColor(red: 249.0/255.0, green: 66.0/255.0, blue: 47.0/255.0, alpha: 1.0)
        case .error:
            return UIColor(red: 249.0/255.0, green: 66.0/255.0, blue: 47.0/255.0, alpha: 1.0)
        case .persistentError:
            return UIColor.darkGray
        }
    }
    
    var icon: UIImage {
        switch self {
        case .info, .persistentInfo:
            return UIImage.system(name: "info.circle", configuration: .init(pointSize: 25, weight: .bold, scale: .large), tintColor: .white)!
        case .success:
            return UIImage.system(name: "checkmark.diamond", configuration: .init(pointSize: 25, weight: .bold, scale: .large), tintColor: .white)!
        case .warning:
            return UIImage.system(name: "exclamationmark.bubble", configuration: .init(pointSize: 25, weight: .bold, scale: .large), tintColor: .white)!
        case .error:
            return UIImage.system(name: "exclamationmark.octagon", configuration: .init(pointSize: 25, weight: .bold, scale: .large), tintColor: .white)!
        case .persistentError:
            return UIImage.system(name: "wifi.slash", configuration: .init(pointSize: 25, weight: .bold, scale: .large), tintColor: .white)!
        }
    }
}
