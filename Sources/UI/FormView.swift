import UIKit
import Combine
import SPAExtensions

public class FormItem: Equatable {
    
    public static func == (lhs: FormItem, rhs: FormItem) -> Bool {
        return lhs.title == rhs.title
            && lhs.type == rhs.type
            && lhs.reuseIdentifier == rhs.reuseIdentifier
    }
    
    public typealias ListItemValidationFunction = (String) -> CommonError?
    
    public enum WidthRatio: CGFloat {
        case full = 1
        case half = 0.5
        
        var spacingMultiplier: CGFloat {
            switch self {
            case .full:
                return 2
            case .half:
                return 1.5
            }
        }
    }
    
    let reuseIdentifier: String = UUID().uuidString
    
    @Published public var title: String
    @Published public var value: String
    public let type: FormInputView.InputType
    public var action: ()->()
    
    public let isValid: ListItemValidationFunction
    public let validation = PassthroughSubject<Void, Never>()
    
    public let widthRatio: WidthRatio
    public let height: CGFloat
    
    public init(title: String,
                value: String = "",
                type: FormInputView.InputType,
                isValid: @escaping ListItemValidationFunction = FormItemValidation.notEmpty(_:),
                widthRatio: WidthRatio = .full,
                height: CGFloat = 70,
                action: @escaping ()->() = {}) {
        
        self.title = title
        self.value = value
        self.type = type
        self.isValid = isValid
        self.widthRatio = widthRatio
        self.height = height
        self.action = action
    }
}


public enum FormItemValidation {
    public static func anyValue(_ s: String) -> CommonError? {
        return nil
    }
    
    public static func notEmpty(_ s: String) -> CommonError? {
        return s.isEmpty ? CommonError.client(.requiredFields) : nil
    }
    
    public static func integerValue(_ s: String) -> CommonError? {
        if s.isEmpty { return CommonError.client(.requiredFields) }
        if Int(s) == nil { return CommonError.client(.requiredFieldInteger) }
        return nil
    }
    
    public static func integerValueInRange(_ s: String, min: Int, max: Int) -> CommonError? {
        guard let integer = Int(s) else { return Self.integerValue(s) }
        if integer < min { return CommonError.custom("Value must be no less than \(min)") }
        if integer > max { return CommonError.custom("Value must be no greater than \(max)") }
        return nil
    }
}

public class FormView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // to be replaced with diffable datasource in the future
    public var cache: [FormItem] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    public let collectionView: UICollectionView
    
    public var itemPadding: CGFloat = 12

    public init(collectionViewLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()) {
        
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        super.init(frame: .zero)

        self.backgroundColor = UIColor.systemBackground
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactiveWithAccessory
        addEnclosedSubview(collectionView)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard previousTraitCollection != nil else { return }
        collectionView.collectionViewLayout.invalidateLayout()
    }


    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        return cache.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let item = cache[indexPath.item]

        collectionView.register(FormViewCell.self, forCellWithReuseIdentifier: item.reuseIdentifier)

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.reuseIdentifier, for: indexPath)
        
        if let cell = cell as? FormViewCell {
            cell.formInputView.configure(inputType: item.type, action: item.action)
            
            // map UI input
            cell.formInputView.value.assign(to: &item.$value)
            
            // map internal state changes
            item.$title.removeDuplicates().sink { value in
                cell.formInputView.title.send(value)
            }.store(in: &cell.cancellables)
            
            item.$value.removeDuplicates().sink { value in
                cell.formInputView.value.send(value)
                item.validation.send()
            }.store(in: &cell.cancellables)
            
            item.validation.sink {
                cell.formInputView.updateState(error: item.isValid(item.value))
            }.store(in: &cell.cancellables)
        }

        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
        
        if cache[indexPath.row].type == .textAscii
            || cache[indexPath.row].type == .textNumpad
            || cache[indexPath.row].type == .dateTimeSelector {
            _ = (collectionView.cellForItem(at: indexPath) as? FormViewCell)?.formInputView.becomeFirstResponder()
        }
        else {
            cache[indexPath.row].action()
        }
    }

//    public func collectionView(_ collectionView: UICollectionView,
//                               viewForSupplementaryElementOfKind kind: String,
//                               at indexPath: IndexPath) -> UICollectionReusableView {

//        guard let decoration = cache[indexPath.section].decoration.get(by: kind) else {
//            collectionView.register(UICollectionReusableView.self,
//                                    forSupplementaryViewOfKind: kind,
//                                    withReuseIdentifier: String(describing: UICollectionReusableView.self))
//            return collectionView.dequeueReusableSupplementaryView(ofKind: kind,
//                                                                   withReuseIdentifier: String(describing: UICollectionReusableView.self),
//                                                                   for: indexPath)
//        }
//
//        registerView(for: decoration, in: collectionView)
//        return dequeueView(for: decoration, at: indexPath, in: collectionView)
//    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
//        guard let decoration = cache[section].decoration.get(by: UICollectionView.elementKindSectionHeader) else {
            return .zero
//        }

//        return calculateReferencedSize(for: decoration,
//                                       of: UICollectionView.elementKindSectionHeader,
//                                       at: IndexPath(row: 0, section: section))
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForFooterInSection section: Int) -> CGSize {
//        guard let decoration = cache[section].decoration.get(by: UICollectionView.elementKindSectionFooter) else {
            return .zero
//        }

//        return calculateReferencedSize(for: decoration,
//                                       of: UICollectionView.elementKindSectionFooter,
//                                       at: IndexPath(row: 0, section: section))
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {

        let item = cache[indexPath.item]

        return CGSize(width: 
                        (collectionView.bounds.width * item.widthRatio.rawValue)
                      - (itemPadding * item.widthRatio.spacingMultiplier),
                      height: item.height)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {

        return UIEdgeInsets(top: itemPadding, left: itemPadding, bottom: itemPadding, right: itemPadding)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {

        return itemPadding
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
                               point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let indexPath = indexPaths.first,
              let cell = collectionView.cellForItem(at: indexPath) as? ContextMenuConfigurable else {
            return nil
        }
        
        return cell.menuConfiguration
    }
    
    public protocol ContextMenuConfigurable {
        var menuConfiguration: UIContextMenuConfiguration? { get set }
    }
}


public class FormViewCell: UICollectionViewCell {
    
    public let formInputView: FormInputView
    
    public var cancellables = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        self.formInputView = FormInputView(inputType: .textAscii)
        super.init(frame: frame)
        
        contentView.addEnclosedSubview(formInputView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    public override func prepareForReuse() {
        cancellables.removeAll()
    }
}
