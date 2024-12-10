import Foundation

public struct SemanticVersion: Sendable, Comparable, CustomStringConvertible, Hashable, Decodable {
    
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        return lhs.major < rhs.major
            || (lhs.minor < rhs.minor && lhs.major == rhs.major)
            || (lhs.patch < rhs.patch && lhs.minor == rhs.minor && lhs.major == rhs.major)
    }
    
    public let major: Int
    public let minor: Int
    public let patch: Int
    
    public init?(_ string: String) {
        let components = string.components(separatedBy: ".")
        guard components.count == 3,
              let major = Int(components[0]),
              let minor = Int(components[1]),
              let patch = Int(components[2]) else {
            return nil
        }
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    public var description: String {
        return "\(major).\(minor).\(patch)"
    }
}
