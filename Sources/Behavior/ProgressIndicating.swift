import UIKit
import SPAExtensions
import NVActivityIndicatorView

class ProgressIndicatorView: UIView {
    let progressIndicator = NVActivityIndicatorView(frame: .zero)
    
    init(text: NSAttributedString? = nil) {
        super.init(frame: .zero)
        addSubview(progressIndicator, activateConstraints: [
            progressIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressIndicator.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            progressIndicator.widthAnchor.constraint(equalTo: progressIndicator.heightAnchor),
            progressIndicator.heightAnchor.constraint(equalToConstant: 60),
        ])
        progressIndicator.color = .systemRed
        self.backgroundColor = .lightGray.withAlphaComponent(0.3)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
}

class EmptyStateView: UIView {
    
    init() {
        super.init(frame: .zero)
        
        let label = UILabel(NSAttributedString(string: "No available data",
                                               color: .darkGray,
                                               font: .preferredFont(forTextStyle: .headline)))
        let image = UIImageView(image: UIImage(named: "custom.exclamationmark.magnifyingglass")?
            .withTintColor(.gray,
                           renderingMode: .alwaysOriginal))
        
        addSubviews([ image, label ], activateConstraints: [
            image.widthAnchor.constraint(equalTo: image.heightAnchor, multiplier: 1.05),
            image.heightAnchor.constraint(equalToConstant: 100),
            image.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 3),
            image.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 10),
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
}

public protocol ProgressIndicating {
}

extension UIViewController: ProgressIndicating {
}


@MainActor
public extension ProgressIndicating where Self: UIViewController {

    private var progressIndicatorView: ProgressIndicatorView? {
        if let self = self as? UINavigationController {
            return self.viewControllers.last?.view.superview?.subviews.compactMap { $0 as? ProgressIndicatorView }.first
        }
        else {
            return view.subviews.compactMap { $0 as? ProgressIndicatorView }.first
        }
    }

    func progressIndicator(shouldShow: Bool, text: NSAttributedString? = nil) {
        shouldShow ? self.showIndicator(text: text) : self.hideIndicator()
    }
    
    func progressIndicator<T: Sendable>(for asyncTask: @escaping() async->T,
                              completion: @MainActor @escaping(T)->()) {
        self.progressIndicator(shouldShow: true)
        Task { @MainActor in
            let result: T = await asyncTask()
            self.progressIndicator(shouldShow: false)
            completion(result)
        }
    }
    
    private func showIndicator(text: NSAttributedString? = nil) {
        guard progressIndicatorView == nil else { return }
        let indicator = ProgressIndicatorView(text: text)
        let indicatorTypes: [NVActivityIndicatorType] = [ .ballPulse, .ballPulseSync, .ballBeat ]
        indicator.progressIndicator.type = indicatorTypes.randomElement()!
        
        if let self = self as? UINavigationController {
            self.viewControllers.last?.view.superview?.addEnclosedSubview(indicator)
            self.viewControllers.last?.view.superview?.bringSubviewToFront(indicator)
        }
        else {
            self.view.addEnclosedSubview(indicator)
            self.view.bringSubviewToFront(indicator)
        }
        
        indicator.alpha = 0
        UIView.animate(withDuration: 1/3,
                       delay: 0,
                       options: .curveEaseInOut) {
            indicator.alpha = 1
        } completion: { [weak indicator] (_) in
            indicator?.progressIndicator.startAnimating()
        }
    }
    
    private func hideIndicator() {
        UIView.animate(withDuration: 1/3,
                       delay: 0,
                       options: .curveEaseInOut) { [weak self] in
            self?.progressIndicatorView?.alpha = 0
        } completion: { [weak self] _ in
            self?.progressIndicatorView?.progressIndicator.stopAnimating()
            self?.progressIndicatorView?.removeFromSuperview()
        }
    }
    
    
    private var emptyStateView: EmptyStateView? {
        if let self = self as? UINavigationController {
            return self.viewControllers.last?.view.superview?.subviews.compactMap { $0 as? EmptyStateView }.first
        }
        else {
            return view.subviews.compactMap { $0 as? EmptyStateView }.first
        }
    }
    
    func showEmptyState(_ shouldShow: Bool) {
        shouldShow ? self.showEmptyState() : self.hideEmptyState()
    }
    
    func showEmptyState() {
        guard emptyStateView == nil else { return }
        let empty = EmptyStateView()
        
        if let self = self as? UINavigationController {
            self.viewControllers.last?.view.superview?.addEnclosedSubview(empty)
            self.viewControllers.last?.view.superview?.bringSubviewToFront(empty)
        }
        else {
            self.view.addEnclosedSubview(empty)
            self.view.bringSubviewToFront(empty)
        }
        
        empty.alpha = 0
        UIView.animate(withDuration: 1/3,
                       delay: 0,
                       options: .curveEaseInOut) {
            empty.alpha = 1
        } completion: { _ in
        }
    }
    
    func hideEmptyState() {
        UIView.animate(withDuration: 1/3,
                       delay: 0,
                       options: .curveEaseInOut) { [weak self] in
            self?.emptyStateView?.alpha = 0
        } completion: { [weak self] _ in
            self?.emptyStateView?.removeFromSuperview()
        }
    }
    
}
