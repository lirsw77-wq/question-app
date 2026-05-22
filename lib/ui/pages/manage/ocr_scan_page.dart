import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/database_provider.dart';
import '../../../data/models/parsed_question.dart';
import '../../../data/services/question_parser.dart';
import '../../../data/services/permission_service.dart';
import '../../../data/services/network_service.dart';

class OcrScanPage extends ConsumerStatefulWidget {
  const OcrScanPage({super.key});

  @override
  ConsumerState<OcrScanPage> createState() => _OcrScanPageState();
}

class _OcrScanPageState extends ConsumerState<OcrScanPage> {
  final ImagePicker _picker = ImagePicker();
  final QuestionParser _parser = QuestionParser();

  bool _isProcessing = false;
  String? _imagePath;
  String? _extractedText;
  List<ParsedQuestion> _parsedQuestions = [];
  String? _error;
  bool _quotaExhausted = false;

  @override
  void initState() {
    super.initState();
    _checkQuota();
  }

  Future<void> _checkQuota() async {
    final baiduOcr = ref.read(baiduOcrServiceProvider);
    final hasQuota = await baiduOcr.hasFreeQuota();
    if (!hasQuota && mounted) {
      setState(() {
        _quotaExhausted = true;
      });
    }
  }

  Future<void> _takePhoto() async {
    // 检查网络
    if (!await NetworkService.isNetworkAvailable()) {
      if (mounted) {
        PermissionService.showNetworkError(context);
      }
      return;
    }

    // 检查额度
    if (_quotaExhausted) {
      if (mounted) {
        _showQuotaExhaustedDialog();
      }
      return;
    }

    // 检查相机权限
    if (!mounted) return;
    if (!await PermissionService.requestCameraPermission(context)) {
      return;
    }

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _imagePath = photo.path;
        _extractedText = null;
        _parsedQuestions = [];
        _error = null;
      });
      await _processImage(photo.path);
    }
  }

  Future<void> _pickFromGallery() async {
    // 检查网络
    if (!await NetworkService.isNetworkAvailable()) {
      if (mounted) {
        PermissionService.showNetworkError(context);
      }
      return;
    }

    // 检查额度
    if (_quotaExhausted) {
      if (mounted) {
        _showQuotaExhaustedDialog();
      }
      return;
    }

    // 检查存储权限
    if (!mounted) return;
    if (!await PermissionService.requestStoragePermission(context)) {
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _extractedText = null;
        _parsedQuestions = [];
        _error = null;
      });
      await _processImage(image.path);
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final baiduOcr = ref.read(baiduOcrServiceProvider);

      // 使用百度云OCR识别
      final textLines = await baiduOcr.recognizeText(imagePath);

      if (textLines == null) {
        // 额度已用完
        setState(() {
          _isProcessing = false;
          _quotaExhausted = true;
        });
        if (mounted) {
          _showQuotaExhaustedDialog();
        }
        return;
      }

      if (textLines.isEmpty) {
        setState(() {
          _isProcessing = false;
          _error = '未能识别到文字内容，请确保图片清晰且包含文字';
        });
        return;
      }

      final text = textLines.join('\n');
      setState(() {
        _extractedText = text;
      });

      // 解析题目
      final result = _parser.parse(text);
      setState(() {
        _parsedQuestions = result.questions.where((q) => !q.hasError).toList();
        _isProcessing = false;

        if (_parsedQuestions.isEmpty) {
          _error = '未能识别出题目，请尝试更清晰的图片或手动编辑';
        }
      });

      // 更新剩余次数显示
      _checkQuota();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = '识别失败: $e';
      });
    }
  }

  void _showQuotaExhaustedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('今日免费额度已用完'),
        content: const Text('今日免费识别额度已用完，次日零点自动恢复可用。\n\n全程禁止开启按量付费，绝不会产生任何费用。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _editQuestion(ParsedQuestion question) {
    context.push('/manage/edit-question', extra: question);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照识题'),
        actions: [
          if (_parsedQuestions.isNotEmpty)
            TextButton.icon(
              onPressed: () => _saveAllQuestions(),
              icon: const Icon(Icons.save),
              label: const Text('全部保存'),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(strokeWidth: 6),
            ),
            const SizedBox(height: 24),
            const Text('正在云端识别题目...', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('使用百度云OCR识别', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    if (_quotaExhausted) {
      return _buildQuotaExhaustedState(theme);
    }

    if (_error != null && _imagePath == null) {
      return _buildScanOptions(theme);
    }

    if (_parsedQuestions.isNotEmpty) {
      return _buildResults(theme);
    }

    if (_extractedText != null) {
      return _buildExtractedText(theme);
    }

    return _buildScanOptions(theme);
  }

  Widget _buildQuotaExhaustedState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              '今日免费额度已用完',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '今日免费识别额度已用完\n次日零点自动恢复可用',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '全程禁止开启按量付费\n绝不会产生任何费用',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOptions(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.document_scanner, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            const Text('拍照识别题目', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              '拍摄或选择包含题目的图片\n自动OCR识别题目、选项、答案\n一键录入题库',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _quotaExhausted ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('拍照'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _quotaExhausted ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('从相册选择'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Image preview
        if (_imagePath != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_imagePath!),
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Success message
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '成功识别 ${_parsedQuestions.length} 道题目',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Questions list
        ...List.generate(_parsedQuestions.length, (index) {
          final q = _parsedQuestions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(q.type, style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editQuestion(q),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(q.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                  if (q.options.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...q.options.take(4).map((opt) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(opt, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  if (q.answer.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('答案: ${q.answer}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Action buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _saveAllQuestions(),
            icon: const Icon(Icons.save),
            label: Text('保存全部 ${_parsedQuestions.length} 题'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _imagePath = null;
                _extractedText = null;
                _parsedQuestions = [];
                _error = null;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重新扫描'),
          ),
        ),
      ],
    );
  }

  Widget _buildExtractedText(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_imagePath != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_imagePath!),
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('未能自动识别题目', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('已提取的文字内容如下，您可以手动编辑后保存：'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_extractedText ?? '', style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push('/manage/add'),
            child: const Text('手动添加题目'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _imagePath = null;
                _extractedText = null;
                _parsedQuestions = [];
                _error = null;
              });
            },
            child: const Text('重新扫描'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAllQuestions() async {
    if (_parsedQuestions.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(questionRepositoryProvider);
      final classifier = ref.read(questionClassifierProvider);

      for (final pq in _parsedQuestions) {
        final classification = classifier.classify(pq.content);
        final question = pq.toQuestion(
          module: classification.module,
          chapter: classification.chapter,
          source: 'ocr_scan',
        );
        await repo.insertQuestion(question);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功保存 ${_parsedQuestions.length} 道题目')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = '保存失败: $e';
      });
    }
  }
}
