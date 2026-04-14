import Flutter
import UIKit

public class FuriganaTranslate: NSObject, FlutterPlugin {
    
    private static let channelName = "que.sera.sera/furigana.translate"
    private static let methodTranslateToFurigana = "translateToFurigana"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName,
                                           binaryMessenger: registrar.messenger())
        let instance = FuriganaTranslate()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case FuriganaTranslate.methodTranslateToFurigana:
            guard let text = call.arguments as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "String argument expected", details: nil))
                return
            }
            result(convert(text))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func convert(_ input: String) -> String {
        let cfString = input as CFString
        let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            cfString,
            CFRangeMake(0, input.utf16.count),
            kCFStringTokenizerUnitWordBoundary,
            Locale(identifier: "ja_JP") as CFLocale
        )
        
        var output = ""
        var tokenType = CFStringTokenizerGoToTokenAtIndex(tokenizer, 0)
        
        while tokenType.rawValue != 0 {
            let cfRange = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            // 直接ひらがなは取得できないため、一度ローマ字読みを取得してひらがなに変換する
            if let latin = CFStringTokenizerCopyCurrentTokenAttribute(
                tokenizer,
                kCFStringTokenizerAttributeLatinTranscription
            ) as? String {
                let mutable = NSMutableString(string: latin)
                if CFStringTransform(mutable, nil, kCFStringTransformLatinHiragana, false) {
                    output.append(mutable as String)
                } else if let original = CFStringCreateWithSubstring(kCFAllocatorDefault, cfString, cfRange) as? String {
                    output.append(original)
                }
            } else if let original = CFStringCreateWithSubstring(kCFAllocatorDefault, cfString, cfRange) as? String {
                output.append(original)
            }
            
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }
        return output
    }
}
