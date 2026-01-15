import 'package:flutter/material.dart';

class CategoryTag {
  final String id;
  final String label;
  final Color color;
  final bool isCircle;

  // --- クレジットカード設定用 ---
  final int? closingDay; // 締め日 (1-28, 99=末日)
  final int? paymentDay; // 支払日 (1-28, 99=末日)
  final int paymentMonthOffset; // 支払月 (1=翌月, 2=翌々月)

  // --- アイコン保存用データ ---
  final int? iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;

  CategoryTag({
    String? id,
    required this.label,
    required this.color,
    this.isCircle = false,
    this.closingDay,
    this.paymentDay,
    this.paymentMonthOffset = 1,
    this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  // 保存された情報からIconDataを復元するgetter
  IconData? get icon {
    if (iconCodePoint == null) return null;
    return IconData(
      iconCodePoint!,
      fontFamily: iconFontFamily,
      fontPackage: iconFontPackage,
    );
  }

  // アプリ全体で使う「表示用アイコン」の取得ロジック
  IconData get displayIcon {
    if (icon != null) return icon!;

    // デフォルト推測ロジック
    final l = label;
    if (l.contains('外食')) return Icons.restaurant;
    if (l.contains('食')) return Icons.local_grocery_store;
    if (l.contains('飲み物') || l.contains('カフェ') || l.contains('酒'))
      return Icons.local_cafe;
    if (l.contains('遊び') || l.contains('レジャー') || l.contains('楽'))
      return Icons.attractions;
    if (l.contains('日用')) return Icons.shopping_bag;
    if (l.contains('交際')) return Icons.wine_bar;
    // 「交通系」もここでヒットして電車アイコンになります
    if (l.contains('交通') || l.contains('電')) return Icons.train;
    if (l.contains('趣味') || l.contains('推')) return Icons.sports_esports;
    if (l.contains('美容') || l.contains('服')) return Icons.checkroom;
    if (l.contains('医療') || l.contains('薬') || l.contains('院'))
      return Icons.medical_services;
    if (l.contains('教育') || l.contains('本')) return Icons.menu_book;
    if (l.contains('光熱') || l.contains('家賃') || l.contains('住'))
      return Icons.home;
    if (l.contains('通信') || l.contains('スマホ')) return Icons.wifi;
    if (l.contains('車') || l.contains('ガソリン')) return Icons.directions_car;
    if (l.contains('給料') || l.contains('給与')) return Icons.attach_money;
    if (l.contains('映画')) return Icons.movie;

    // カード系の推測
    if (l.contains('クレジット') ||
        closingDay != null ||
        l.contains('カード') ||
        l.contains('Pay')) {
      return Icons.credit_card;
    }

    // どうしても決まらない場合
    return isCircle ? Icons.category : Icons.payment;
  }

  factory CategoryTag.fromJson(Map<String, dynamic> json) {
    return CategoryTag(
      id: json['id'],
      label: json['label'],
      color: Color(json['color_value']),
      isCircle: json['is_circle'] ?? false,
      closingDay: json['closing_day'],
      paymentDay: json['payment_day'],
      paymentMonthOffset: json['payment_month_offset'] ?? 1,
      iconCodePoint: json['icon_code_point'],
      iconFontFamily: json['icon_font_family'],
      iconFontPackage: json['icon_font_package'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'color_value': color.value,
      'is_circle': isCircle,
      'closing_day': closingDay,
      'payment_day': paymentDay,
      'payment_month_offset': paymentMonthOffset,
      'icon_code_point': iconCodePoint,
      'icon_font_family': iconFontFamily,
      'icon_font_package': iconFontPackage,
    };
  }

  // ▼▼ あなた仕様のデフォルトカード ▼▼
  static List<CategoryTag> get defaultCards => [
    CategoryTag(
      label: 'クレジット',
      color: Colors.redAccent,
      closingDay: 99, // 仮で末締め翌27日払いに設定
      paymentDay: 27,
      paymentMonthOffset: 1,
    ),
    CategoryTag(label: '交通系', color: Colors.green),
  ];

  static List<CategoryTag> get defaultExpenses => [
    CategoryTag(label: '食費', color: Colors.orange, isCircle: true),
    CategoryTag(label: '外食費', color: Colors.deepOrange, isCircle: true),
    CategoryTag(label: '飲み物代', color: Colors.green, isCircle: true),
    CategoryTag(label: '娯楽費', color: Colors.purple, isCircle: true),
    CategoryTag(label: '交通費', color: Colors.blue, isCircle: true),
    CategoryTag(label: '医療費', color: Colors.blueGrey, isCircle: true),
    CategoryTag(label: '本代', color: Colors.brown, isCircle: true),
    CategoryTag(label: '美容・衣服代', color: Colors.pinkAccent, isCircle: true),
    CategoryTag(label: '家賃', color: Colors.indigo, isCircle: true),
  ];
}
