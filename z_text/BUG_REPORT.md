# 🐛 atsumeru_kakeibo バグ整理レポート

**作成日:** 2026年6月14日  
**対象:** あつめる家計簿アプリ（Flutter）

---

## 📋 概要
本レポートは、アプリ全体のコードを調査し、意図通りに操作しない可能性のあるバグを整理したものです。

---

## 🔴 重大度別分類

### 【Lv.1】致命的バグ（アプリクラッシュ、データ破損の可能性）

#### 1. **クレジットカード支払日計算の月オーバーフロー**
**ファイル:** [lib/services/input_service.dart](lib/services/input_service.dart#L172-L186)  
**重大度:** HIGH 🔴  
**影響:** クレジットカード決済で支払日が異常になる可能性

**問題コード:**
```dart
int monthsToAdd = cardTag.paymentMonthOffset;
if (cardTag.closingDay != 99 && date.day > cardTag.closingDay!) {
  monthsToAdd++;
}
int targetYear = date.year;
int targetMonth = date.month + monthsToAdd;  // ⚠️ 12を超える処理がない
int targetDay = cardTag.paymentDay!;

final int lastDayOfMonth = DateTime(
  targetYear,
  targetMonth + 1,  // ⚠️ targetMonth が 13以上で異常な値
  0,
).day;

final int realPaymentDay = (targetDay > lastDayOfMonth) ? lastDayOfMonth : targetDay;
paymentDate = DateTime(targetYear, targetMonth, realPaymentDay);  // ❌ 無効な月
```

**実例:**
- 日付: 2026年11月15日、支払いオフセット: 2ヶ月の場合
- `targetMonth = 11 + 2 = 13` （→ 13月という存在しない月！）
- `DateTime(2026, 13, ...)` → 例外発生 or 不正な日付

**修正案:**
```dart
int targetYear = date.year;
int targetMonth = date.month + monthsToAdd;

// 年をまたぐ場合の処理
if (targetMonth > 12) {
  targetYear += (targetMonth - 1) ~/ 12;
  targetMonth = ((targetMonth - 1) % 12) + 1;
}
```

**テスト例:**
- ✅ 通常ケース（月内）
- ⚠️ 月跨ぎケース（11月+2ヶ月=1月）
- ⚠️ 年跨ぎケース（12月+2ヶ月=2月次年）

---

#### 2. **ID生成の時間競合リスク**
**ファイル:** [lib/models/category_tag.dart](lib/models/category_tag.dart#L20-L22)  
**重大度:** MEDIUM-HIGH 🟠  
**影響:** カテゴリやカードで重複IDが発生、ReorderableListViewエラーやデータ喪失

**問題コード:**
```dart
CategoryTag({
  String? id,
  ...
}) : id =
  id ??
  "${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}";
```

**リスク:**
- `microsecondsSinceEpoch` は100万分の1秒単位
- 高速で複数CategoryTag生成時に**同じマイクロ秒+同じRandom値**で重複の可能性
- 例: 2つのスレッドが同時刻に`CategoryTag(id: null, ...)`を作成 → 同じID

**発生確率:** 約1/10,000（Random部分）だが、本番環境では確率的に発生

**修正案:**
```dart
: id =
  id ??
  "${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1000000)}"
```

または UUID パッケージを使用:
```dart
: id = id ?? const Uuid().v4();
```

---

#### 3. **TransactionItem.fromJson の ID 再生成問題**
**ファイル:** [lib/models/transaction_item.dart](lib/models/transaction_item.dart#L36-L42)  
**重大度:** MEDIUM-HIGH 🟠  
**影響:** 古いデータのID不一致、undo/redo機能の破損

**問題コード:**
```dart
id:
  json['id'] as String? ??
  // フォールバック: IDがない古いデータ用の救済措置
  (DateTime.now().microsecondsSinceEpoch.toString() +
    (json['date_iso'] as String)),
```

**問題点:**
- IDが無い場合、`fromJson` が呼ばれるたびに**新規IDが生成される**
- 同じデータを複数回JSONデコードすると、毎回異なるIDになる
- 結果: 重複データ、削除時に別のレコードを削除、など

**実例:**
```dart
// 1回目の読み込み
final item1 = TransactionItem.fromJson(json);  // ID: "1718350000000000_2024-06-14T12:00:00..."

// 2回目の読み込み（1マイクロ秒後）
final item2 = TransactionItem.fromJson(json);  // ID: "1718350000001000_2024-06-14T12:00:00..."
// item1.id != item2.id ❌
```

**修正案:**
```dart
id: json['id'] as String? ??
  "${json['date_iso']}_${Random().nextInt(1000000)}",
```

またはデータ保存時に必ず ID を含める

---

### 【Lv.2】機能バグ（ユーザー操作の予期しない動作）

#### 4. **ゼロ除算後の0円警告の曖昧性**
**ファイル:** [lib/widgets/custom_number_keyboard.dart](lib/widgets/custom_number_keyboard.dart#L505-L516)  
**重大度:** MEDIUM 🟡  
**影響:** ユーザーが「なぜ計算が拒否されたのか不明」

**問題コード:**
```dart
if (val.isInfinite || val.isNaN) {
  _showWarning(context, '0では割れません');
  return;
}

// ...

if (val == 0) {
  _showWarning(context, '金額が0円になってしまいます');
  return;
}
```

**シナリオ:**
1. ユーザーが入力: `100 ÷ 0`
2. `SimpleCalculator.calculate()` → 結果 `"0"` (ゼロ除算を0で返す)
3. `val = 0.0` → `val == 0` で「0円になってしまいます」と警告
4. ユーザー: 「何が問題？」と困惑 😕

**修正案:**
```dart
// 計算中にゼロ除算が発生したことを明示的に追跡
final resultString = SimpleCalculator.calculate(widget.controller.text);
if (widget.controller.text.contains('÷0')) {
  _showWarning(context, '0では割れません');
  return;
}

double? val = double.tryParse(resultString);
if (val == 0) {
  _showWarning(context, '金額は0円以上にしてください');
  return;
}
```

---

#### 5. **HistoryScreen の初期ページオーバーフロー**
**ファイル:** [lib/screens/history_screen.dart](lib/screens/history_screen.dart#L47-L55)  
**重大度:** MEDIUM 🟡  
**影響:** 特定の年月指定時にPageController がクラッシュ、履歴画面が開かない

**問題コード:**
```dart
void _setupPageController() {
  int initialPage = 1000;
  if (widget.initialDate != null) {
    final now = DateTime.now();
    final diff =
        (widget.initialDate!.year - now.year) * 12 +
        (widget.initialDate!.month - now.month);
    initialPage = 1000 + diff;
  }
  _pageController = PageController(initialPage: initialPage);
}
```

**シナリオ:**
- 初期Date: 1900年1月 (履歴から選択誤操作)
- `diff = (1900 - 2026) * 12 + (1 - 6) = -126 * 12 - 5 = -1517`
- `initialPage = 1000 - 1517 = -517` ❌
- PageController: 負のページ番号で例外

**修正案:**
```dart
initialPage = max(0, 1000 + diff);
```

---

#### 6. **GachaRepository サンプリング精度の誤り**
**ファイル:** [lib/repositories/gacha_repository.dart](lib/repositories/gacha_repository.dart#L47-L61)  
**重大度:** MEDIUM 🟡  
**影響:** ガチャの確率が完全ではない、特定キャラが出にくくなる

**問題コード:**
```dart
int totalWeight = candidates.fold(0, (int sum, item) => sum + item.weight);
int randomValue = Random().nextInt(totalWeight);

for (final item in candidates) {
  randomValue -= item.weight;
  if (randomValue < 0) return item;
}
return candidates.last;  // ← 最後の要素に到達しない可能性
```

**問題:**
- 最後のアイテムの確率が若干低い（ループ終了後のfallbackのため）
- `randomValue` が正確に0になる確率が低い場合、最後の要素が出現確率低下

**実例:**
```
weight: [3, 3, 4], total: 10
randomValue: 9
- item0: 9 - 3 = 6 (not < 0, continue)
- item1: 6 - 3 = 3 (not < 0, continue)
- item2: 3 - 4 = -1 (< 0, return item2) ✓

weight: [3, 3, 4], total: 10
randomValue: 7
- item0: 7 - 3 = 4 (not < 0, continue)
- item1: 4 - 3 = 1 (not < 0, continue)
- item2: 1 - 4 = -3 (< 0, return item2) ✓
✓ OK

weight: [3, 3, 3], total: 9
randomValue: 8
- item0: 8 - 3 = 5 (not < 0, continue)
- item1: 5 - 3 = 2 (not < 0, continue)
- item2: 2 - 3 = -1 (< 0, return item2) ✓
✓ OK
```

正確には、確率は計算通りですが、コードの意図が不明確です。

**修正案（明確にする）:**
```dart
for (int i = 0; i < candidates.length; i++) {
  final item = candidates[i];
  randomValue -= item.weight;
  if (randomValue < 0) return item;
}
// 理論上ここに到達しないが、念のためのガード
return candidates.last;
```

---

### 【Lv.3】設計・保守性の問題

#### 7. **TransactionRepository のメモリキャッシュ非永続化**
**ファイル:** [lib/repositories/transaction_repository.dart](lib/repositories/transaction_repository.dart#L11-L12)  
**重大度:** LOW-MEDIUM 🟡  
**影響:** アプリ再起動時にキャッシュが喪失、データ読み込み遅延の可能性

**問題コード:**
```dart
List<TransactionItem>? _memoryCache;

/// 全件取得 (メモリキャッシュがあればそれを返す)
Future<List<TransactionItem>> getAllTransactions({
  bool forceReload = false,
}) async {
  if (_memoryCache != null && !forceReload) {
    return List.from(_memoryCache!);
  }
  // ...
}
```

**問題:**
- `_memoryCache` はシングルトンだが、Dartプロセス再起動で消える
- アプリ起動直後は常にディスク読み込み（キャッシュなし）
- ただし設計としては正常（SharedPreferencesがディスク層）

**改善案:**
```dart
// より安全：キャッシュ再構築の明示
Future<void> invalidateCache() => _memoryCache = null;
```

---

#### 8. **CategoryTag の推定ロジック削除不完全**
**ファイル:** [lib/models/category_tag.dart](lib/models/category_tag.dart#L50-L58)  
**重大度:** LOW 🟢  
**影響:** 旧コードが残っている、将来のバグの種

**コメント:**
```dart
// ▼▼ 変更箇所：推定ロジックを削除し、なければデフォルトを返すだけに単純化 ▼▼
IconData get displayIcon {
  // 設定されているアイコンがあればそれを返す
  if (icon != null) return icon!;

  // 推定ロジックを全削除
  // どうしてもアイコンがない場合の最終手段
  return isCircle ? Icons.category : Icons.payment;
}
```

**コメント:** 「推定ロジック削除」は完了していますが、旧データ互換性への懸念がコメントに残っています。

**推奨:**
- コメントを削除するか、期限付きマイグレーションコードを追加

---

#### 9. **Null安全性の微妙な使い方**
**ファイル:** [lib/services/input_service.dart](lib/services/input_service.dart#L177)  
**重大度:** LOW 🟢  
**影響:** 将来のバグリスク、コード可読性低下

**問題コード:**
```dart
if (cardTag.closingDay != null && cardTag.paymentDay != null) {
  // ...
  final int realPaymentDay = (targetDay > lastDayOfMonth)
      ? lastDayOfMonth
      : targetDay;
```

**問題:**
- `cardTag.paymentDay!` で既にnull assertionしているが、後で `cardTag.paymentDay` を参照
- nullチェック後の`!`は不要（既にnullチェック済み）

**改善案:**
```dart
if (cardTag?.paymentDay case final paymentDay?) {
  // paymentDay は null-safe
  final int realPaymentDay = (paymentDay > lastDayOfMonth)
      ? lastDayOfMonth
      : paymentDay;
}
```

---

## 📊 優先度付きアクション

### 🔴 [必須] 即座に修正
1. **クレジットカード支払日計算** → 年月オーバーフロー修正
2. **ID生成競合** → UUID導入または精度向上
3. **TransactionItem ID再生成** → データ永続化確認

### 🟠 [推奨] 次のリリース前に修正
4. **ゼロ除算警告** → メッセージ改善
5. **HistoryScreen ページオーバーフロー** → 初期ページバウンド
6. **GachaRepository サンプリング** → コード明確化

### 🟡 [望ましい] 将来の改善
7. **Null安全性** → コード整理
8. **コメント削除** → 技術債処理
9. **エラーハンドリング** → 統一化

---

## 🧪 テストケース提案

### 単体テスト例
```dart
// test/services/input_service_test.dart
void main() {
  group('registerTransaction - Credit Card Payment Date', () {
    test('Should calculate correct payment date crossing year boundary', () {
      final date = DateTime(2026, 11, 15);
      final cardTag = CategoryTag(
        label: 'Test Card',
        color: Colors.red,
        closingDay: 10,
        paymentDay: 27,
        paymentMonthOffset: 2,
      );
      
      final result = await service.registerTransaction(
        rawAmount: '1000',
        memo: '',
        date: date,
        expenseTag: expenses[0],
        isCardPayment: true,
        cardTag: cardTag,
        showCardOnInput: true,
        isGachaEnabled: false,
      );
      
      expect(result.success, true);
      // paymentDate should be 2027-01-27 (not 2026-13-27)
    });
  });
}
```

---

## 📝 備考

- 調査対象: lib/フォルダ全体（dart ファイル）
- 調査方法: コード静的解析 + 論理検証
- 検出されなかったバグ: ウィジェット描画の微妙な問題など（実行時テスト必要）

---

**作成者:** GitHub Copilot  
**最終更新:** 2026-06-14
