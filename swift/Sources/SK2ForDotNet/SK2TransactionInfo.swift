import Foundation

@objc(SK2TransactionInfo) public class SK2TransactionInfo: NSObject {
    @objc public let productId: String
    @objc public let transactionId: Int64
    @objc public let originalTransactionId: Int64
    @objc public let purchaseDate: Date
    @objc public let productType: String
    @objc public let expirationDate: Date?
    @objc public let isRevoked: Bool

    init(
        productId: String,
        transactionId: Int64,
        originalTransactionId: Int64,
        purchaseDate: Date,
        productType: String,
        expirationDate: Date?,
        isRevoked: Bool
    ) {
        self.productId = productId
        self.transactionId = transactionId
        self.originalTransactionId = originalTransactionId
        self.purchaseDate = purchaseDate
        self.productType = productType
        self.expirationDate = expirationDate
        self.isRevoked = isRevoked
        super.init()
    }
}
