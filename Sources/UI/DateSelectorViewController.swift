import UIKit
import Combine
import SPAExtensions
import DatePicker

public class DateSelectorViewController: UIViewController {
    
//    private lazy var datePicker = {
//        let dp = UIDatePicker(frame: .zero)
//        dp.preferredDatePickerStyle = .inline
//        dp.datePickerMode = .date
//        dp.addAction(for: .valueChanged) {
//            self.dateSelected = dp.date.operationalDayStart()
//        }
//        return dp
//    }()
    
    private lazy var datePicker = {
        var dp = DatePicker()
        dp.mode = .date(DatePickerDateModeSettings(layoutDirection: .vertical,
                                                   selectionBehavior: .single,
                                                   currentDateSelection: .off))
        dp.addAction(UIAction { _ in
            self.dateSelected = dp.date
        }, for: .valueChanged)
        return dp
    }()
    
    @Published public private(set) var dateSelected: Date?
    
    public var cancellables = [AnyCancellable]()
    
    public convenience init(minDate: Date? = nil, maxDate: Date? = nil) {
        self.init(nibName: nil, bundle: nil)
        self.datePicker.minimumDate = minDate
        self.datePicker.maximumDate = maxDate
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = Localized.string("Select Date")
        
        view.backgroundColor = .white
        view.addEnclosedSubview(datePicker,
                                insets: .init(top: 0, leading: 10, bottom: 10, trailing: 10),
                                toSafeArea: true)
    }
    
}
