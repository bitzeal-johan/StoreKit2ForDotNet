# SK2ForDotNet

StoreKit 2 wrapper for .NET iOS projects. Bridges Apple's Swift-only StoreKit 2 APIs to .NET via `@objc`-compatible interfaces compiled as an `.xcframework`.

## Why?

.NET for iOS has no StoreKit 2 bindings because StoreKit 2 is a Swift-only API. Apple removed StoreKit 1 from the Xcode 26 SDK, so .NET iOS projects need a bridge to continue supporting in-app purchases.

This library provides that bridge: a small Swift wrapper compiled into an `.xcframework`, with a .NET binding project on top.

## Requirements

- .NET 10 iOS (`net10.0-ios`)
- iOS 15.0+ (required by StoreKit 2)
- Xcode 26+ (for building the xcframework from source)

## Installation

### Project Reference

Clone the repo and add a project reference to your iOS `.csproj`:

```xml
<ProjectReference Include="path/to/StoreKit2ForDotNet/binding/SK2ForDotNet.Binding/SK2ForDotNet.Binding.csproj" />
```

You also need to add the native framework reference in your iOS project:

```xml
<NativeReference Include="path/to/StoreKit2ForDotNet/binding/SK2ForDotNet.Binding/SK2ForDotNet.xcframework">
  <Kind>Framework</Kind>
  <SmartLink>false</SmartLink>
  <Frameworks>StoreKit Foundation</Frameworks>
</NativeReference>
```

Your project must also link with the Swift standard libraries. If you already have this (e.g. for Firebase), no changes needed. Otherwise add this target to your `.csproj`:

```xml
<Target Name="LinkWithSwift" DependsOnTargets="_ParseBundlerArguments;_DetectSdkLocations"
        BeforeTargets="_LinkNativeExecutable">
  <PropertyGroup>
    <_SwiftPlatform Condition="$(RuntimeIdentifier.StartsWith('iossimulator-'))">iphonesimulator</_SwiftPlatform>
    <_SwiftPlatform Condition="$(RuntimeIdentifier.StartsWith('ios-'))">iphoneos</_SwiftPlatform>
  </PropertyGroup>
  <ItemGroup>
    <_CustomLinkFlags Include="-L" />
    <_CustomLinkFlags Include="/usr/lib/swift" />
    <_CustomLinkFlags Include="-L" />
    <_CustomLinkFlags Include="$(_SdkDevPath)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/$(_SwiftPlatform)" />
    <_CustomLinkFlags Include="-Wl,-rpath" />
    <_CustomLinkFlags Include="-Wl,/usr/lib/swift" />
  </ItemGroup>
</Target>
```

## Usage

### 1. Create the wrapper and set the delegate

```csharp
using SK2ForDotNet;

public class MyBillingService : SK2WrapperDelegate
{
    private readonly SK2Wrapper _wrapper;

    public MyBillingService()
    {
        _wrapper = new SK2Wrapper();
        _wrapper.WeakDelegate = this;
    }
```

### 2. Initialize (loads current entitlements and starts observing transactions)

```csharp
    public void Start()
    {
        _wrapper.Initialize();
    }
```

### 3. Receive entitlement updates via the delegate

```csharp
    public override void DidUpdateEntitlements(SK2Wrapper wrapper, SK2TransactionInfo[] transactions)
    {
        // Called on init and whenever entitlements change
        foreach (var tx in transactions)
        {
            Console.WriteLine($"Owned: {tx.ProductId} (type: {tx.ProductType})");
        }
    }

    public override void DidEncounterError(SK2Wrapper wrapper, NSError error)
    {
        Console.WriteLine($"Error: {error.LocalizedDescription}");
    }
```

### 4. Purchase a product

```csharp
    public void Purchase(string productId)
    {
        _wrapper.Purchase(productId, (result, transaction, error) =>
        {
            switch (result)
            {
                case SK2PurchaseResultType.Success:
                    // Purchase succeeded, entitlements will also update via delegate
                    break;
                case SK2PurchaseResultType.UserCancelled:
                    break;
                case SK2PurchaseResultType.Pending:
                    // Ask to Buy or deferred
                    break;
                case SK2PurchaseResultType.Failed:
                    Console.WriteLine($"Failed: {error?.LocalizedDescription}");
                    break;
            }
        });
    }
```

### 5. Fetch product info (optional)

```csharp
    public void LoadProducts(string[] productIds)
    {
        _wrapper.FetchProducts(productIds, (products, error) =>
        {
            if (products != null)
            {
                foreach (var p in products)
                    Console.WriteLine($"{p.DisplayName}: {p.DisplayPrice}");
            }
        });
    }
}
```

## API Reference

### SK2Wrapper

| Method | Description |
|--------|-------------|
| `Initialize()` | Loads current entitlements and starts observing `Transaction.updates`. Results arrive via `DidUpdateEntitlements`. |
| `Purchase(productId, completion)` | Fetches the product and launches the App Store payment sheet. Completion returns `SK2PurchaseResultType`. |
| `FetchProducts(productIds, completion)` | Fetches product metadata (name, price, type) from the App Store. |

### SK2WrapperDelegate

| Method | Description |
|--------|-------------|
| `DidUpdateEntitlements(wrapper, transactions)` | Called with the full list of active entitlements. Fires on init and on every transaction update. |
| `DidEncounterError(wrapper, error)` | Optional. Called when an error occurs. |

### SK2TransactionInfo

| Property | Type | Description |
|----------|------|-------------|
| `ProductId` | `string` | The product identifier |
| `TransactionId` | `long` | Unique transaction ID |
| `OriginalTransactionId` | `long` | Original transaction ID (for renewals) |
| `PurchaseDate` | `NSDate` | When the purchase was made |
| `ProductType` | `string` | `"nonConsumable"`, `"consumable"`, `"autoRenewable"`, `"nonRenewable"` |
| `ExpirationDate` | `NSDate?` | Subscription expiration (nil for non-subscriptions) |
| `IsRevoked` | `bool` | Whether the transaction has been revoked |

### SK2ProductInfo

| Property | Type | Description |
|----------|------|-------------|
| `ProductId` | `string` | The product identifier |
| `DisplayName` | `string` | Localized product name |
| `DisplayPrice` | `string` | Localized price string (e.g. "$4.99") |
| `Price` | `NSDecimalNumber` | Numeric price |
| `ProductType` | `string` | Product type string |

### SK2PurchaseResultType

| Value | Description |
|-------|-------------|
| `Success` | Purchase completed and verified |
| `UserCancelled` | User dismissed the payment sheet |
| `Pending` | Purchase requires approval (Ask to Buy) |
| `Failed` | Purchase failed |

## Building the xcframework from source

The repo includes a prebuilt `.xcframework`. To rebuild from Swift source:

```bash
./scripts/build-xcframework.sh
```

This requires Xcode 26+ and builds for both iOS device (arm64) and simulator (arm64 + x86_64).

## Architecture

```
Swift (StoreKit 2)  -->  @objc interfaces  -->  .xcframework  -->  .NET binding  -->  your C# code
```

The Swift layer wraps StoreKit 2's async APIs behind `@objc`-compatible delegate and completion-block patterns. The .NET binding project provides C# types that map to the ObjC interface. Your code interacts only with the C# types.

## License

MIT
