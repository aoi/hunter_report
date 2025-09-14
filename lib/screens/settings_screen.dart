import 'package:flutter/material.dart';
import 'package:hunter_report/services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _hunterCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // hunterTableの内容をロードし、各フォームに表示する。
    DatabaseHelper().getHunter().then((hunter) {
      if (hunter != null) {
        setState(() {
          _nameController.text = hunter.name ?? '';
          _addressController.text = hunter.address ?? '';
          _hunterCodeController.text = hunter.hunterCode ?? '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          // You may want to use a GlobalKey<FormState> for validation
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '狩猟者情報',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '氏名',
                  border: OutlineInputBorder(),
                ),
                controller: _nameController,
                // validator: (value) => value == null || value.isEmpty ? '氏名を入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '住所',
                  border: OutlineInputBorder(),
                ),
                controller: _addressController,
                // validator: (value) => value == null || value.isEmpty ? '住所を入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '従事者番号',
                  border: OutlineInputBorder(),
                ),
                controller: _hunterCodeController,
                // validator: (value) => value == null || value.isEmpty ? '登録番号を入力してください' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // 保存処理をここに実装
                    // フォームの値を取得してDBに保存
                    final name = _nameController.text.trim();
                    final address = _addressController.text.trim();
                    final hunterCode = _hunterCodeController.text.trim();

                    if (name.isEmpty || address.isEmpty || hunterCode.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('全ての項目を入力してください')),
                      );
                      return;
                    }

                    try {
                      final dbHelper = DatabaseHelper();
                      await dbHelper.upsertHunter(
                        name: name,
                        address: address,
                        hunterCode: hunterCode,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('保存しました')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('保存に失敗しました')),
                      );
                    }
                  },
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}