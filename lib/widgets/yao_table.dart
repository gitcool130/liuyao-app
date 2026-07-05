import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/yao_line.dart';
import '../models/app_settings.dart';
import '../algorithms/liuqin_config.dart';
import '../algorithms/constants.dart';
import '../algorithms/dizhi_quantification.dart';
import '../providers/settings_provider.dart';

/// 六爻详情表格组件
/// 从上爻到初爻显示六神、伏神、六亲、地支、世应、本卦、变卦
///
/// 注意：App全局已设置 textScaler: TextScaler.linear(0.85)，忽略系统字体缩放
/// 此组件使用固定宽度 + FittedBox 防止换行
class YaoTable extends StatelessWidget {
  final List<YaoLine> yaoLines;
  final String gongWuXing; // 卦宫五行，用于计算伏神六亲
  final String? gongName;  // 卦宫名（如"乾宫"）
  final String benGuaName; // 本卦名称
  final String? bianGuaName; // 变卦名称（有动爻时）
  final String? benGuaLabel; // 本卦标签（六冲/六合）
  final String? bianGuaLabel; // 变卦标签（六冲/六合）
  final bool hasDongYao; // 是否有动爻

  /// 是否显示数字量化
  final bool showQuantification;

  /// 量化值列表（从初爻到上爻，与yaoLines顺序对应）
  final List<QuantificationResult>? quantificationResults;

  const YaoTable({
    super.key,
    required this.yaoLines,
    required this.gongWuXing,
    required this.benGuaName,
    this.gongName,
    this.bianGuaName,
    this.benGuaLabel,
    this.bianGuaLabel,
    this.hasDongYao = false,
    this.showQuantification = false,
    this.quantificationResults,
  });

  @override
  Widget build(BuildContext context) {
    // 检测屏幕方向，横屏时增加间距
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    // 本卦爻象栏宽度（收窄）
    final benGuaWidth = isLandscape ? 80.0 : 60.0;

    // 从上爻(位置6)到初爻(位置1)排序
    final sortedLines = yaoLines.toList()
      ..sort((a, b) => b.position.compareTo(a.position));

    // 获取自定义颜色设置
    final settings = context.watch<SettingsProvider>().settings;
    final staticColor = settings.staticYaoColor;
    final dongColor = settings.dongYaoColor;
    final yaoFontSize = settings.yaoFontSize;
    final showColoredWuXing = settings.showColoredWuXing;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 表头（包含卦名）
            _buildHeader(benGuaWidth),

            // 爻行
            for (var yao in sortedLines)
              _buildYaoRow(yao, benGuaWidth, staticColor, dongColor, yaoFontSize, showColoredWuXing),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double benGuaWidth) {
    // 卦名合并宽度：六亲(36) + 干支(44/58) + 世应(24) + 本卦爻象(benGuaWidth)
    final guaNameHeaderWidth = 36 + (showQuantification ? 58 : 44) + 24 + benGuaWidth;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      child: Row(
        children: [
          const _HeaderCell('六神', width: 36),
          const _HeaderCell('伏', width: 36),
          // 本卦名称（占六亲+支+世应+爻象的合并空间，左对齐显示）
          SizedBox(
            width: guaNameHeaderWidth,
            child: Text(
              '${gongName != null ? '$gongName：' : ''}${benGuaLabel != null && benGuaLabel!.isNotEmpty ? '$benGuaName($benGuaLabel)' : benGuaName}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 变卦名称（占变卦列，左对齐显示）
          if (hasDongYao && bianGuaName != null)
            SizedBox(
              width: 130,
              child: Text(
                bianGuaLabel != null && bianGuaLabel!.isNotEmpty ? '$bianGuaName($bianGuaLabel)' : bianGuaName!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildYaoRow(YaoLine yao, double benGuaWidth, Color staticColor, Color dongColor, double yaoFontSize, bool showColoredWuXing) {
    final isDong = yao.isDong;
    final isShi = yao.isShi == true;
    final isYing = yao.isYing == true;
    final isXunKong = yao.isXunKong == true;

    // 六亲显示完整两个字（如"官鬼")
    final liuQinDisplay = yao.liuQin ?? '';

    // 地支+五行（紧凑显示，不留空），含纳甲天干：天干+地支+五行
    final ganZhiDisplay = yao.ganZhi ?? '';
    final tianGanDisplay = yao.tianGan ?? '';
    final zhiWuXing = '$tianGanDisplay$ganZhiDisplay${yao.wuXing ?? ''}';

    // 获取量化值（按位置索引匹配，避免重复地支匹配错误）
    QuantificationResult? quantResult;
    if (showQuantification && quantificationResults != null && quantificationResults!.length >= yao.position) {
      // position 1-6 对应 quantificationResults 索引 0-5
      quantResult = quantificationResults![yao.position - 1];
    }

    // 伏神：显示六亲首字+伏神地支（如伏神是"酉"，六亲是"官鬼"，显示为"官酉")
    String fuShenDisplay = '';
    if (yao.fuShen != null && yao.fuShen!.isNotEmpty) {
      // 根据伏神地支和卦宫五行计算伏神六亲
      String fuShenLiuQin = LiuQinConfig.getLiuQin(gongWuXing, diZhiWuXing[yao.fuShen] ?? '');
      fuShenDisplay = fuShenLiuQin.isNotEmpty ? fuShenLiuQin[0] : ''; // 六亲首字
      fuShenDisplay += yao.fuShen!; // 加上伏神地支
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
      decoration: BoxDecoration(
        color: isDong ? Colors.orange.shade50 : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 六神（完整两个字显示）
          _YaoCell(
            yao.liuShen ?? '',
            width: 36,
          ),

          // 伏神（六亲首字+地支）
          _YaoCell(
            fuShenDisplay,
            width: 36,
            color: yao.fuShen != null ? Colors.blue.shade700 : null,
          ),

          _YaoCell(liuQinDisplay, width: 36),

          // 地支+五行（支持量化显示）
          _buildZhiCell(zhiWuXing, isXunKong, quantResult, showColoredWuXing, tianGan: yao.tianGan),

          // 世应
          _YaoCell(
            isShi ? '世' : (isYing ? '应' : ''),
            width: 24,
            color: isShi ? Colors.red.shade700 : (isYing ? Colors.blue.shade700 : null),
            fontWeight: FontWeight.bold,
          ),

          // 本卦爻象 - 横屏时宽度加大
          _YaoSymbolCell(yao, width: benGuaWidth, staticColor: staticColor, dongColor: dongColor, fontSize: yaoFontSize),

          // 变卦爻象+六亲+地支五行（有动爻时才显示）
          if (hasDongYao)
            _BianYaoCell(yao, width: 130, staticColor: staticColor, dongColor: dongColor, fontSize: yaoFontSize),
        ],
      ),
    );
  }

  /// 构建地支单元格（支持量化显示）
  /// zhiWuXing 格式：天干+地支+五行，如“甲寅木”
  /// 开启五行彩色显示时，天干按天干五行着色，地支+五行按地支五行着色
  Widget _buildZhiCell(String zhiWuXing, bool isXunKong, QuantificationResult? quant, bool showColoredWuXing, {String? tianGan}) {
    // 量化值颜色和文本
    Color? quantColor;
    String? quantText;

    if (showQuantification && quant != null) {
      if (quant.isRiChong) {
        quantColor = Colors.orange;
        quantText = '*';
      } else {
        final value = quant.totalValue ?? 0;
        if (value > 0) {
          quantColor = Colors.red;
        } else if (value < 0) {
          quantColor = Colors.blue;
        } else {
          quantColor = Colors.grey;
        }
        quantText = value.toStringAsFixed(1).replaceAll('.0', '');
      }
    }

    final zhiWidget = SizedBox(
      width: showQuantification ? 58 : 44,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            showColoredWuXing && !isXunKong
                ? _buildColoredZhiText(zhiWuXing, isXunKong, tianGan)
                : Text(
                    zhiWuXing,
                    style: TextStyle(
                      fontSize: 14,
                      color: isXunKong ? Colors.grey : Colors.black87,
                      fontStyle: isXunKong ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 1,
                  ),
            if (showQuantification && quantText != null)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  quantText,
                  style: TextStyle(
                    fontSize: 10,
                    color: quantColor,
                    fontWeight: quant?.isRiChong == true ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                ),
              ),
          ],
        ),
      ),
    );

    return zhiWidget;
  }

  /// 构建彩色五行纳甲文本
  /// 字符串为“天干+地支+五行”，如“甲寅木”
  /// 天干按天干五行着色，地支和五行按地支五行着色
  Widget _buildColoredZhiText(String zhiWuXing, bool isXunKong, String? tianGan) {
    // 末尾字符为地支五行
    final wuXing = zhiWuXing.substring(zhiWuXing.length - 1);
    // 地支部分 = 去掉末尾五行后的剩余，再去掉前面的天干
    final diZhiPart = zhiWuXing.substring(0, zhiWuXing.length - 1);
    final gan = (tianGan != null && tianGan.isNotEmpty && diZhiPart.startsWith(tianGan))
        ? tianGan
        : '';
    final diZhi = gan.isNotEmpty ? diZhiPart.substring(gan.length) : diZhiPart;

    final ganColor = gan.isNotEmpty ? AppSettings.wuXingColors[tianGanWuXing[gan]] : null;
    final zhiColor = AppSettings.wuXingColors[diZhiWuXing[diZhi]];

    return RichText(
      maxLines: 1,
      text: TextSpan(
        children: [
          if (gan.isNotEmpty)
            TextSpan(
              text: gan,
              style: TextStyle(
                fontSize: 14,
                color: isXunKong ? Colors.grey : (ganColor ?? Colors.black87),
                fontWeight: FontWeight.bold,
                fontStyle: isXunKong ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          TextSpan(
            text: diZhi,
            style: TextStyle(
              fontSize: 14,
              color: isXunKong ? Colors.grey : (zhiColor ?? Colors.black87),
              fontWeight: FontWeight.bold,
              fontStyle: isXunKong ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          TextSpan(
            text: wuXing,
            style: TextStyle(
              fontSize: 14,
              color: isXunKong ? Colors.grey : (zhiColor ?? Colors.black87),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 表头单元格
class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final bool alignLeft;
  final bool bold;

  const _HeaderCell(this.text, {required this.width, this.alignLeft = false, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: bold ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: bold ? const Color(0xFF8B4513) : const Color(0xFF5D4037),
        ),
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// 爻行单元格
class _YaoCell extends StatelessWidget {
  final String text;
  final double width;
  final Color? color;
  final FontWeight fontWeight;

  const _YaoCell(
    this.text, {
    required this.width,
    this.color,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: color ?? Colors.black87,
            fontWeight: fontWeight,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }
}

/// 爻象符号单元格（使用FittedBox防止换行）
class _YaoSymbolCell extends StatelessWidget {
  final YaoLine yao;
  final double width;
  final Color staticColor;
  final Color dongColor;
  final double fontSize;

  const _YaoSymbolCell(this.yao, {required this.width, required this.staticColor, required this.dongColor, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final symbol = yao.yaoTypeSymbol;
    final isDong = yao.isDong;

    // 动爻标记符号○✕用更大字号渲染
    final double symbolFontSize = isDong ? fontSize * 1.2 : fontSize;

    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      child: RichText(
          text: TextSpan(
            children: [
              if (isDong && symbol.contains('◯'))
                TextSpan(
                  text: '▅▅▅▅▅',
                  style: TextStyle(fontSize: fontSize, color: dongColor, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                )
              else if (isDong && symbol.contains('✕'))
                TextSpan(
                  text: '▅▅ ▅▅',
                  style: TextStyle(fontSize: fontSize, color: dongColor, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                )
              else
                TextSpan(
                  text: symbol,
                  style: TextStyle(fontSize: fontSize, color: isDong ? dongColor : staticColor, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              if (isDong)
                TextSpan(
                  text: symbol.contains('◯') ? '◯' : '✕',
                  style: TextStyle(fontSize: symbolFontSize, color: dongColor, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
            ],
          ),
          maxLines: 1,
        ),
    );
  }
}

/// 变卦爻象单元格（显示爻象+六亲+地支五行）
/// 使用FittedBox防止换行
class _BianYaoCell extends StatelessWidget {
  final YaoLine yao;
  final double width;
  final Color staticColor;
  final Color dongColor;
  final double fontSize;

  const _BianYaoCell(this.yao, {required this.width, required this.staticColor, required this.dongColor, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    // 检查是否有变卦信息
    if (yao.bianYaoType == null && yao.bianGanZhi == null) {
      return SizedBox(width: width, child: const SizedBox.shrink());
    }

    // 变卦爻象符号
    String symbol;
    if (yao.bianYaoType == YaoType.laoYang) {
      symbol = '▅▅▅▅▅◯';
    } else if (yao.bianYaoType == YaoType.laoYin) {
      symbol = '▅▅ ▅▅✕';
    } else if (yao.bianYaoType == YaoType.shaoYang) {
      symbol = '▅▅▅▅▅';
    } else if (yao.bianYaoType == YaoType.shaoYin) {
      symbol = '▅▅ ▅▅';
    } else {
      symbol = '';
    }

    // 变卦六亲+纳甲天干+地支五行（如"兄甲寅木"）
    String bianInfo = '';
    if (yao.bianLiuQin != null && yao.bianLiuQin!.isNotEmpty) {
      bianInfo = yao.bianLiuQin!;
      if (yao.bianTianGan != null) {
        bianInfo += yao.bianTianGan!;
      }
      if (yao.bianGanZhi != null) {
        bianInfo += yao.bianGanZhi!;
        if (yao.bianWuXing != null) {
          bianInfo += yao.bianWuXing!;
        }
      }
    } else if (yao.bianTianGan != null || yao.bianGanZhi != null) {
      bianInfo = (yao.bianTianGan ?? '') + (yao.bianGanZhi ?? '');
      if (yao.bianWuXing != null) {
        bianInfo += yao.bianWuXing!;
      }
    }

    final symbolColor = yao.isDong ? dongColor : staticColor;

    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            children: [
              if (bianInfo.isNotEmpty)
                TextSpan(
                  text: bianInfo,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              TextSpan(
                text: symbol,
                style: TextStyle(
                  fontSize: fontSize,
                  color: symbolColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}