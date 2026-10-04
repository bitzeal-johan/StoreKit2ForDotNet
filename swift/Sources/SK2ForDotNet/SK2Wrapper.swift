import Foundation
import StoreKit

@objc(SK2Wrapper) public class SK2Wrapper: NSObject {
    @objc public weak var delegate: SK2WrapperDelegate?

    private var transactionObserverTask: Task<Void, Never>?

    @objc public override init() {
        super.init()
    }

    deinit {
        transactionObserverTask?.cancel()
    }

    @objc public func initialize() {
        transactionObserverTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                if case .verified(_) = result {
                    await self.refreshEntitlements()
                }
            }
        }
        Task { [weak self] in
            await self?.refreshEntitlements()
        }
    }

    @objc public func fetchProducts(
        _ productIds: [String],
        completion: @escaping ([SK2ProductInfo]?, NSError?) -> Void
    ) {
        Task {
            do {
                let products = try await Product.products(for: Set(productIds))
                let infos = products.map { product in
                    SK2ProductInfo(
                        productId: product.id,
                        displayName: product.displayName,
                        displayPrice: product.displayPrice,
                        price: product.price as NSDecimalNumber,
                        productType: Self.productTypeString(product.type)
                    )
                }
                completion(infos, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }

    @objc public func purchase(
        productId: String,
        completion: @escaping (SK2PurchaseResultType, SK2TransactionInfo?, NSError?) -> Void
    ) {
        Task {
            do {
                let products = try await Product.products(for: [productId])
                guard let product = products.first else {
                    let error = NSError(
                        domain: "SK2ForDotNet",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Product not found: \(productId)"]
                    )
                    completion(.failed, nil, error)
                    return
                }
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        await transaction.finish()
                        let info = Self.transactionInfo(from: transaction)
                        await self.refreshEntitlements()
                        completion(.success, info, nil)
                    case .unverified(_, let error):
                        completion(.failed, nil, error as NSError)
                    }
                case .userCancelled:
                    completion(.userCancelled, nil, nil)
                case .pending:
                    completion(.pending, nil, nil)
                @unknown default:
                    completion(.failed, nil, nil)
                }
            } catch {
                completion(.failed, nil, error as NSError)
            }
        }
    }

    @objc public func fetchAppTransaction(
        completion: @escaping (SK2AppTransactionInfo?, NSError?) -> Void
    ) {
        guard #available(iOS 16.0, macOS 13.0, *) else {
            completion(nil, NSError(
                domain: "SK2ForDotNet",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "AppTransaction requires iOS 16"]
            ))
            return
        }
        Task {
            do {
                switch try await AppTransaction.shared {
                case .verified(let appTransaction):
                    completion(Self.appTransactionInfo(from: appTransaction, isVerified: true), nil)
                case .unverified(let appTransaction, _):
                    completion(Self.appTransactionInfo(from: appTransaction, isVerified: false), nil)
                }
            } catch {
                completion(nil, error as NSError)
            }
        }
    }

    @available(iOS 16.0, macOS 13.0, *)
    private static func appTransactionInfo(from tx: AppTransaction, isVerified: Bool) -> SK2AppTransactionInfo {
        return SK2AppTransactionInfo(
            originalAppVersion: tx.originalAppVersion,
            originalPurchaseDate: tx.originalPurchaseDate,
            isVerified: isVerified
        )
    }

    private func refreshEntitlements() async {
        var entries: [SK2TransactionInfo] = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    entries.append(Self.transactionInfo(from: transaction))
                }
            }
        }
        let snapshot = entries
        await MainActor.run {
            self.delegate?.sk2Wrapper(self, didUpdateEntitlements: snapshot)
        }
    }

    private static func transactionInfo(from tx: Transaction) -> SK2TransactionInfo {
        return SK2TransactionInfo(
            productId: tx.productID,
            transactionId: Int64(bitPattern: tx.id),
            originalTransactionId: Int64(bitPattern: tx.originalID),
            purchaseDate: tx.purchaseDate,
            productType: productTypeString(tx.productType),
            expirationDate: tx.expirationDate,
            isRevoked: tx.revocationDate != nil
        )
    }

    private static func productTypeString(_ type: Product.ProductType) -> String {
        switch type {
        case .nonConsumable: return "nonConsumable"
        case .consumable: return "consumable"
        case .autoRenewable: return "autoRenewable"
        case .nonRenewable: return "nonRenewable"
        default: return "unknown"
        }
    }
}
