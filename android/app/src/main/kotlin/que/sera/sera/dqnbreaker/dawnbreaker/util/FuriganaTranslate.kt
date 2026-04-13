package que.sera.sera.dqnbreaker.dawnbreaker.util

import com.atilika.kuromoji.ipadic.Tokenizer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FuriganaTranslate : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    private val tokenizer by lazy { Tokenizer() }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(flutterPluginBinding.binaryMessenger, "que.sera.sera/furigana.translate")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "translateToFurigana") {
            val input = call.arguments<String>()
            if (input == null) {
                result.error("INVALID_ARGUMENT", "String argument expected", null)
                return
            }
            val reading = tokenizer.tokenize(input)
                .joinToString("") { token -> token.reading ?: token.surface }
            result.success(toHiragana(reading))
        } else {
            result.notImplemented()
        }
    }

    private fun toHiragana(text: String): String =
        text.map { c -> if (c in 'ァ'..'ヶ') 'ぁ' + (c - 'ァ') else c }.joinToString("")

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}