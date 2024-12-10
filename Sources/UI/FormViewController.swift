import UIKit
import Combine
import SPAExtensions

@MainActor
public protocol FormViewModel {
    var title: String { get }
    var listItems: [FormItem] { get }
    var cancellables: Set<AnyCancellable> { get set }
    
    func isFormValid() -> Bool
    func submitForm() async -> CommonError?
}

public extension FormViewModel {
    func isFormValid() -> Bool {
        return listItems.compactMap({ $0.isValid($0.value) }).isEmpty
    }
}

public class FormViewController: UIViewController {
    
    public let formView: FormView
    
    private let viewModel: FormViewModel
    
    public init(viewModel: FormViewModel) {
        self.viewModel = viewModel
        self.formView = FormView()
        self.formView.cache = viewModel.listItems
        
        super.init(nibName: nil, bundle: nil)
        self.title = viewModel.title
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addEnclosedSubview(formView)
        
        let submitButton = UIButton(title: NSAttributedString(string: Localized.string("Submit"), color: .systemBlue),
                                    action: { [weak self] in
            guard let self = self else { return }
            if self.viewModel.isFormValid() {
                self.formView.resignAnyFirstResponder()
                
                self.progressIndicator(shouldShow: true)
                Task {
                    let error = await self.viewModel.submitForm()
                    self.progressIndicator(shouldShow: false)
                    if let error = error {
                        self.notify(error)
                    }
                    else {
                        let success = CommonEvent.Item(title: self.viewModel.title,
                                                        message: Localized.string("Data submitted successfully"),
                                                        kind: .success)
                        self.notify(success)
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
            else {
                self.viewModel.listItems.forEach { $0.validation.send() }
            }
        })
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: submitButton)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startObservingKeyboard()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopObservingKeyboard()
    }
}
