import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class InputTabTutorial {
  static void show(
    BuildContext context, {
    required GlobalKey paymentKey,
    required GlobalKey categoryKey,
    required bool showCardOnInput,
    required VoidCallback onFinish,
  }) {
    // ターゲットの作成
    List<TargetFocus> targets = [];

    // 1. 支払い方法選択（表示されている場合のみ）
    if (showCardOnInput && paymentKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "payment_selector",
          keyTarget: paymentKey,
          alignSkip: Alignment.topRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "支払い方法の選択",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "左右にスワイプして「カード」や「記録しない（記録なし）」を切り替えられます。\n\n長押しすると、そのカードの利用明細へジャンプします。",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 10,
        ),
      );
    }

    // 2. カテゴリ選択
    if (categoryKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "category_selector",
          keyTarget: categoryKey,
          alignSkip: Alignment.topRight,
          contents: [
            TargetContent(
              align: ContentAlign.top, // 上側に表示
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "支出の記録",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "ここで費目（カテゴリー）を選択できます。\n\n長押しすると、その費目の履歴へジャンプします。",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 10,
        ),
      );
    }

    if (targets.isEmpty) {
      onFinish();
      return;
    }

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "スキップ",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: onFinish,
      onClickTarget: (target) {},
      onClickOverlay: (target) {},
      onSkip: () {
        onFinish();
        return true;
      },
    ).show(context: context);
  }
}
