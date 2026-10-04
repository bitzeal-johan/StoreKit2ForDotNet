import Foundation

@objc(SK2AppTransactionInfo) public class SK2AppTransactionInfo: NSObject {
    @objc public let originalAppVersion: String
    @objc public let originalPurchaseDate: Date
    @objc public let isVerified: Bool

    init(originalAppVersion: String, originalPurchaseDate: Date, isVerified: Bool) {
        self.originalAppVersion = originalAppVersion
        self.originalPurchaseDate = originalPurchaseDate
        self.isVerified = isVerified
        super.init()
    }
}
