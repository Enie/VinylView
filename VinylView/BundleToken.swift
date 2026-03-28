import Foundation

// Bundle accessor that works both as a framework (xcodeproj) and as an SPM package.
// SPM generates Bundle.module only when building as a package; frameworks use Bundle(for:).
extension Bundle {
    static var vinylView: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle(for: _BundleToken.self)
        #endif
    }
}

private final class _BundleToken: NSObject {}
