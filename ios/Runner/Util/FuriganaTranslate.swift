import Flutter
import UIKit

public class FuriganaTranslate: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "que.sera.sera/furigana.translate",
            binaryMessenger: registrar.messenger()
        )
        let instance = FuriganaTranslate()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "translateToFurigana":
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
        var output = ""
        let range = CFRangeMake(0, input.utf16.count)
        let cfString = input as CFString
        let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            cfString,
            range,
            kCFStringTokenizerUnitWordBoundary,
            Locale(identifier: "ja_JP") as CFLocale
        )
        
        var tokenType = CFStringTokenizerGoToTokenAtIndex(tokenizer, 0)
        while tokenType.rawValue != 0 {
            let cfRange = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            // ローマ字読みを取得してひらがなに変換
            if let latin = CFStringTokenizerCopyCurrentTokenAttribute(
                tokenizer,
                kCFStringTokenizerAttributeLatinTranscription
            ) as? String {
                let mutable = NSMutableString(string: latin)
                if CFStringTransform(mutable, nil, kCFStringTransformLatinHiragana, false) {
                    output.append(mutable as String)
                } else if let sub = CFStringCreateWithSubstring(kCFAllocatorDefault, cfString, cfRange) {
                    // 変換失敗時は元のトークンをそのまま使用
                    output.append(sub as String)
                }
            } else {
                // 英数字・記号など変換できないトークンは元のテキストをそのまま使用
                if let sub = CFStringCreateWithSubstring(kCFAllocatorDefault, cfString, cfRange) {
                    output.append(sub as String)
                }
            }
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }
        return output
    }
}
