import 'package:flutter/material.dart';

class DeveloperTipsScreen extends StatelessWidget {
  const DeveloperTipsScreen({super.key});

  // データ定義（ここに追加していけばリストが増えます）
  static const List<_TipItem> _tips = [
    _TipItem(
      title: 'ご挨拶',
      content:
          'どうも。開発者のからくりです。「次へ家計簿」をダウンロードいただきありがとうございます。\n\nこのアプリは従来の家計簿アプリと比べ、シンプルなのに「なんで今までなかったんだろう」という機能を詰め込みました。\n\nこの独り言に使い方のtipsが置いてあるので、よかったらご覧ください。',
      icon: Icons.waving_hand,
      color: Colors.blue,
    ),
    _TipItem(
      title: '変な名前、次へ家計簿',
      content:
          '「次へ」はこのアプリの命です。多くのアプリが1回入力をするたびにキーボードがすとんと降りてしまいます。これでは連続入力の手間が倍増です。\n\nそこで、キーボードの右下に「次へ」ボタンを設置し、保存して次の入力をスムーズに再開することができます。\n\n次の入力へスムーズに、次の未来にまっすぐと。\n\nってのはちょっとかっこつけすぎですかね笑\n次へ家計簿、末長くよろしくお願いいたします。',
      icon: Icons.keyboard_return,
      color: Colors.indigo,
    ),
    _TipItem(
      title: '収入記録、なくしちゃいました',
      content:
          'このアプリは家計簿なのに収入欄がなく支出のみの記録となっています。\n\n私自身が他の家計簿を使っていて、「収入を入力するとあといくら使えるかが明確になる→言い換えれば、きちんと毎回つけないと金銭感覚がずれていく→毎回つけなきゃ！というプレッシャーになる→家計簿をやめる」という経験をしてきたことに基づいています。\n\nたまにサボっても、「ちょっと使いすぎている気がする、まずい」程度の緩いブレーキになれればという思いがあります。',
      icon: Icons.money_off,
      color: Colors.green,
    ),
    _TipItem(
      title: '支払い明細にジャンプ',
      content: '入力欄のカード項目をオンにするとカードの選択が出てきますが、これを長押しするとそのカードの明細に飛びます。地味に便利。',
      icon: Icons.credit_card,
      color: Colors.purple,
    ),
    _TipItem(
      title: '円グラフからジャンプ',
      content: '円グラフ画面の下の凡例からも費目詳細に飛ぶことができます。地味に便利。',
      icon: Icons.pie_chart,
      color: Colors.orange,
    ),
    _TipItem(
      title: '気づいていますか？取り消し機能',
      content:
          '費目を入力したあと、あ、間違えたと思ったら取り消し機能の出番です。入力画面の下の方にある取り消しボタンで、直前の入力をなかったことにできます。地味に便利。',
      icon: Icons.undo,
      color: Colors.redAccent,
    ),
    _TipItem(
      title: 'まさかのガチャ機能',
      content:
          '本当におまけ機能ですが、3回支出を入力するとガチャが回せます。キャラクターは100種類程度、2段階進化という謎のこだわりが見えるので、暇があればぜひお試しください。\n\nそんなのいらないよ、という方は、設定からガチャのタブ項目を消すことも可能です。',
      icon: Icons.star,
      color: Colors.amber,
    ),
    // ▼▼ 追加: バックアップについてのTip ▼▼
    _TipItem(
      title: '機種変更とバックアップ',
      content:
          'このアプリは面倒な会員登録がありません。つまり、データはすべてあなたのスマホの中に保存されています。\n\n機種変更の際は、iPhoneならiCloud、AndroidならGoogleの標準バックアップ機能を使えばデータを引き継ぐことができます。\n\n逆に言うと、運営側ではデータを預かっていないので、バックアップなしにスマホをなくすとデータも一緒に消えてしまいます。自己責任でご利用ください。',
      icon: Icons.cloud_sync,
      color: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('管理人の独り言 & Tips')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tips.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final tip = _tips[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: tip.color.withOpacity(0.1),
              child: Icon(tip.icon, color: tip.color),
            ),
            title: Text(
              tip.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => _TipDetailDialog(tip: tip),
              );
            },
          );
        },
      ),
    );
  }
}

class _TipItem {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _TipItem({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });
}

class _TipDetailDialog extends StatelessWidget {
  final _TipItem tip;

  const _TipDetailDialog({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ヘッダー部分
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: tip.color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Icon(tip.icon, size: 48, color: tip.color),
                const SizedBox(height: 10),
                Text(
                  tip.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // 本文部分（スクロール可能にする）
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                tip.content,
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
            ),
          ),
          const Divider(height: 1),
          // 閉じるボタン
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Text('閉じる', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
