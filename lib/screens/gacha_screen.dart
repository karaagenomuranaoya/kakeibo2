import 'dart:math';
import 'package:flutter/material.dart';
import '../repositories/gacha_repository.dart';

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  final GachaRepository _repository = GachaRepository();
  int _credits = 0;
  List<String> _unlockedIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final credits = await _repository.getCredits();
    final unlocked = await _repository.getCollection();
    if (mounted) {
      setState(() {
        _credits = credits;
        _unlockedIds = unlocked;
        _isLoading = false;
      });
    }
  }

  // ガチャを回す処理
  Future<void> _spinGacha() async {
    if (_credits < 3) return;

    // クレジット消費
    final success = await _repository.consumeCredits(3);
    if (!success) return;

    // ランダム抽選
    final random = Random();
    final item = _repository.items[random.nextInt(_repository.items.length)];

    // 保存
    await _repository.unlockItem(item.id);

    // データ再読み込み
    await _loadData();

    // 結果表示ダイアログ
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("GET!!",
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
                const SizedBox(height: 20),
                Image.asset(item.imagePath, height: 150, fit: BoxFit.contain),
                const SizedBox(height: 20),
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(item.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                )
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // クレジットの進捗 (0~3)
    final double progress = (_credits % 3) / 3.0;
    // ガチャが回せる回数
    final int spins = _credits ~/ 3;

    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      body: Column(
        children: [
          // 上部：ステータスエリア
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                const Text("クレジット",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("$_credits",
                        style: const TextStyle(
                            fontSize: 48, fontWeight: FontWeight.bold)),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(" pt",
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: spins > 0 ? 1.0 : progress,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.orange,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 5),
                Text(
                  spins > 0 ? "ガチャが回せます！" : "あと ${3 - (_credits % 3)} 回入力でガチャ！",
                  style: TextStyle(
                      color: spins > 0 ? Colors.orange : Colors.grey,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: spins > 0 ? _spinGacha : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    elevation: spins > 0 ? 5 : 0,
                  ),
                  child: const Text(
                    "ガチャを回す (3pt)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // 下部：コレクションエリア
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("コレクション",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _repository.items.length,
                      itemBuilder: (context, index) {
                        final item = _repository.items[index];
                        final isUnlocked = _unlockedIds.contains(item.id);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: isUnlocked
                                    ? Colors.orange.shade200
                                    : Colors.grey.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              isUnlocked
                                  ? Image.asset(item.imagePath,
                                      height: 60, fit: BoxFit.contain)
                                  : const Icon(Icons.help_outline,
                                      size: 40, color: Colors.grey),
                              const SizedBox(height: 5),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  isUnlocked ? item.name : "???",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isUnlocked ? Colors.black : Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
