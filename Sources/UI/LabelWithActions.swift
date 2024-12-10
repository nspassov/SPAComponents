import UIKit

public class LabelWithActions: UILabel {
    
    private let interaction = UIEditMenuInteraction(delegate: nil)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    private func setup() {
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.showMenu)))
        self.addInteraction(interaction)
    }

    @objc func showMenu(_ recognizer: UIGestureRecognizer) {
        self.becomeFirstResponder()
        
        let location = recognizer.location(in: self)
        let configuration = UIEditMenuConfiguration(identifier: nil,
                                                    sourcePoint: location)
        interaction.presentEditMenu(with: configuration)
        
#if targetEnvironment(simulator)
        print("⚠️ The Copy action does not work in the iOS Simulator")
#endif
    }

    public override var canBecomeFirstResponder: Bool {
        return true
    }

    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }
    
    public override func copy(_ sender: Any?) {
        UIPasteboard.general.string = text
    }
}

