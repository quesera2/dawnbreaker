import 'package:flutter/material.dart';

/// 画面の入場アニメーションが終わってから処理を始める。
///
/// この画面が入場し切るまで、送り出した側の画面は破棄されない。残った購読を
/// 抱えたまま `NoLogin` にすると permission-denied になるため、サインアウトを
/// 伴う処理（ログアウト・アカウント削除）は遷移の完了を待ってから始める
mixin AfterTransitionMixin<T extends StatefulWidget> on State<T> {
  Animation<double>? _transition;
  VoidCallback? _pendingAction;

  void runAfterTransition(VoidCallback action) {
    final transition = ModalRoute.of(context)?.animation;
    if (transition == null || transition.isCompleted) {
      action();
      return;
    }
    _pendingAction = action;
    _transition = transition..addStatusListener(_onTransitionStatus);
  }

  @override
  void dispose() {
    _stopWaiting();
    super.dispose();
  }

  void _onTransitionStatus(AnimationStatus status) {
    if (!status.isCompleted) return;
    final action = _pendingAction;
    _stopWaiting();
    action?.call();
  }

  void _stopWaiting() {
    _transition?.removeStatusListener(_onTransitionStatus);
    _transition = null;
    _pendingAction = null;
  }
}
