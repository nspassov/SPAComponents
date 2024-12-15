import UIKit

public class ColumnView: UIView {
    
    private let stackView: UIStackView = UIStackView(frame: .zero)
    private var arrangedSubviews: [LabelPairView] {
        return stackView.arrangedSubviews as? [LabelPairView] ?? []
    }
    
    private var topConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!
    
    private func setup() {
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        self.topConstraint = stackView.topAnchor.constraint(equalTo: topAnchor)
        self.bottomConstraint = stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        
        NSLayoutConstraint.activate([
            topConstraint,
            bottomConstraint,
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        // add a "zero" item in the stack view to use as anchor for column width constraints
        add(pair: ( NSAttributedString(string: ""), NSAttributedString(string: "") ),
            horizontalSpacing: 0,
            firstColumnWidth: 0)
    }
    
    public func remove(at index: Int) {
        if index < stackView.arrangedSubviews.count-1 {
            let v = stackView.arrangedSubviews[index+1]
            UIView.animate(withDuration: 1/3,
                           animations: { [weak self] in
                v.isHidden = !v.isHidden
                self?.stackView.layoutIfNeeded()
            }) { isFinished in
                isFinished ? v.removeFromSuperview() : ()
            }
        }
    }
    
    public func add(pairs: [ (NSAttributedString, NSAttributedString) ],
                    verticalSpacing: CGFloat = 5,
                    horizontalSpacing: CGFloat = 10,
                    firstColumnWidth: CGFloat = 0) {
        
        stackView.spacing = verticalSpacing
        topConstraint.constant = verticalSpacing
        bottomConstraint.constant = -verticalSpacing
        
        pairs.forEach { pair in
            add(pair: pair,
                horizontalSpacing: horizontalSpacing,
                firstColumnWidth: firstColumnWidth)
        }
    }
    
    public func add(pair: (NSAttributedString, NSAttributedString),
                    at index: Int? = nil,
                    horizontalSpacing: CGFloat = 10,
                    firstColumnWidth: CGFloat = 0) {
        
        let view = LabelPairView(interimSpacing: horizontalSpacing)
        view.firstLabel.attributedText = pair.0
        view.secondLabel.attributedText = pair.1
        
        if let index = index, index < stackView.arrangedSubviews.count-1 {
            UIView.animate(withDuration: 1/3) { [weak self] in
                self?.stackView.insertArrangedSubview(view, at: index+1)
                self?.stackView.layoutIfNeeded()
            }
        }
        else {
            stackView.addArrangedSubview(view)
        }
        
        if firstColumnWidth == 0 {
            NSLayoutConstraint.activate([
                view.firstLabel.widthAnchor.constraint(greaterThanOrEqualTo: stackView.widthAnchor, multiplier: 1/3),
                view.firstLabel.widthAnchor.constraint(lessThanOrEqualTo: stackView.widthAnchor, multiplier: 1/2)
            ])
            
            if let first = arrangedSubviews.first, view != first {
                NSLayoutConstraint.activate([
                    view.firstLabel.widthAnchor.constraint(equalTo: first.firstLabel.widthAnchor)
                ])
            }
        }
        else {
            NSLayoutConstraint.activate([
                view.firstLabel.widthAnchor.constraint(equalToConstant: firstColumnWidth),
            ])
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private class LabelPairView: UIView {
        let firstLabel = UILabel()
        let secondLabel = UILabel()
        
        private let interimSpacing: CGFloat
        
        private func setup() {
            firstLabel.numberOfLines = 0
            secondLabel.numberOfLines = 0
            
            firstLabel.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(firstLabel)
            
            secondLabel.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(secondLabel)
            
            NSLayoutConstraint.activate([
                firstLabel.topAnchor.constraint(equalTo: topAnchor),
                firstLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
                firstLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: interimSpacing),
                firstLabel.trailingAnchor.constraint(equalTo: secondLabel.leadingAnchor, constant: -interimSpacing),
                secondLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -interimSpacing),
                secondLabel.topAnchor.constraint(equalTo: topAnchor),
                secondLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
                firstLabel.firstBaselineAnchor.constraint(equalTo: secondLabel.firstBaselineAnchor)
            ])
        }
        
        init(interimSpacing: CGFloat) {
            self.interimSpacing = interimSpacing
            super.init(frame: .zero)
            setup()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
