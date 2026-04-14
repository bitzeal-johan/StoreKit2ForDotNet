import Foundation

@objc(SK2WrapperDelegate) public protocol SK2WrapperDelegate: AnyObject {
    @objc func sk2Wrapper(_ wrapper: SK2Wrapper, didUpdateEntitlements transactions: [SK2TransactionInfo])
    @objc optional func sk2Wrapper(_ wrapper: SK2Wrapper, didEncounterError error: NSError)
}
