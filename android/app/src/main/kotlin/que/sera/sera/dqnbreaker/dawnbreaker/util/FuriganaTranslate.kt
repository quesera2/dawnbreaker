package que.sera.sera.dqnbreaker.dawnbreaker.util

import com.atilika.kuromoji.ipadic.Tokenizer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FuriganaTranslate : FlutterPlugin, MethodCallHandler {

    companion object {
        private const val CHANNEL_NAME = "que.sera.sera/furigana.translate"

        private const val METHOD_TRANSLATE_TO_FURIGANA = "translateToFurigana"
    }

    private lateinit var channel: MethodChannel

    private lateinit var tokenizer: Tokenizer

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        tokenizer = Tokenizer()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == METHOD_TRANSLATE_TO_FURIGANA) {
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

    private fun toHiragana(
        text: String
    ): String = buildString {
        for (c in text) {
            append(if (c.isKatakana) c.katakanaToHiragana() else c)
        }
    }

    private val Char.isKatakana: Boolean
        get() = this in 'ァ'..'ヶ'

    private fun Char.katakanaToHiragana(): Char = 'ぁ' + (this - 'ァ')

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}