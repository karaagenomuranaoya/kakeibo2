import 'package:flutter/material.dart';
import '../models/category_tag.dart';
import '../screens/monthly_report_screen.dart';
import '../screens/history_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'メニュー',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('月別レポート'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MonthlyHistoryScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader("費目別"),
          ...expenseTags.map(
            (tag) => _buildFilterTile(context, tag, 'expense'),
          ),
          const SizedBox(height: 15),
          const Divider(),
          _buildSectionHeader("支払い方法別"),
          ...paymentTags.map(
            (tag) => _buildFilterTile(context, tag, 'payment'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 10, bottom: 5),
      child: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildFilterTile(
    BuildContext context,
    CategoryTag tag,
    String filterKey,
  ) {
    return ListTile(
      leading: Icon(
        filterKey == 'payment' ? Icons.payment : Icons.label,
        color: tag.color,
      ),
      title: Text(tag.label),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryScreen(
              filterValue: tag.label,
              filterKey: filterKey,
              color: tag.color,
            ),
          ),
        );
      },
    );
  }
}
