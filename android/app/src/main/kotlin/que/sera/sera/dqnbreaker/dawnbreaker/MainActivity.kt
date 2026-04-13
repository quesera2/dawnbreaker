package que.sera.sera.dqnbreaker.dawnbreaker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import que.sera.sera.dqnbreaker.dawnbreaker.util.FuriganaTranslate

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(FuriganaTranslate())
    }
}
