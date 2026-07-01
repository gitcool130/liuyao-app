/// 图像导入页面
/// 通过拍照或选择图片导入排盘
/// 使用本地OCR识别，无需API Key配置

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/divination_record.dart';
import '../models/image_recognition_result.dart';
import '../providers/divination_provider.dart';
import '../services/ocr_paipan_service.dart';
import '../services/paipan_parser.dart';
import '../services/paipan_corrector.dart';

/// 图像导入页面
class ImageImportScreen extends StatefulWidget {
  const ImageImportScreen({super.key});

  @override
  State<ImageImportScreen> createState() => _ImageImportScreenState();
}

class _ImageImportScreenState extends State<ImageImportScreen> {
  final ImagePicker _picker = ImagePicker();
  final OCRPaipanService _ocrService = OCRPaipanService();
  File? _selectedImage;
  ImageRecognitionResult? _recognitionResult;
  bool _isRecognizing = false;
  String _progressText = '';

  // 编辑控制器
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _benGuaController = TextEditingController();
  final TextEditingController _bianGuaController = TextEditingController();
  final TextEditingController _yearGanZhiController = TextEditingController();
  final TextEditingController _monthGanZhiController = TextEditingController();
  final TextEditingController _dayGanZhiController = TextEditingController();
  final TextEditingController _hourGanZhiController = TextEditingController();

  @override
  void dispose() {
    _ocrService.close();
    _questionController.dispose();
    _genderController.dispose();
    _benGuaController.dispose();
    _bianGuaController.dispose();
    _yearGanZhiController.dispose();
    _monthGanZhiController.dispose();
    _dayGanZhiController.dispose();
    _hourGanZhiController.dispose();
    super.dispose();
  }

  /// 初始化编辑控制器（识别成功后）
  void _initEditControllers(ParsedDivinationData data) {
    _questionController.text = data.question ?? '';
    _genderController.text = data.gender ?? '';
    _benGuaController.text = data.benGuaName ?? '';
    _bianGuaController.text = data.bianGuaName ?? '';
    _yearGanZhiController.text = data.yearGanZhi ?? '';
    _monthGanZhiController.text = data.monthGanZhi ?? '';
    _dayGanZhiController.text = data.dayGanZhi ?? '';
    _hourGanZhiController.text = data.hourGanZhi ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照导入排盘'),
        actions: [
          if (_selectedImage != null)
            TextButton(
              onPressed: _clearImage,
              child: const Text('清除', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 图片选择区域
            _buildImageSelector(),

            const SizedBox(height: 24),

            // 识别按钮
            if (_selectedImage != null && !_isRecognizing)
              ElevatedButton.icon(
                onPressed: _startRecognition,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('开始识别'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

            // 进度指示
            if (_isRecognizing) _buildProgressIndicator(),

            const SizedBox(height: 24),

            // 识别结果
            if (_recognitionResult != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  /// 构建图片选择器
  Widget _buildImageSelector() {
    if (_selectedImage != null) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Image.file(
              _selectedImage!,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _clearImage,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.image, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '选择排盘图片',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '支持拍照或从相册选择',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('拍照'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('相册'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _importFromClipboard,
              icon: const Icon(Icons.content_paste),
              label: const Text('从剪贴板导入'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建进度指示器
  Widget _buildProgressIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_progressText),
          ],
        ),
      ),
    );
  }

  /// 构建结果区域
  Widget _buildResultSection() {
    final result = _recognitionResult!;

    if (!result.success) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    '识别失败',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(result.errorMessage ?? '未知错误'),
            ],
          ),
        ),
      );
    }

    final data = result.data!;
    final missingFields = result.needsConfirmation ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 识别成功提示
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      '识别成功',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '置信度: ${(result.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                if (missingFields.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '以下字段需要确认: ${missingFields.join(', ')}',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 识别结果展示
        _buildResultForm(data),

        const SizedBox(height: 24),

        // 校正排盘按钮
        ElevatedButton.icon(
          onPressed: _correctAndNavigate,
          icon: const Icon(Icons.calculate),
          label: const Text('校正排盘'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  /// 构建结果展示表单（可编辑）
  Widget _buildResultForm(ParsedDivinationData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '识别结果',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '（可编辑修改）',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 基本信息 - 可编辑字段
            _buildEditableRow('性别', _genderController, hint: '男/女'),
            _buildEditableRow('占问', _questionController, maxLines: 3, hint: '占问内容'),

            // 显示不可编辑的识别信息
            _buildInfoRow('公历时间', data.gregorianTime?.toString() ?? '未识别'),
            _buildInfoRow('农历时间', data.lunarTime ?? '未识别'),

            const Divider(),

            // 干支信息 - 四柱放在一行编辑
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('干支四柱', style: TextStyle(color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _yearGanZhiController,
                      decoration: InputDecoration(
                        labelText: '年柱',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _monthGanZhiController,
                      decoration: InputDecoration(
                        labelText: '月柱',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _dayGanZhiController,
                      decoration: InputDecoration(
                        labelText: '日柱',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _hourGanZhiController,
                      decoration: InputDecoration(
                        labelText: '时柱',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // 卦象信息 - 本卦变卦可编辑
            _buildEditableRow('本卦', _benGuaController, hint: '卦名'),
            _buildEditableRow('变卦', _bianGuaController, hint: '卦名（可空）'),

            // 其他不可编辑的信息
            _buildInfoRow('旬空', data.xunKong?.join(', ') ?? '未识别'),

            const Divider(),

            // 六爻详情（将由校正计算生成）
            const Text('六爻详情将在校正后生成', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// 构建可编辑的信息行
  Widget _buildEditableRow(String label, TextEditingController controller, {
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建六爻表格
  Widget _buildYaoTable(ParsedDivinationData data) {
    final liuShen = data.liuShen ?? List.filled(6, '未识别');
    final liuQin = data.liuQin ?? List.filled(6, '未识别');
    final diZhi = data.diZhi ?? List.filled(6, '未识别');

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FixedColumnWidth(60),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
      },
      children: [
        // 表头
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: const [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('爻位', textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('六神', textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('六亲', textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('地支', textAlign: TextAlign.center),
            ),
          ],
        ),
        // 六爻数据（从上往下显示）
        for (int i = 5; i >= 0; i--)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _getYaoName(i + 1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: data.shiPosition == i + 1 ||
                               data.yingPosition == i + 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: data.shiPosition == i + 1
                        ? Colors.red
                        : data.yingPosition == i + 1
                            ? Colors.blue
                            : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(liuShen[i], textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(liuQin[i], textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(diZhi[i], textAlign: TextAlign.center),
              ),
            ],
          ),
      ],
    );
  }

  String _getYaoName(int position) {
    const names = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
    return names[position - 1];
  }

  // ========== 事件处理 ==========

  /// 拍照
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
        _recognitionResult = null;
      });
    }
  }

  /// 从相册选择
  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _recognitionResult = null;
      });
    }
  }

  /// 清除图片
  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _recognitionResult = null;
    });
  }

  /// 从剪贴板导入（剪贴板内容视同OCR识别结果）
  Future<void> _importFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData == null || clipboardData.text == null || clipboardData.text!.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('剪贴板为空，请先复制排盘文字')),
      );
      return;
    }

    setState(() {
      _isRecognizing = true;
      _progressText = '解析剪贴板内容...';
    });

    try {
      final parser = PaipanParser();
      final result = parser.parse(clipboardData.text!, []);

      setState(() {
        _recognitionResult = result;
        _isRecognizing = false;
        if (result.success && result.data != null) {
          _progressText = '✅ 导入成功！请核对下方数据';
          _initEditControllers(result.data!);
        } else {
          _progressText = '❌ 解析失败：${result.errorMessage ?? "无法识别排盘格式"}';
        }
      });
    } catch (e) {
      setState(() {
        _isRecognizing = false;
        _progressText = '❌ 导入失败：$e';
      });
    }
  }

  /// 开始识别（使用本地OCR）
  Future<void> _startRecognition() async {
    if (_selectedImage == null) return;

    setState(() {
      _isRecognizing = true;
      _progressText = '准备OCR识别...';
    });

    // 使用本地OCR服务识别
    final result = await _ocrService.recognizePaipan(
      _selectedImage!.path,
      onProgress: (stage) {
        setState(() {
          _progressText = stage;
        });
      },
    );

    setState(() {
      _isRecognizing = false;
      _recognitionResult = result;
      // 初始化编辑控制器
      if (result.success && result.data != null) {
        _initEditControllers(result.data!);
      }
    });
  }

  /// 校正排盘并导航到结果页面
  Future<void> _correctAndNavigate() async {
    if (_recognitionResult == null || !_recognitionResult!.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先完成OCR识别')),
      );
      return;
    }

    final ocrData = _recognitionResult!.data!;

    // 使用编辑后的数据替换OCR识别的数据
    final editedData = ParsedDivinationData(
      gender: _genderController.text.isNotEmpty ? _genderController.text : ocrData.gender,
      question: _questionController.text.isNotEmpty ? _questionController.text : ocrData.question,
      gregorianTime: ocrData.gregorianTime,
      lunarTime: ocrData.lunarTime,
      yearGanZhi: _yearGanZhiController.text.isNotEmpty ? _yearGanZhiController.text : ocrData.yearGanZhi,
      monthGanZhi: _monthGanZhiController.text.isNotEmpty ? _monthGanZhiController.text : ocrData.monthGanZhi,
      dayGanZhi: _dayGanZhiController.text.isNotEmpty ? _dayGanZhiController.text : ocrData.dayGanZhi,
      hourGanZhi: _hourGanZhiController.text.isNotEmpty ? _hourGanZhiController.text : ocrData.hourGanZhi,
      benGuaName: _benGuaController.text.isNotEmpty ? _benGuaController.text : ocrData.benGuaName,
      bianGuaName: _bianGuaController.text.isNotEmpty ? _bianGuaController.text : ocrData.bianGuaName,
      dongYaoPositions: ocrData.dongYaoPositions,
      xunKong: ocrData.xunKong,
    );

    // 验证必要字段
    if (editedData.benGuaName == null || editedData.benGuaName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写本卦卦名')),
      );
      return;
    }

    if (editedData.dayGanZhi == null || editedData.dayGanZhi!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写日柱干支')),
      );
      return;
    }

    // 调用校正服务生成完整排盘
    DivinationRecord? record = PaipanCorrector.correctAndGenerate(editedData);

    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('校正计算失败')),
      );
      return;
    }

    // 设置到Provider并导航到结果页面，清除导航栈让后退回到首页
    final provider = Provider.of<DivinationProvider>(context, listen: false);
    provider.setRecord(record);

    Navigator.pushNamedAndRemoveUntil(context, '/result', (route) => route.isFirst);
  }
}
