import 'dart:io';
import 'package:hunter_report/models/hunter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/hunt_report.dart';
import 'package:printing/printing.dart';

class PdfService {
  static Future<File> generateHuntReport(Hunter? hunter, HuntReport report) async {
    try {
      final pdf = pw.Document();
      // Google Fontsを使用して日本語フォントを読み込む
      pw.Font? font;
      try {
        font = await PdfGoogleFonts.notoSansJPRegular();
      } catch (fontError) {
        print('Google Fonts読み込みエラー: $fontError');
        print('デフォルトフォントを使用します');
        font = null;
      }

      // 全ての画像を読み込む
      Map<int, List<pw.MemoryImage>> huntedAnimalImages = {};
      for (int i = 0; i < report.huntedAnimals.length; i++) {
        final huntedAnimal = report.huntedAnimals[i];
        List<pw.MemoryImage> images = [];
        for (String imagePath in huntedAnimal.imagePaths) {
          try {
            final file = File(imagePath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              images.add(pw.MemoryImage(bytes));
            }
          } catch (e) {
            print('Error loading image: $e');
          }
        }
        huntedAnimalImages[i] = images;
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Wrap(
            children: [
              pw.Header(level: 0, child: pw.Text('狩猟報告書', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: font))),
              pw.Text('捕獲情報', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font)),
              // pw.SizedBox(height: 8),
              // 捕獲者情報
              pw.SizedBox(height: 16),
              pw.Table(border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(5),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        color: PdfColors.grey300,
                        child: pw.Text('捕獲者氏名', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: pw.Text(hunter?.name ?? '', style: pw.TextStyle(font: font)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        color: PdfColors.grey300,
                        child: pw.Text('捕獲者住所', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: pw.Text(hunter?.address ?? '', style: pw.TextStyle(font: font)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        color: PdfColors.grey300,
                        child: pw.Text('従事者番号', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: pw.Text(hunter?.hunterCode ?? '', style: pw.TextStyle(font: font)),
                      ),
                    ],
                  ),
                ]
              ),

              pw.SizedBox(height: 16),

              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(5),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        color: PdfColors.grey300,
                        child: pw.Text('捕獲年月日', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: pw.Text(_formatDate(report.dateTime), style: pw.TextStyle(font: font)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        color: PdfColors.grey300,
                        child: pw.Text('捕獲場所', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: pw.Text(report.location, style: pw.TextStyle(font: font)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        color: PdfColors.grey300,
                        child: pw.Text('メッシュ番号', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: pw.Text(report.meshNumber ?? '', style: pw.TextStyle(font: font)),
                      ),
                    ],
                  ),
                  // if (report.latitude != null && report.longitude != null)
                  //   pw.TableRow(
                  //     children: [
                  //       pw.Container(
                  //         padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  //         color: PdfColors.grey300,
                  //         child: pw.Text('座標', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                  //       ),
                  //       pw.Container(
                  //         padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  //         child: pw.Text('${report.latitude}, ${report.longitude}', style: pw.TextStyle(font: font)),
                  //       ),
                  //     ],
                  //   ),
                ],
              ),

              // 獲物情報
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 16),
                child: pw.Table(
                  border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
                  columnWidths: {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(1),
                    3: pw.FlexColumnWidth(1),
                    4: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: pw.Text('獲物の種類', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: pw.Text('銃器', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: pw.Text('くくりわな', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: pw.Text('箱わな', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: pw.Text('総頭数', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                        ),
                      ],
                    ),
                    ...report.huntedAnimals.asMap().entries.map((entry) {
                      final index = entry.key;
                      final huntedAnimal = entry.value;
                      return pw.TableRow(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            child: pw.Text(huntedAnimal.animalType, style: pw.TextStyle(font: font)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            child: pw.Text('${huntedAnimal.gunCount}頭', style: pw.TextStyle(font: font)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            child: pw.Text('${huntedAnimal.snareCount}頭', style: pw.TextStyle(font: font)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            child: pw.Text('${huntedAnimal.boxTrapCount}頭', style: pw.TextStyle(font: font)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            child: pw.Text('${huntedAnimal.totalCount}頭', style: pw.TextStyle(font: font)),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),

              // 確認
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('確認欄', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font)),
                    pw.Table(
                      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
                      columnWidths: {
                        0: pw.FlexColumnWidth(2),
                        1: pw.FlexColumnWidth(5),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              color: PdfColors.grey300,
                              child: pw.Text('確認者', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              child: pw.Text('', style: pw.TextStyle(font: font)),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              color: PdfColors.grey300,
                              child: pw.Text('確認年月日', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              child: pw.Text('', style: pw.TextStyle(font: font)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          )
        )
      );

      // 各獲物の写真ページを追加
      for (int i = 0; i < report.huntedAnimals.length; i++) {
        final huntedAnimal = report.huntedAnimals[i];
        final images = huntedAnimalImages[i] ?? [];
        
        if (images.isNotEmpty) {
          for (var image in images) {
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                theme: font != null ? pw.ThemeData.withFont(base: font) : null,
                build: (pw.Context context) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.all(16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(huntedAnimal.animalType, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font)),
                        pw.SizedBox(height: 16),
                        pw.Center(
                          child: pw.Image(
                            image, 
                            width: PdfPageFormat.a4.availableWidth * 0.8,
                            height: PdfPageFormat.a4.availableHeight * 0.8, 
                            fit: pw.BoxFit.contain,
                          )
                        )
                      ]
                    )
                  );
                }
              )
            );
          }
        }
      }

      print('PDF保存開始');
      // PDFファイルを保存
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/hunt_report_${report.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      print('PDF保存完了: ${file.path}');
      return file;
    } catch (e) {
      print('PDF生成エラー詳細: $e');
      rethrow;
    }
  }



  static String _formatDate(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日';
  }
}

