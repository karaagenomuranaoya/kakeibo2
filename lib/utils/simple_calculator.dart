class SimpleCalculator {
  /// 文字列の数式を計算して結果を返す
  /// 日本円の家計簿なので、結果は必ず「四捨五入した整数」の文字列を返す
  static String calculate(String expression) {
    if (expression.isEmpty) return "";

    // 1. カンマを除去
    String cleanExpr = expression.replaceAll(',', '');

    // 2. 末尾が演算子の場合は削除して計算する (例: "100+" -> "100")
    if (_isOperator(cleanExpr[cleanExpr.length - 1])) {
      cleanExpr = cleanExpr.substring(0, cleanExpr.length - 1);
    }

    try {
      final tokens = _tokenize(cleanExpr);
      if (tokens.isEmpty) return expression;

      final double result = _evaluateTokens(tokens);

      // ▼▼ 修正箇所: ここで強制的に四捨五入して整数にする ▼▼
      // 家計簿（円）に小数は不要なため、四捨五入(round)を行って整数文字列にする
      return result.round().toString();
    } catch (e) {
      // 計算不能な場合（ゼロ除算など）は元の文字列を返すか、"0"にする
      return expression;
    }
  }

  static bool _isOperator(String char) {
    return ["+", "-", "x", "÷"].contains(char);
  }

  static List<dynamic> _tokenize(String expr) {
    final List<dynamic> tokens = [];
    String currentNumber = "";

    for (int i = 0; i < expr.length; i++) {
      final char = expr[i];
      if (_isOperator(char)) {
        // ▼▼ 修正: 先頭のマイナス、または演算子直後のマイナスは「負の数」の一部とみなす ▼▼
        // 例: "-100", "50x-2" などの対応
        if (char == '-' && currentNumber.isEmpty) {
          // トークンがまだ空（先頭）か、直前が演算子（currentNumberが空かつtokensの末尾が演算子）の場合
          // ただし、家計簿アプリのキーボード仕様上、"50x-2"は入力できないようになっているため、
          // 「先頭のマイナス」だけケアすればOKです。
          bool isNegativeSign = false;
          if (tokens.isEmpty) {
            isNegativeSign = true;
          } else {
            // 念のため、前のトークンが演算子ならマイナス符号扱いにするロジック
            final lastToken = tokens.last;
            if (lastToken is String && _isOperator(lastToken)) {
              isNegativeSign = true;
            }
          }

          if (isNegativeSign) {
            currentNumber += char;
            continue;
          }
        }
        // ▲▲ 修正ここまで ▲▲
        if (currentNumber.isNotEmpty) {
          tokens.add(double.parse(currentNumber));
          currentNumber = "";
        }
        tokens.add(char);
      } else {
        currentNumber += char;
      }
    }
    if (currentNumber.isNotEmpty) {
      tokens.add(double.parse(currentNumber));
    }
    return tokens;
  }

  static double _evaluateTokens(List<dynamic> tokens) {
    // 1. 乗算・除算を先に計算
    final List<dynamic> processing = [];
    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];
      if (token == "x" || token == "÷") {
        final operator = token;
        // 先頭がいきなり演算子などの不正なケース対策
        if (processing.isEmpty || i + 1 >= tokens.length) {
          i++;
          continue;
        }

        final left = processing.removeLast() as double;
        final right = tokens[i + 1] as double;

        double result = 0;
        if (operator == "x") result = left * right;
        if (operator == "÷") {
          // ゼロ除算対策（無限大になっても round() でエラーにならないようガード）
          if (right == 0) {
            result = 0; // または left をそのまま返す仕様もアリ
          } else {
            result = left / right;
          }
        }

        processing.add(result);
        i += 2;
      } else {
        processing.add(token);
        i++;
      }
    }

    // 2. 加算・減算を計算
    if (processing.isEmpty) return 0;

    double finalResult = processing[0] as double;
    for (int j = 1; j < processing.length; j += 2) {
      final operator = processing[j];
      final right = processing[j + 1] as double;

      if (operator == "+") finalResult += right;
      if (operator == "-") finalResult -= right;
    }

    return finalResult;
  }
}
