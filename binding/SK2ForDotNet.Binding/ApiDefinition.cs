#nullable enable
using System;
using Foundation;
using ObjCRuntime;

namespace SK2ForDotNet;

delegate void SK2FetchProductsCompletion(SK2ProductInfo[]? products, NSError? error);
delegate void SK2PurchaseCompletion(SK2PurchaseResultType result, SK2TransactionInfo? transaction, NSError? error);
delegate void SK2AppTransactionCompletion(SK2AppTransactionInfo? appTransaction, NSError? error);

// @protocol SK2WrapperDelegate
[Protocol, Model]
[BaseType(typeof(NSObject))]
interface SK2WrapperDelegate
{
    [Abstract]
    [Export("sk2Wrapper:didUpdateEntitlements:")]
    void DidUpdateEntitlements(SK2Wrapper wrapper, SK2TransactionInfo[] transactions);

    [Export("sk2Wrapper:didEncounterError:")]
    void DidEncounterError(SK2Wrapper wrapper, NSError error);
}

// @interface SK2TransactionInfo : NSObject
[BaseType(typeof(NSObject))]
[DisableDefaultCtor]
interface SK2TransactionInfo
{
    [Export("productId")]
    string ProductId { get; }

    [Export("transactionId")]
    long TransactionId { get; }

    [Export("originalTransactionId")]
    long OriginalTransactionId { get; }

    [Export("purchaseDate", ArgumentSemantic.Copy)]
    NSDate PurchaseDate { get; }

    [Export("productType")]
    string ProductType { get; }

    [NullAllowed, Export("expirationDate", ArgumentSemantic.Copy)]
    NSDate? ExpirationDate { get; }

    [Export("isRevoked")]
    bool IsRevoked { get; }
}

// @interface SK2ProductInfo : NSObject
[BaseType(typeof(NSObject))]
[DisableDefaultCtor]
interface SK2ProductInfo
{
    [Export("productId")]
    string ProductId { get; }

    [Export("displayName")]
    string DisplayName { get; }

    [Export("displayPrice")]
    string DisplayPrice { get; }

    [Export("price", ArgumentSemantic.Strong)]
    NSDecimalNumber Price { get; }

    [Export("productType")]
    string ProductType { get; }
}

// @interface SK2AppTransactionInfo : NSObject
[BaseType(typeof(NSObject))]
[DisableDefaultCtor]
interface SK2AppTransactionInfo
{
    [Export("originalAppVersion")]
    string OriginalAppVersion { get; }

    [Export("originalPurchaseDate", ArgumentSemantic.Copy)]
    NSDate OriginalPurchaseDate { get; }

    [Export("isVerified")]
    bool IsVerified { get; }
}

// @interface SK2Wrapper : NSObject
[BaseType(typeof(NSObject))]
interface SK2Wrapper
{
    [NullAllowed, Export("delegate", ArgumentSemantic.Weak)]
    NSObject? WeakDelegate { get; set; }

    [Export("initialize")]
    void Initialize();

    [Export("fetchProducts:completion:")]
    void FetchProducts(string[] productIds, SK2FetchProductsCompletion completion);

    [Export("purchaseWithProductId:completion:")]
    void Purchase(string productId, SK2PurchaseCompletion completion);

    [Export("fetchAppTransactionWithCompletion:")]
    void FetchAppTransaction(SK2AppTransactionCompletion completion);
}
