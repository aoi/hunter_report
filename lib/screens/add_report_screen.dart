import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/hunt_report.dart';
import '../providers/hunt_report_provider.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({super.key});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  
  DateTime _selectedDateTime = DateTime.now();
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  
  // 獲物のリスト
  List<GameItemData> _gameItems = [];
  
  // 獲物の種類の選択肢
  static const List<String> _animalTypes = [
    'イノシシ',
    'シカ(オス)',
    'シカ(メス)',
    'アライグマ(オス)',
    'アライグマ(メス)',
    'その他',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // 最初の獲物を追加
    _addGameItem();
  }

  @override
  void dispose() {
    _locationController.dispose();
    for (var item in _gameItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final hasPermission = await LocationService.requestLocationPermission();
      if (hasPermission) {
        final position = await LocationService.getCurrentLocation();
        if (position != null) {
          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
          });
          
          // 住所を取得して場所フィールドに設定
          final address = await LocationService.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (address != null) {
            _locationController.text = address;
          }
        }
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addGameItem() {
    setState(() {
      _gameItems.add(GameItemData());
    });
  }

  void _removeGameItem(int index) {
    setState(() {
      _gameItems[index].dispose();
      _gameItems.removeAt(index);
    });
  }

  Future<void> _addImage(int gameItemIndex) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () async {
                Navigator.pop(context);
                await _takePicture(gameItemIndex);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () async {
                Navigator.pop(context);
                await _pickFromGallery(gameItemIndex);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture(int gameItemIndex) async {
    try {
      final hasPermission = await CameraService.requestCameraPermission();
      if (hasPermission) {
        final imagePath = await CameraService.pickImageFromCamera();
        if (imagePath != null) {
          final savedPath = await CameraService.saveImageToAppDirectory(imagePath);
          setState(() {
            _gameItems[gameItemIndex].imagePaths.add(savedPath);
          });
        }
      } else {
        _showPermissionDialog('カメラの権限が必要です');
      }
    } catch (e) {
      _showErrorDialog('写真の撮影に失敗しました');
    }
  }

  Future<void> _pickFromGallery(int gameItemIndex) async {
    try {
      final hasPermission = await CameraService.requestStoragePermission();
      if (hasPermission) {
        final imagePath = await CameraService.pickImageFromGallery();
        if (imagePath != null) {
          final savedPath = await CameraService.saveImageToAppDirectory(imagePath);
          setState(() {
            _gameItems[gameItemIndex].imagePaths.add(savedPath);
          });
        }
      } else {
        _showPermissionDialog('ストレージの権限が必要です');
      }
    } catch (e) {
      _showErrorDialog('画像の選択に失敗しました');
    }
  }

  void _removeImage(int gameItemIndex, int imageIndex) {
    setState(() {
      _gameItems[gameItemIndex].imagePaths.removeAt(imageIndex);
    });
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;
    
    // 少なくとも1つの獲物が必要
    if (_gameItems.isEmpty) {
      _showErrorDialog('少なくとも1つの獲物を登録してください');
      return false;
    }
    
    // 各獲物のバリデーション
    for (int i = 0; i < _gameItems.length; i++) {
      final item = _gameItems[i];
      
      // その他選択時の自由入力チェック
      if (item.selectedAnimalType == 'その他' && 
          (item.customAnimalTypeController.text.trim().isEmpty)) {
        _showErrorDialog('獲物${i + 1}の獲物の種類を入力してください');
        return false;
      }
      
      // 捕獲頭数チェック
      final gunCount = int.tryParse(item.gunCountController.text) ?? 0;
      final snareCount = int.tryParse(item.snareCountController.text) ?? 0;
      final boxTrapCount = int.tryParse(item.boxTrapCountController.text) ?? 0;
      
      if (gunCount + snareCount + boxTrapCount == 0) {
        _showErrorDialog('獲物${i + 1}の捕獲頭数を入力してください');
        return false;
      }
    }
    
    return true;
  }

  Future<void> _saveReport() async {
    if (!_validateForm()) return;

    // GameItemDataをGameItemに変換
    final gameItems = _gameItems.map((item) => GameItem(
      animalType: item.currentAnimalType,
      gunCount: int.tryParse(item.gunCountController.text) ?? 0,
      snareCount: int.tryParse(item.snareCountController.text) ?? 0,
      boxTrapCount: int.tryParse(item.boxTrapCountController.text) ?? 0,
      imagePaths: List.from(item.imagePaths),
    )).toList();

    final report = HuntReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      location: _locationController.text.trim(),
      dateTime: _selectedDateTime,
      gameItems: gameItems,
      latitude: _latitude,
      longitude: _longitude,
    );

    try {
      await context.read<HuntReportProvider>().addReport(report);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('報告を保存しました')),
        );
      }
    } catch (e) {
      _showErrorDialog('報告の保存に失敗しました');
    }
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('権限が必要'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規報告'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 場所
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: '捕獲場所 *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _getCurrentLocation,
                      ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '捕獲場所を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 日時
            InkWell(
              onTap: _selectDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '捕獲日時 *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                ),
                child: Text(
                  DateFormat('yyyy年MM月dd日 HH:mm').format(_selectedDateTime),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 獲物セクション
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '獲物情報',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addGameItem,
                          icon: const Icon(Icons.add),
                          label: const Text('獲物を追加'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // 獲物のリスト
                    ...List.generate(_gameItems.length, (index) {
                      return _buildGameItemCard(index);
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  '報告を保存',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameItemCard(int index) {
    final gameItem = _gameItems[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '獲物 ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_gameItems.length > 1)
                  IconButton(
                    onPressed: () => _removeGameItem(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: '削除',
                  ),
              ],
            ),
            const SizedBox(height: 16),

                         // 獲物の種類
             DropdownButtonFormField<String>(
               value: gameItem.selectedAnimalType,
               decoration: const InputDecoration(
                 labelText: '獲物の種類 *',
                 border: OutlineInputBorder(),
                 prefixIcon: Icon(Icons.pets),
               ),
               items: _animalTypes.map((String animalType) {
                 return DropdownMenuItem<String>(
                   value: animalType,
                   child: Text(animalType),
                 );
               }).toList(),
               onChanged: (String? newValue) {
                 if (newValue != null) {
                   setState(() {
                     gameItem.selectedAnimalType = newValue;
                   });
                 }
               },
               validator: (value) {
                 if (value == null || value.isEmpty) {
                   return '獲物の種類を選択してください';
                 }
                 return null;
               },
             ),
             
             // その他選択時の自由入力フィールド
             if (gameItem.selectedAnimalType == 'その他') ...[
               const SizedBox(height: 16),
               TextFormField(
                 controller: gameItem.customAnimalTypeController,
                 decoration: const InputDecoration(
                   labelText: '獲物の種類（自由入力）*',
                   border: OutlineInputBorder(),
                   prefixIcon: Icon(Icons.edit),
                 ),
                 validator: (value) {
                   if (gameItem.selectedAnimalType == 'その他' && 
                       (value == null || value.trim().isEmpty)) {
                     return '獲物の種類を入力してください';
                   }
                   return null;
                 },
               ),
             ],
             const SizedBox(height: 16),

             // 捕獲頭数
             const Text(
               '捕獲頭数',
               style: TextStyle(
                 fontSize: 16,
                 fontWeight: FontWeight.bold,
               ),
             ),
             const SizedBox(height: 8),
             TextFormField(
              controller: gameItem.gunCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '銃器',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports),
              ),
              validator: (value) {
                final count = int.tryParse(value ?? '0') ?? 0;
                if (count < 0) {
                  return '0以上を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: gameItem.snareCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'くくりわな',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports),
              ),
              validator: (value) {
                final count = int.tryParse(value ?? '0') ?? 0;
                if (count < 0) {
                  return '0以上を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
              TextFormField(
              controller: gameItem.boxTrapCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '箱わな',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports),
              ),
              validator: (value) {
                final count = int.tryParse(value ?? '0') ?? 0;
                if (count < 0) {
                  return '0以上を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 写真セクション
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '写真 *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _addImage(index),
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('追加'),
                    ),
                  ],
                ),
                                 if (gameItem.imagePaths.isEmpty)
                   const Padding(
                     padding: EdgeInsets.all(32),
                     child: Center(
                       child: Column(
                         children: [
                           Icon(
                             Icons.camera_alt_outlined,
                             size: 48,
                             color: Colors.grey,
                           ),
                           SizedBox(height: 8),
                           Text(
                             '写真を追加してください',
                             style: TextStyle(color: Colors.grey),
                           ),
                         ],
                       ),
                     ),
                   )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: gameItem.imagePaths.length,
                    itemBuilder: (context, imageIndex) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(gameItem.imagePaths[imageIndex]),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index, imageIndex),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 獲物データを管理するためのヘルパークラス
class GameItemData {
  final TextEditingController animalTypeController = TextEditingController();
  final TextEditingController gunCountController = TextEditingController();
  final TextEditingController snareCountController = TextEditingController();
  final TextEditingController boxTrapCountController = TextEditingController();
  final List<String> imagePaths = [];
  
  // 獲物の種類の選択状態
  String selectedAnimalType = 'イノシシ';
  final TextEditingController customAnimalTypeController = TextEditingController();

  void dispose() {
    animalTypeController.dispose();
    gunCountController.dispose();
    snareCountController.dispose();
    boxTrapCountController.dispose();
    customAnimalTypeController.dispose();
  }
  
  // 現在の獲物の種類を取得
  String get currentAnimalType {
    if (selectedAnimalType == 'その他') {
      return customAnimalTypeController.text.trim();
    }
    return selectedAnimalType;
  }
}

