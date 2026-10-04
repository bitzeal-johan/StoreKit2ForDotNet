#nullable enable
using System;
using System.Threading.Tasks;
using Foundation;

namespace SK2ForDotNet;

public sealed record AppTransactionInfo(
    string OriginalAppVersion,
    DateTimeOffset OriginalPurchaseDate,
    bool IsVerified);

public static class SK2WrapperAppTransactionExtensions
{
    // Throws NSErrorException when StoreKit fails or the device is below iOS 16.
    public static Task<AppTransactionInfo> GetAppTransactionAsync(this SK2Wrapper wrapper)
    {
        var completion = new TaskCompletionSource<AppTransactionInfo>();
        wrapper.FetchAppTransaction((appTransaction, error) =>
        {
            if (appTransaction is null)
            {
                completion.SetException(new NSErrorException(error ?? new NSError(new NSString("SK2ForDotNet"), 0)));
                return;
            }
            completion.SetResult(new AppTransactionInfo(
                appTransaction.OriginalAppVersion,
                new DateTimeOffset((DateTime)appTransaction.OriginalPurchaseDate, TimeSpan.Zero),
                appTransaction.IsVerified));
        });
        return completion.Task;
    }
}
