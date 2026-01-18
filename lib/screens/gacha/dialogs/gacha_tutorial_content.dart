import 'package:flutter/material.dart';
import '../../../widgets/tutorial_overlay.dart';

/// ガチャ画面専用のチュートリアル表示ロジック
class GachaTutorialContent {
  /// フェーズ1: ガチャ画面に初めて来たとき
  static Widget phase1({required VoidCallback onDismiss}) {
    return TutorialOverlay(
      iconData: Icons.auto_awesome,
      iconColor: Colors.orange,
      title: "アイコンガチャへようこそ",
      description:
          "ここでは特別なアイコンが手に入る\nガチャを回すことができます。\n\nチケットは入力で1日5枚まで\n手に入りますが\n今回はお試し用のチケットを\n用意しました。",
      subDescription: "試しに回してみましょう",
      onDismiss: onDismiss,
    );
  }

  /// フェーズ2: 初めてガチャを回した後
  static Widget phase2({required VoidCallback onDismiss}) {
    return TutorialOverlay(
      iconData: Icons.grid_view,
      iconColor: Colors.white,
      title: "コレクション",
      description:
          "手に入れたアイコンはここに並びます。\n\nタップすると詳細が見られるほか、\nカテゴリを編集するときには\nアイコンとして使えます。\n同じものが出ると10段階で進化します。",
      subDescription: "コンプリート目指して\n頑張ってくださいね",
      onDismiss: onDismiss,
    );
  }
}
