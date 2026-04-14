using ObjCRuntime;

namespace SK2ForDotNet;

[Native]
public enum SK2PurchaseResultType : long
{
    Success = 0,
    UserCancelled = 1,
    Pending = 2,
    Failed = 3
}
