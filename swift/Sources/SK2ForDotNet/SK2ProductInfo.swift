import Foundation

@objc(SK2ProductInfo) public class SK2ProductInfo: NSObject {
    @objc public let productId: String
    @objc public let displayName: String
    @objc public let displayPrice: String
    @objc public let price: NSDecimalNumber
    @objc public let productType: String

    init(
        productId: String,
        displayName: String,
        displayPrice: String,
        price: NSDecimalNumber,
        productType: String
    ) {
        self.productId = productId
        self.displayName = displayName
        self.displayPrice = displayPrice
        self.price = price
        self.productType = productType
        super.init()
    }
}
