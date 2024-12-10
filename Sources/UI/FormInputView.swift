import UIKit
import Combine
import SPAExtensions

public class FormInputView: UIView, UITextFieldDelegate, EventNotifying {
    
    public let title = PassthroughSubject<String, Never>()
    public let value = PassthroughSubject<String, Never>()
    
    public func updateState(error: CommonError?) {
        self.error = error
        self.updateState()
    }
    
    public func updateState() {
        if let error = self.error, !textField.isFirstResponder {
            self.notify(error, kind: .warning)
        }
        self.state = (self.error != nil ? .error : (textField.isFirstResponder ? .focused : .normal))
    }
    
    public enum InputType {
        case textAscii
        case textNumpad
        case button
        case dateTimeSelector
        case timeSelector
    }
    
    private var inputType: InputType
    private var keyboard: Keyboard {
        didSet {
            self.textField.spellCheckingType = keyboard.spellChecking
            self.textField.autocorrectionType = keyboard.autocorrection
            self.textField.autocapitalizationType = keyboard.autocapitalization

            self.textField.returnKeyType = keyboard.keyboardReturnKeyType
            self.textField.keyboardType = keyboard.keyboardType
            self.textField.keyboardAppearance = keyboard.keyboardAppearance
        }
    }
    
    private var error: CommonError? = nil
    
    enum State {
        case normal
        case focused
        case error
        case disabled
    }
    
    private var state: State = .normal {
        didSet {
            switch state {
            case .normal:
                layer.borderColor = UIColor.darkGray.cgColor
            case .focused:
                layer.borderColor = UIColor.systemBlue.cgColor
            case .error:
                layer.borderColor = UIColor.systemRed.cgColor
            case .disabled:
                layer.borderColor = UIColor.lightGray.cgColor
            }
        }
    }
    
    private let titleLabel: UILabel
    private let textField: UITextField
    private let button: UIButton
    
    private var cancellables = Set<AnyCancellable>()
    
    private(set) lazy var keyboardToolbar: KeyboardToolbar = {
        return KeyboardToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
    }()
    
    init(inputType: InputType, keyboard: Keyboard = .default) {
        self.inputType = inputType
        self.keyboard = keyboard
        
        self.titleLabel = UILabel()
        self.textField = UITextField(frame: .zero)
        self.button = UIButton(type: .custom)
        
        super.init(frame: .zero)
        
        textField.delegate = self
        
        textField.publisher.sink { value in
            self.value.send(value)
        }.store(in: &cancellables)

        
        button.setTitleColor(.systemBlue, for: .normal)
        button.contentHorizontalAlignment = .left
        
        button.publisher.sink {
            self.value.send(self.button.title().string)
        }.store(in: &cancellables)
        
        
        value.sink { value in
            self.button.setTitle(value, for: .normal)
            self.textField.text = value
        }.store(in: &cancellables)
        
        title.sink { value in
            self.titleLabel.text = value
        }.store(in: &cancellables)
        
        layer.borderWidth = 1
        layer.cornerRadius = 15
        
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.textColor = .darkGray
        
        textField.font = UIFont.preferredFont(forTextStyle: .title2)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title2)
        
        configure()
        configureKeyboardToolbar(doneHandler: { })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    func configure() {
        self.removeAllSubviews()
        
        self.updateState()
        
        switch inputType {
        case .textAscii, .textNumpad, .dateTimeSelector, .timeSelector:
            addSubviews([titleLabel, textField], activateConstraints: [
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
                
                textField.topAnchor.constraint(equalTo: centerYAnchor, constant: -10),
                textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
                textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
                textField.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
            
            self.keyboard = (inputType == .textNumpad) ? .numpad : .default
            self.textField.inputView = (inputType == .dateTimeSelector || inputType == .timeSelector) ? datePicker : nil
            self.textField.inputAccessoryView = (inputType == .textNumpad
                                                 || inputType == .dateTimeSelector
                                                 || inputType == .timeSelector) ? keyboardToolbar : nil
            self.textField.tintColor = (inputType == .dateTimeSelector
                                        || inputType == .timeSelector) ? UIColor.clear : UIColor.systemBlue

        case .button:
            addSubviews([titleLabel, button], activateConstraints: [
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),

                button.topAnchor.constraint(equalTo: centerYAnchor, constant: -10),
                button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
                button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
                button.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }
    }
    
    public func configure(inputType: InputType, action: (() -> Void)? = nil) {
        self.inputType = inputType
        self.button.addAction({
            self.resignAnyFirstResponder() // make sure that an action on another FormView resigns any first responder
            action?()
        })
        self.configure()
    }
    
    public override func becomeFirstResponder() -> Bool {
        if inputType == .textAscii
            || inputType == .textNumpad
            || inputType == .dateTimeSelector {
            
            textField.becomeFirstResponder()
            return true
        }
        return false
    }
    
    
    // Date Picker and accessory toolbar
    
    func configureKeyboardToolbar(doneHandler: (() -> Void)? = nil) {
        
        self.keyboardToolbar.setup(doneHandler: { [weak self] _ in
            doneHandler?()
            self?.textField.resignFirstResponder()
        })
        self.keyboardToolbar.alpha = 1
    }
    
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker(frame: .zero)
        datePicker.datePickerMode = (inputType == .timeSelector) ? .time : .dateAndTime
        datePicker.timeZone = TimeZone.current
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(datePickerChanged(sender:)), for: .valueChanged)
        return datePicker
    }()
    
    @objc func datePickerChanged(sender: UIDatePicker) {
        if inputType == .dateTimeSelector {
            self.value.send(sender.date.toUITimestamp())
        }
        else if inputType == .timeSelector {
            self.value.send(sender.date.toUITime())
        }
    }
    
    
    // UITextFieldDelegate
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        updateState()
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        updateState()
    }
    
    public func textField(_ textField: UITextField,
                          shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
        
        if inputType == .dateTimeSelector || inputType == .timeSelector {
            return false
        }
        return true
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    // ---
    
    @MainActor
    struct Keyboard {
        
        let keyboardReturnKeyType: UIReturnKeyType
        let keyboardType: UIKeyboardType
        let keyboardAppearance: UIKeyboardAppearance
        
        let spellChecking: UITextSpellCheckingType = .yes
        let autocorrection: UITextAutocorrectionType = .no
        let autocapitalization: UITextAutocapitalizationType = .sentences
        
        public static var `default` = Keyboard(keyboardReturnKeyType: .done,
                                               keyboardType: .default,
                                               keyboardAppearance: .default)
        
        public static var ascii = Keyboard(keyboardReturnKeyType: .done,
                                           keyboardType: .asciiCapable,
                                           keyboardAppearance: .default)

        public static var numpad = Keyboard(keyboardReturnKeyType: .done,
                                         keyboardType: .numberPad,
                                         keyboardAppearance: .default)

        public static var decimal = Keyboard(keyboardReturnKeyType: .done,
                                             keyboardType: .decimalPad,
                                             keyboardAppearance: .default)
        
        public static var numbersAndPunctuation = Keyboard(keyboardReturnKeyType: .done,
                                                           keyboardType: .numbersAndPunctuation,
                                                           keyboardAppearance: .default)
    }
    
    @MainActor
    class KeyboardToolbar: UIToolbar {

        typealias DoneAction = (UIBarButtonItem) -> Void

        func setup(doneHandler: @escaping DoneAction) {
            var items: [UIBarButtonItem] = []
            items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, action: { _ in }))
            items.append(UIBarButtonItem(barButtonSystemItem: .done, action: doneHandler))
            self.items = items
            self.sizeToFit()
        }
    }

}
