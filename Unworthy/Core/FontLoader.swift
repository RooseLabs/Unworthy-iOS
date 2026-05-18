import CoreText
import Foundation

enum FontLoader {
    private static var cachedNames: [String: String] = [:]
    private static var failedFiles = Set<String>()

    static func getFont(fileName: String) -> String? {
        if let cached = cachedNames[fileName] {
            return cached
        }
        if failedFiles.contains(fileName) {
            return nil
        }
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            failedFiles.insert(fileName)
            return nil
        }
        var registrationError: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &registrationError) {
            if let error = registrationError?.takeRetainedValue() {
                NSLog("Font registration failed: %@", String(describing: error))
            }
        }
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let descriptor = descriptors.first,
              let postScriptName = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String else {
            failedFiles.insert(fileName)
            return nil
        }
        cachedNames[fileName] = postScriptName
        return postScriptName
    }
}
