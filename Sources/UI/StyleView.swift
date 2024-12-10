import UIKit

/** Enables styling of the following properties:
 
- top/left/bottom/right border (dividers) with begin/end offset
- rounded corner(s) with custom radius
- outline (following rounded corners)
- drop shadow (following rounded corners)
- gradient
 */
public class StyleView: UIView {

    private var isLayoutLayersNeeded: Bool = true {
        didSet {
            if isLayoutLayersNeeded {
                setNeedsLayout()
            }
        }
    }

    public var onAccessibilityActivate: (() -> Bool)?

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    public override func accessibilityActivate() -> Bool {
        return onAccessibilityActivate?() ?? super.accessibilityActivate()
    }

    private func setup() {
        layer.masksToBounds = false

        layer.insertSublayer(shadowLayer, at: 0)

        shadowLayer.addSublayer(cornersLayer)

        cornersLayer.insertSublayer(gradientLayer, at: 0)

        borderTopLayer.fillColor = UIColor.clear.cgColor
        cornersLayer.addSublayer(borderTopLayer)

        borderLeftLayer.fillColor = UIColor.clear.cgColor
        cornersLayer.addSublayer(borderLeftLayer)

        borderBottomLayer.fillColor = UIColor.clear.cgColor
        cornersLayer.addSublayer(borderBottomLayer)

        borderRightLayer.fillColor = UIColor.clear.cgColor
        cornersLayer.addSublayer(borderRightLayer)

        outlineLayer.fillColor = UIColor.clear.cgColor
        cornersLayer.addSublayer(outlineLayer)
    }

    public var borders: Borders = Borders() {
        didSet {
            borderTopLayer.strokeColor = borders.top.color
            borderTopLayer.lineWidth = borders.top.width

            borderLeftLayer.strokeColor = borders.left.color
            borderLeftLayer.lineWidth = borders.left.width

            borderBottomLayer.strokeColor = borders.bottom.color
            borderBottomLayer.lineWidth = borders.bottom.width

            borderRightLayer.strokeColor = borders.right.color
            borderRightLayer.lineWidth = borders.right.width
            isLayoutLayersNeeded = true
        }
    }

    private var borderTopLayer: CAShapeLayer = CAShapeLayer()

    private var borderTopPath: CGPath {
        let points = [
            CGPoint(
                x: self.borderTopLayer.bounds.minX + self.borders.top.startInset,
                y: self.borderTopLayer.bounds.minY
            ),
            CGPoint(
                x: self.borderTopLayer.bounds.maxX - self.borders.top.endInset,
                y: self.borderTopLayer.bounds.minY
            )
        ]
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return path
    }

    private var borderLeftLayer: CAShapeLayer = CAShapeLayer()

    private var borderLeftPath: CGPath {
        let points = [
            CGPoint(
                x: self.borderLeftLayer.bounds.minX,
                y: self.borderLeftLayer.bounds.minY + self.borders.left.startInset
            ),
            CGPoint(
                x: self.borderLeftLayer.bounds.minX,
                y: self.borderLeftLayer.bounds.maxY - self.borders.left.endInset
            )
        ]
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return path
    }

    private var borderBottomLayer: CAShapeLayer = CAShapeLayer()

    private var borderBottomPath: CGPath {
        let points = [
            CGPoint(
                x: self.borderBottomLayer.bounds.minX + self.borders.bottom.startInset,
                y: self.borderBottomLayer.bounds.maxY
            ),
            CGPoint(
                x: self.borderBottomLayer.bounds.maxX - self.borders.bottom.endInset,
                y: self.borderBottomLayer.bounds.maxY
            )
        ]
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return path
    }

    private var borderRightLayer: CAShapeLayer = CAShapeLayer()

    private var borderRightPath: CGPath {
        let points = [
            CGPoint(
                x: self.borderRightLayer.bounds.maxX,
                y: self.borderRightLayer.bounds.minY + self.borders.right.startInset
            ),
            CGPoint(
                x: self.borderRightLayer.bounds.maxX,
                y: self.borderRightLayer.bounds.maxY - self.borders.right.endInset
            )
        ]
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return path
    }

    public var corners: Corners = Corners() {
        didSet {
            isLayoutLayersNeeded = true
        }
    }

    private var cornersLayer: CALayer = CALayer()

    private var cornersMaskLayer: CAShapeLayer = CAShapeLayer()

    public var gradient: Gradient = Gradient() {
        didSet {
            gradientLayer.colors = gradient.colors
            gradientLayer.startPoint = gradient.startPoint
            gradientLayer.endPoint = gradient.endPoint
            isLayoutLayersNeeded = true
        }
    }

    private var gradientLayer: CAGradientLayer = CAGradientLayer()

    public var outline: Border = Border() {
        didSet {
            outlineLayer.strokeColor = outline.color
            outlineLayer.lineWidth = outline.width
            isLayoutLayersNeeded = true
        }
    }

    private var outlineLayer: CAShapeLayer = CAShapeLayer()

    public var externalMargins: UIEdgeInsets = UIEdgeInsets()

    public var shadow: Shadow = Shadow() {
        didSet {
            shadowLayer.shadowColor = shadow.color
            shadowLayer.shadowOpacity = shadow.opacity
            shadowLayer.shadowOffset = shadow.offset
            shadowLayer.shadowRadius = shadow.radius
            isLayoutLayersNeeded = true
        }
    }

    private var shadowLayer: CALayer = CALayer()

    private var cachedBackgroundColor: UIColor?

    public override var backgroundColor: UIColor? {
        get {
            if let backgroundColor = self.cornersLayer.backgroundColor {
                return UIColor(cgColor: backgroundColor)
            }
            return nil
        }
        set {
            if cachedBackgroundColor != newValue {
                self.cachedBackgroundColor = newValue
                self.cornersLayer.backgroundColor = newValue?.resolvedColor(with: traitCollection).cgColor
            }
        }
    }

    public override var alignmentRectInsets: UIEdgeInsets {
        return UIEdgeInsets(
            top: -externalMargins.top,
            left: -externalMargins.left,
            bottom: -externalMargins.bottom,
            right: -externalMargins.right
        )
    }

    public func setBackgroundImage(_ image: UIImage?) {
        if let image = image {
            cornersLayer.contents = image.cgImage
        } else {
            cornersLayer.contents = nil
        }
    }

    public func add(animation: CAPropertyAnimation, for key: String) {
        self.cornersLayer.add(animation, forKey: key)
    }

    public override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        guard shadowLayer.frame != self.layer.bounds || isLayoutLayersNeeded else {
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        shadowLayer.frame = self.layer.bounds

        cornersLayer.frame = shadowLayer.bounds
        cornersMaskLayer.frame = cornersLayer.bounds

        gradientLayer.frame = cornersLayer.bounds

        let cornersPath = UIBezierPath(
            roundedRect: shadowLayer.bounds,
            byRoundingCorners: corners.rounded,
            cornerRadii: corners.radii
        )

        let shadowInset: CGRect = shadowLayer.bounds.insetBy(dx: shadow.offset.width, dy: shadow.offset.height)

        let shadowPath = UIBezierPath(
            roundedRect: shadowInset,
            byRoundingCorners: corners.rounded,
            cornerRadii: corners.radii
        )

        shadowLayer.shadowPath = shadowPath.cgPath
        cornersLayer.mask = cornersMaskLayer
        cornersMaskLayer.path = cornersPath.cgPath

        borderTopLayer.frame = cornersLayer.bounds
        borderTopLayer.path = borderTopPath

        borderLeftLayer.frame = cornersLayer.bounds
        borderLeftLayer.path = borderLeftPath

        borderBottomLayer.frame = cornersLayer.bounds
        borderBottomLayer.path = borderBottomPath

        borderRightLayer.frame = cornersLayer.bounds
        borderRightLayer.path = borderRightPath

        outlineLayer.frame = cornersLayer.bounds
        outlineLayer.path = cornersPath.cgPath

        CATransaction.commit()
        isLayoutLayersNeeded = false
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle else {
            return
        }
        // Updating background and shadow manually
        // Because CGColor is not dynamic
        cornersLayer.backgroundColor = cachedBackgroundColor?.resolvedColor(with: traitCollection).cgColor
        gradientLayer.colors = gradient.colors
        shadowLayer.shadowColor = shadow.color
    }
}

public struct Border {

    public var width: CGFloat
    public var color: CGColor
    public var startInset: CGFloat
    public var endInset: CGFloat

    public init(
        width: CGFloat = 0,
        color: UIColor = UIColor.clear,
        startInset: CGFloat = 0,
        endInset: CGFloat = 0
    ) {
        self.width = width
        self.color = color.cgColor
        self.startInset = startInset
        self.endInset = endInset
    }

    static var zero: Border {
        return Border()
    }
}

public struct Borders {

    public var top: Border
    public var left: Border
    public var bottom: Border
    public var right: Border

    public init(
        top: Border = Border(),
        left: Border = Border(),
        bottom: Border = Border(),
        right: Border = Border()
    ) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    static var zero: Borders {
        return Borders()
    }
}

public struct Corners {

    public var rounded: UIRectCorner
    public var cornerRadius: CGFloat
    public var radii: CGSize {
        CGSize(width: cornerRadius, height: cornerRadius)
    }

    public init(
        rounded: UIRectCorner = UIRectCorner(),
        cornerRadius: CGFloat = .zero
    ) {
        self.rounded = rounded
        self.cornerRadius = cornerRadius
    }
}

public struct Gradient {

    private let dynamicColors: [UIColor]
    public var colors: [CGColor] {
        dynamicColors.compactMap { $0.cgColor }
    }
    public var startPoint: CGPoint
    public var endPoint: CGPoint
    public var isOpaque = false
    public var locations: [NSNumber]?
    public var zPosition: CGFloat?

    public init(
        colors: [UIColor] = [],
        startPoint: CGPoint = CGPoint(x: 0.5, y: 0),
        endPoint: CGPoint = CGPoint(x: 0.5, y: 1.0),
        isOpaque: Bool = false,
        locations: [NSNumber]? = [0, 1],
        zPosition: CGFloat? = nil
    ) {
        self.dynamicColors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.isOpaque = isOpaque
        self.locations = locations
        self.zPosition = zPosition
    }
}

public struct Shadow {
    
    private let dynamicColor: UIColor
    public var color: CGColor {
        return dynamicColor.cgColor
    }
    public var opacity: Float
    public var offset: CGSize
    public var radius: CGFloat

    public init(
        color: UIColor = UIColor.clear,
        opacity: Float = 0,
        offset: CGSize = CGSize.zero,
        radius: CGFloat = 0
    ) {
        self.dynamicColor = color
        self.opacity = opacity
        self.offset = offset
        self.radius = radius
    }
}
