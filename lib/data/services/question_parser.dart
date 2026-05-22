import '../models/parsed_question.dart';

class ParseResult {
  final List<ParsedQuestion> questions;
  final String? examSource;
  ParseResult({required this.questions, this.examSource});
}

class QuestionParser {
  static final RegExp _questionNumberPattern = RegExp(
    r'^(\d{1,3})[.、．]\s*|^（(\d{1,3})）\s*|^第(\d{1,3})题[.、．]?\s*',
  );

  static final RegExp _optionPattern = RegExp(
    r'^([A-D])[.、．:：]\s*(.+)|^（([A-D])）\s*(.+)',
  );

  static final RegExp _answerSectionPattern = RegExp(
    r'(参考答案|答案与解析|答案解析|参考答案及解析|答案汇总|正确答案)',
    caseSensitive: false,
  );

  static final RegExp _explanationPattern = RegExp(
    r'^(解析|详解|解题思路|答案解析|参考解析)[：:]\s*',
    caseSensitive: false,
  );

  static final RegExp _yearPattern = RegExp(r'(20[12]\d)');
  static final RegExp _regionPattern = RegExp(
    r'(河南省直|省直|驻马店|洛阳|南阳|郑州|开封|安阳|新乡|焦作|濮阳|许昌|漯河|三门峡|商丘|信阳|周口|平顶山|鹤壁|济源|河南)',
  );

  static final RegExp _trueFalsePattern = RegExp(r'^(正确|错误|对|错|√|×|T|F|是|否)$', caseSensitive: false);
  static final RegExp _fillBlankPattern = RegExp(r'_{2,}|（\s*）|\(\s*\)');

  ParseResult parse(String fullText) {
    final source = _extractSource(fullText);
    final questions = _parseQuestions(fullText);
    return ParseResult(questions: questions, examSource: source);
  }

  String? _extractSource(String text) {
    final headerChunk = text.substring(0, text.length.clamp(0, 1000));

    String? year;
    String? region;

    final yearMatch = _yearPattern.firstMatch(headerChunk);
    if (yearMatch != null) year = '${yearMatch.group(1)}年';

    final regionMatch = _regionPattern.firstMatch(headerChunk);
    if (regionMatch != null) region = '${regionMatch.group(1)}事业单位真题';

    if (year == null && region == null) {
      final fullYearMatch = _yearPattern.firstMatch(text);
      if (fullYearMatch != null) year = '${fullYearMatch.group(1)}年';
    }

    if (year != null || region != null) {
      return [year, region].where((s) => s != null).join(' ');
    }
    return null;
  }

  List<ParsedQuestion> _parseQuestions(String text) {
    final questions = <ParsedQuestion>[];
    final blocks = _splitIntoQuestionBlocks(text);

    for (final block in blocks) {
      final parsed = _parseSingleQuestion(block);
      if (parsed != null) questions.add(parsed);
    }

    return questions;
  }

  List<String> _splitIntoQuestionBlocks(String text) {
    final lines = text.split('\n');
    final blocks = <String>[];
    final currentBlock = StringBuffer();
    bool inAnswerSection = false;
    final answerBlocks = <String>[];
    final answerBuffer = StringBuffer();

    for (final line in lines) {
      if (_answerSectionPattern.hasMatch(line)) {
        inAnswerSection = true;
        if (currentBlock.isNotEmpty) {
          blocks.add(currentBlock.toString().trim());
          currentBlock.clear();
        }
        continue;
      }

      if (inAnswerSection) {
        answerBuffer.writeln(line);
        continue;
      }

      final questionMatch = _questionNumberPattern.firstMatch(line);
      if (questionMatch != null) {
        if (currentBlock.isNotEmpty) {
          blocks.add(currentBlock.toString().trim());
          currentBlock.clear();
        }
      }
      currentBlock.writeln(line);
    }

    if (currentBlock.isNotEmpty) {
      blocks.add(currentBlock.toString().trim());
    }

    if (answerBuffer.isNotEmpty) {
      answerBlocks.add(answerBuffer.toString().trim());
    }

    final parsedBlocks = <String>[];
    for (final block in blocks) {
      if (block.trim().isNotEmpty) parsedBlocks.add(block);
    }

    if (answerBlocks.isNotEmpty) {
      _mergeAnswers(parsedBlocks, answerBlocks.first);
    }

    return parsedBlocks;
  }

  void _mergeAnswers(List<String> blocks, String answerText) {
    final answerLines = answerText.split('\n');
    final answerMap = <int, String>{};
    final explanationMap = <int, String>{};

    int? currentQNum;
    bool isExplanation = false;
    final explanationBuffer = StringBuffer();

    for (final line in answerLines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final numMatch = RegExp(r'^(\d{1,3})[.、．:：\s]').firstMatch(trimmed);
      if (numMatch != null) {
        if (currentQNum != null && explanationBuffer.isNotEmpty) {
          explanationMap[currentQNum] = explanationBuffer.toString().trim();
          explanationBuffer.clear();
        }
        currentQNum = int.tryParse(numMatch.group(1)!);
        isExplanation = false;

        final afterNum = trimmed.substring(numMatch.group(0)!.length).trim();
        if (afterNum.isNotEmpty) {
          answerMap[currentQNum!] = afterNum;
        }
        continue;
      }

      if (_explanationPattern.hasMatch(trimmed)) {
        isExplanation = true;
        final afterLabel = trimmed.replaceFirst(_explanationPattern, '').trim();
        if (afterLabel.isNotEmpty) explanationBuffer.writeln(afterLabel);
        continue;
      }

      if (currentQNum != null) {
        if (isExplanation) {
          explanationBuffer.writeln(trimmed);
        } else {
          answerMap[currentQNum] = (answerMap[currentQNum] ?? '') + trimmed;
        }
      }
    }

    if (currentQNum != null && explanationBuffer.isNotEmpty) {
      explanationMap[currentQNum] = explanationBuffer.toString().trim();
    }

    for (int i = 0; i < blocks.length; i++) {
      final numMatch = _questionNumberPattern.firstMatch(blocks[i]);
      if (numMatch != null) {
        final qNum = int.tryParse(numMatch.group(1) ?? numMatch.group(2) ?? numMatch.group(3) ?? '');
        if (qNum != null && (answerMap.containsKey(qNum) || explanationMap.containsKey(qNum))) {
          final answer = answerMap[qNum] ?? '';
          final explanation = explanationMap[qNum] ?? '';
          if (answer.isNotEmpty || explanation.isNotEmpty) {
            blocks[i] = '${blocks[i]}\n【答案】$answer\n【解析】$explanation';
          }
        }
      }
    }
  }

  ParsedQuestion? _parseSingleQuestion(String block) {
    final lines = block.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return null;

    final firstLine = lines.first.trim();
    final qMatch = _questionNumberPattern.firstMatch(firstLine);
    if (qMatch == null) return null;

    String content = '';
    final options = <String>[];
    String answer = '';
    String explanation = '';

    int contentStart = 0;
    if (qMatch.group(0) != null) {
      contentStart = qMatch.group(0)!.length;
    }
    content = firstLine.substring(contentStart).trim();

    String currentOptionLabel = '';
    final currentOptionContent = StringBuffer();
    bool foundAnswer = false;
    bool foundExplanation = false;

    void flushOption() {
      if (currentOptionLabel.isNotEmpty) {
        options.add('$currentOptionLabel. ${currentOptionContent.toString().trim()}');
        currentOptionLabel = '';
        currentOptionContent.clear();
      }
    }

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('【答案】') || line.startsWith('[答案]')) {
        flushOption();
        answer = line.replaceFirst(RegExp(r'^【答案】|^\[答案\]'), '').trim();
        foundAnswer = true;
        continue;
      }
      if (line.startsWith('【解析】') || line.startsWith('[解析]')) {
        flushOption();
        explanation = line.replaceFirst(RegExp(r'^【解析】|^\[解析\]'), '').trim();
        foundExplanation = true;
        continue;
      }

      if (foundAnswer && !foundExplanation) {
        answer += line;
        continue;
      }
      if (foundExplanation) {
        explanation += line;
        continue;
      }

      final optMatch = _optionPattern.firstMatch(line);
      if (optMatch != null) {
        flushOption();
        currentOptionLabel = optMatch.group(1) ?? optMatch.group(3) ?? '';
        final optContent = optMatch.group(2) ?? optMatch.group(4) ?? '';
        currentOptionContent.write(optContent);
        continue;
      }

      if (currentOptionLabel.isNotEmpty) {
        currentOptionContent.write(line);
        continue;
      }

      if (!foundAnswer) {
        content += line;
      }
    }

    flushOption();

    content = content.trim();
    answer = answer.trim();
    explanation = explanation.trim();

    if (content.isEmpty) return null;

    final type = _detectQuestionType(content, options, answer);

    return ParsedQuestion(
      content: content,
      type: type,
      options: options,
      answer: answer,
      explanation: explanation,
      hasError: _hasParseError(content, options, answer, type),
      errorReason: _getErrorReason(content, options, answer, type),
    );
  }

  String _detectQuestionType(String content, List<String> options, String answer) {
    if (_fillBlankPattern.hasMatch(content)) return '填空题';

    if (options.isEmpty && answer.isNotEmpty) {
      if (_trueFalsePattern.hasMatch(answer)) return '判断题';
    }

    if (options.isEmpty && _trueFalsePattern.hasMatch(content.split(RegExp(r'[?？。]')).first.trim())) {
      return '判断题';
    }

    if (options.length >= 2) {
      if (answer.length > 2 && answer.contains(RegExp(r'[A-D]'))) {
        final letterMatches = RegExp(r'[A-D]').allMatches(answer.toUpperCase());
        if (letterMatches.length >= 2) return '多选题';
      }
      if (answer.length == 1 && RegExp(r'^[A-D]$').hasMatch(answer.toUpperCase())) {
        return '单选题';
      }
      return '单选题';
    }

    if (content.length > 100 || RegExp(r'(分析|论述|谈谈|如何|为什么)').hasMatch(content)) {
      return '主观题';
    }

    return '单选题';
  }

  bool _hasParseError(String content, List<String> options, String answer, String type) {
    if (content.length < 5) return true;
    if (type == '单选题' && options.length < 2) return true;
    if (type == '多选题' && options.length < 3) return true;
    return false;
  }

  String? _getErrorReason(String content, List<String> options, String answer, String type) {
    if (content.length < 5) return '题干内容过短，可能解析有误';
    if (type == '单选题' && options.length < 2) return '单选题选项不足2个';
    if (type == '多选题' && options.length < 3) return '多选题选项不足3个';
    return null;
  }
}
