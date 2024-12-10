import UIKit
import StoreKit
import SPAExtensions

@MainActor
public enum AppUpdate {
    
    private static var appStoreLookup: AppStoreLookup? = nil
    
    public static func checkAppStore(for bundleId: String) async -> Result<AppStoreLookup, CommonError> {
        
        if let lookupData = self.appStoreLookup,
              Date.now.timeIntervalSince(lookupData.lookupDate) < 60 * 30 { // no often than every 30 minutes
            debugLog(lookupData)
            return .success(lookupData)
        }
        
        guard let url = URL(string: "https://itunes.apple.com/lookup")?
            .appending(queryItems: [ URLQueryItem(name: "bundleId",
                                                  value: bundleId) ]) else {
            return .failure(.custom("Invalid URL for App Store version check"))
        }
        
        let response = await URLSession.shared.perform(URLRequest(url: url)) { data in
            return try JSONDecoder().decode(LookupResult.self, from: data)
        }
        
        switch response {
        case .success(let lookupData):
            if let lookupData = lookupData.appStore?.first {
                self.appStoreLookup = lookupData
                debugLog(lookupData)
                return .success(lookupData)
            }
            else {
                return .failure(.custom("App Store data not found"))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public static func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    public static func checkTestFlight(for appStoreId: String,
                                       completion: @escaping(Result<TestFlightLookup, CommonError>)->()) {
        
//        let testflightURL = "https://api.appstoreconnect.apple.com/v1/apps/\(self.appStoreId)/builds"
//        check https://github.com/acarolsf/checkVersion-iOS/blob/main/checkVersion-iOS.swift
        completion(.failure(.custom("Requires a JWT token for AppStore Connect")))
    }
}

fileprivate struct LookupResult: Sendable, Decodable {
    let testFlight: [TestFlightLookup]?
    let appStore: [AppStoreLookup]?
    
    private enum CodingKeys: String, CodingKey {
        case testFlight = "data"
        case appStore = "results"
    }
}

public struct AppStoreLookup: Sendable, Decodable, CustomStringConvertible {
    public let appName: String
    public let appVersion: SemanticVersion
    public let storeURL: URL
    public let appStoreId: String
    public let releaseDate: Date
    public let lookupDate: Date
    
    private enum CodingKeys: String, CodingKey {
        case appName = "trackName"
        case appVersion = "version"
        case appStoreId = "trackId"
        case storeURL = "trackViewUrl"
        case releaseDate = "currentVersionReleaseDate"
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.appName = try c.decode(String.self, forKey: .appName)
        let version = try c.decode(String.self, forKey: .appVersion)
        self.appVersion = try SemanticVersion(version) ?! CommonError.custom("Invalid app version")
        self.storeURL = try c.decode(URL.self, forKey: .storeURL)
        let storeId = try c.decode(Int.self, forKey: .appStoreId)
        self.appStoreId = String(describing: storeId)
        var date = try c.decode(String.self, forKey: .releaseDate)
        date.removeLast()
        self.releaseDate = try Date.fromJSONResponse(date) ?! CommonError.custom("Invalid release date")
        self.lookupDate = .now
    }
    
    public var description: String {
        return appName ++ appVersion.description ++ "released" ++ releaseDate.toUIDateRelative() + ", last checked at" ++ lookupDate.timeForRequest()
    }
    
    public func notificationItem() -> CommonEvent.Item {
        return CommonEvent.Item(title: "\(self.appName) \(self.appVersion.description) Available",
                                 message: "Since \(self.releaseDate.toUIDateRelative())",
                                 kind: .persistentInfo,
                                 action: {
            await self.storeURL.openExternally()
        })
    }
}

public struct TestFlightLookup: Sendable, Decodable {
    public let type: String
    public let attributes: Attributes
    
    public struct Attributes: Sendable, Decodable {
        public let version: String
        public let expired: String
    }
}
