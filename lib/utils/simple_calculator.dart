class SimpleCalculator {
  /// 文字列の数式を計算して結果を返す
  /// エラーや計算不能な場合は元の文字列または"Error"を返すなどの処理を行う
  static String calculate(String expression) {
    if (expression.isEmpty) return "";

    // 末尾が演算子の場合は削除して計算する
    String cleanExpr = expression;
    if (_isOperator(cleanExpr[cleanExpr.length - 1])) {
      cleanExpr = cleanExpr.substring(0, cleanExpr.length - 1);
    }

    try {
      // 簡易的な計算ロジック（四則演算のみ対応）
      // 演算子の優先順位を考慮してトークン化
      final tokens = _tokenize(cleanExpr);
      if (tokens.isEmpty) return expression;

      final result = _evaluateTokens(tokens);

      // 整数で表現できるなら整数に、そうでなければ小数（最大2桁）
      if (result == result.toInt()) {
        return result.toInt().toString();
      } else {
        return result
            .toStringAsFixed(2)
            .replaceAll(RegExp(r"0+$"), "")
            .replaceAll(RegExp(r"\.$"), "");
      }
    } catch (e) {
      // 計算エラー時はそのまま返す（ユーザーに修正させる）
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
        final left = processing.removeLast() as double;
        final right = tokens[i + 1] as double;

        double result = 0;
        if (operator == "x") result = left * right;
        if (operator == "÷") result = left / right;

        processing.add(result);
        i += 2;
      } else {
        processing.add(token);
        i++;
      }
    }

    // 2. 加算・減算を計算
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
