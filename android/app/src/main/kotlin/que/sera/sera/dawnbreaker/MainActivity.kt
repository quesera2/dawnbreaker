package que.sera.sera.dawnbreaker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import que.sera.sera.dawnbreaker.util.FuriganaTranslate

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(FuriganaTranslate())
    }
}
