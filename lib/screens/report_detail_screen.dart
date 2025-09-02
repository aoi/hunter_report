import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/hunt_report.dart';
import '../services/pdf_service.dart';

class ReportDetailScreen extends StatelessWidget {
  final HuntReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('報告詳細'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReport(context),
            tooltip: 'PDFを共有',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本情報カード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '基本情報',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('捕獲場所', report.location),
                    _buildInfoRow('捕獲日時', _formatDateTime(report.dateTime)),
                    if (report.latitude != null && report.longitude != null)
                      _buildInfoRow('座標', '${report.latitude}, ${report.longitude}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 獲物情報セクション
            ...report.gameItems.asMap().entries.map((entry) {
              final index = entry.key;
              final gameItem = entry.value;
              return _buildGameItemCard(context, index, gameItem);
            }).toList(),

            // アクションボタン
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _generateAndSharePDF(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDFを生成して共有'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameItemCard(BuildContext context, int index, GameItem gameItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '獲物 ${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: Colors.green[100],
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Text(
                     '${gameItem.totalCount}頭',
                     style: TextStyle(
                       color: Colors.green[800],
                       fontSize: 12,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
              ],
            ),
            const SizedBox(height: 16), 
            _buildInfoRow('獲物の種類', gameItem.animalType),
            _buildInfoRow('銃器', '${gameItem.gunCount}頭'),
            _buildInfoRow('くくりわな', '${gameItem.snareCount}頭'),
            _buildInfoRow('箱わな', '${gameItem.boxTrapCount}頭'),
            _buildInfoRow('総頭数', '${gameItem.totalCount}頭'),
            
            if (gameItem.imagePaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '写真',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: gameItem.imagePaths.length,
                itemBuilder: (context, imageIndex) {
                  return GestureDetector(
                    onTap: () => _showImageFullScreen(context, gameItem.imagePaths, imageIndex),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(gameItem.imagePaths[imageIndex]),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
  }

  void _showImageFullScreen(BuildContext context, List<String> imagePaths, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('写真 ${initialIndex + 1}/${imagePaths.length}'),
          ),
          body: PageView.builder(
            itemCount: imagePaths.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Image.file(
                    File(imagePaths[index]),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndSharePDF(BuildContext context) async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      print('PDF生成開始: ${report.gameItems.length}種類の獲物');
      
      // PDF生成
      final pdfFile = await PdfService.generateHuntReport(report);
      
      print('PDF生成完了: ${pdfFile.path}');
      
      // ローディングを閉じる
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 共有
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: '狩猟報告書: ${report.gameItems.map((item) => item.animalType).join(', ')}',
        subject: '狩猟報告書',
      );
    } catch (e) {
      print('PDF生成エラー: $e');
      
      // ローディングを閉じる
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // エラーダイアログ表示
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラー'),
          content: Text('PDFの生成に失敗しました\n\nエラー: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _shareReport(BuildContext context) async {
    await _generateAndSharePDF(context);
  }
}

