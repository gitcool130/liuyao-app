import 'dart:math';
import 'package:flutter/material.dart';
import '../algorithms/dizhi_relations.dart';
import '../models/app_settings.dart';

/// 关系连线容器组件
/// 使用Stack包裹InfoCard+ShenshaCard+YaoTable，让连线可以跨越整个区域
/// 通过GlobalKey动态获取组件实际尺寸
class YaoRelationsOverlay extends StatefulWidget {
  /// 关系列表
  final List<YaoRelation> relations;

  /// 信息卡片组件（包含月建日辰）
  final Widget infoCard;

  /// 神煞卡片组件
  final Widget shenshaCard;

  /// 子组件（YaoTable）
  final Widget child;

  /// 月建地支
  final String monthZhi;

  /// 日辰地支
  final String dayZhi;

  /// 是否显示量化（影响支列宽度）
  final bool showQuantification;

  /// 自定义颜色设置
  final AppSettings settings;

  const YaoRelationsOverlay({
    super.key,
    required this.relations,
    required this.infoCard,
    required this.shenshaCard,
    required this.child,
    required this.monthZhi,
    required this.dayZhi,
    this.showQuantification = false,
    required this.settings,
  });

  @override
  State<YaoRelationsOverlay> createState() => _YaoRelationsOverlayState();
}

class _YaoRelationsOverlayState extends State<YaoRelationsOverlay> {
  final GlobalKey _infoCardKey = GlobalKey();
  final GlobalKey _shenshaCardKey = GlobalKey();
  final GlobalKey _yaoTableKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // 获取各组件实际高度
    final infoCardH = _getHeight(_infoCardKey);
    final shenshaCardH = _getHeight(_shenshaCardKey);
    final yaoTableH = _getHeight(_yaoTableKey);

    // 计算YaoTable内部的实际行高
    // YaoTable结构：Card(4) + Header + 6行
    // 实际行高 = (总高度 - cardPadding上下 - header高度) / 6
    double actualRowHeight = 0;
    double actualHeaderHeight = 0;
    if (yaoTableH > 0) {
      // Card padding上下共8px，header约20-25px
      // 简化计算：假设cardPadding=8, header约占总高度的15%
      // 更精确：rowHeight = (yaoTableH - 8 - estimatedHeader) / 6
      // 但我们需要更可靠的方法

      // 方案：使用测量值和估算结合
      // rowHeight = (yaoTableH - cardPadding(8) - estimatedHeader) / 6
      final cardPadding = 8.0; //上下各4px
      actualHeaderHeight = yaoTableH * 0.12; // header约占总高度12%
      actualRowHeight = (yaoTableH - cardPadding - actualHeaderHeight) / 6;
    }

    return Stack(
      children: [
        // 底层：InfoCard + ShenshaCard + YaoTable垂直排列
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(key: _infoCardKey, child: widget.infoCard),
            const SizedBox(height: 4),
            Container(key: _shenshaCardKey, child: widget.shenshaCard),
            const SizedBox(height: 4),
            Container(key: _yaoTableKey, child: widget.child),
          ],
        ),

        // 上层：关系连线（覆盖整个区域）
        if (widget.relations.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: _RelationsPainter(
                relations: widget.relations,
                settings: widget.settings,
                monthZhi: widget.monthZhi,
                dayZhi: widget.dayZhi,
                showQuantification: widget.showQuantification,
                infoCardHeight: infoCardH,
                shenshaCardHeight: shenshaCardH,
                yaoTableHeight: yaoTableH,
                actualHeaderHeight: actualHeaderHeight,
                actualRowHeight: actualRowHeight,
              ),
              size: Size.infinite,
            ),
          ),
      ],
    );
  }

  /// 获取组件实际高度
  double _getHeight(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      return renderBox.size.height;
    }
    return 0;
  }
}

/// 简化版关系绘制器
class _RelationsPainter extends CustomPainter {
  final List<YaoRelation> relations;
  final AppSettings settings;
  final String monthZhi;
  final String dayZhi;
  final bool showQuantification;
  final double infoCardHeight;
  final double shenshaCardHeight;
  final double yaoTableHeight;
  final double actualHeaderHeight;
  final double actualRowHeight;

  _RelationsPainter({
    required this.relations,
    required this.settings,
    required this.monthZhi,
    required this.dayZhi,
    this.showQuantification = false,
    this.infoCardHeight = 0,
    this.shenshaCardHeight = 0,
    this.yaoTableHeight = 0,
    this.actualHeaderHeight = 0,
    this.actualRowHeight = 0,
  });

  /// 让触摸事件穿透，不阻挡下层的按钮操作
  @override
  bool hitTest(Offset position) => false;

  @override
  void paint(Canvas canvas, Size size) {
    if (relations.isEmpty || size.isEmpty) return;

    // 使用实际测量的高度（如果测量失败则使用默认估算值）
    final measuredInfoCardH = infoCardHeight > 0 ? infoCardHeight : 90.0;
    final measuredShenshaCardH = shenshaCardHeight > 0 ? shenshaCardHeight : 48.0;

    // YaoTable在Stack中的起始Y位置
    final yaoTableStartY = measuredInfoCardH + 4 + measuredShenshaCardH + 4;

    // YaoTable内部布局（优先使用测量值）
    // Card padding: all(4) = 上下共8px，顶部4px
    final headerH = actualHeaderHeight > 0 ? actualHeaderHeight : 22.0;
    final rowH = actualRowHeight > 0 ? actualRowHeight : 21.0;

    // "支"列的x位置：神(28)+伏(36)+六亲(36) = 100，加上量化列偏移
    final zhiColumnX = 100.0 + (showQuantification ? 28 : 18);

    // 变卦列的x位置：前面的列宽度之和
    // 神(28)+伏(36)+六亲(36)+支(36或50)+世应(24)+本卦(80) = 244或256
    final benGuaWidth = 80.0;
    final bianGuaStartX = zhiColumnX + (showQuantification ? 50 : 36) + 24 + benGuaWidth + 4;
    // 变卦地支在变卦列中的位置：爻象符号后约60px（130宽度的后半部分是地支五行）
    final bianGuaZhiX = bianGuaStartX + 60;

    // 爻位置（从上到下，position 6→1 对应 index 0→5）
    // Y = yaoTableStartY + cardPaddingTop(4) + headerH + rowH的中心
    final yaoPositions = List.generate(6, (i) {
      return Offset(zhiColumnX, yaoTableStartY + 4 + headerH + rowH * (i + 0.5));
    });

    // 变爻位置（从变卦列的地支位置出发）
    final bianYaoPositions = List.generate(6, (i) {
      return Offset(bianGuaZhiX, yaoTableStartY + 4 + headerH + rowH * (i + 0.5));
    });

    // 月建位置：从InfoCard中的月建文字位置出发
    final monthPos = Offset(65, measuredInfoCardH * 0.45);

    // 日辰位置：日建在第四个干支
    final dayPos = Offset(145, measuredInfoCardH * 0.45);

    // 绘制关系
    for (int i = 0; i < relations.length; i++) {
      final relation = relations[i];
      _drawRelation(canvas, relation, i, monthPos, dayPos, yaoPositions, bianYaoPositions, size);
    }
  }

  void _drawRelation(Canvas canvas, YaoRelation relation, int index,
      Offset monthPos, Offset dayPos, List<Offset> yaoPositions, List<Offset> bianYaoPositions, Size size) {
    // 获取起点
    Offset start;
    if (relation.fromType == 'month') {
      start = monthPos; // 从信息卡的月建位置出发
    } else if (relation.fromType == 'day') {
      start = dayPos; // 从信息卡的日辰位置出发
    } else if (relation.fromType == 'bian') {
      // 变爻从变卦列的地支位置出发
      final idx = 6 - relation.fromPosition;
      if (idx >= 0 && idx < 6) {
        start = bianYaoPositions[idx];
      } else {
        return;
      }
    } else {
      // yao（本卦爻）position 1-6 对应 index 5-0
      final idx = 6 - relation.fromPosition;
      if (idx >= 0 && idx < 6) {
        start = yaoPositions[idx];
      } else {
        return;
      }
    }

    // 获取终点
    Offset end;
    if (relation.toType == 'yao') {
      final idx = 6 - relation.toPosition;
      if (idx >= 0 && idx < 6) {
        end = yaoPositions[idx];
      } else {
        return;
      }
    } else if (relation.toType == 'fu') {
      // 伏神在爻右侧（伏神列）
      final idx = 6 - relation.toPosition;
      if (idx >= 0 && idx < 6) {
        end = Offset(28 + 18, yaoPositions[idx].dy); // 伏神列中心
      } else {
        return;
      }
    } else {
      return;
    }

    // 计算控制点（传入关系类型）
    final controlPoint = _calculateControlPoint(start, end, index, size, relation.relationType);

    // 颜色（使用自定义设置或默认值）
    final color = settings.getLineColor(relation.relationType);

    // 绘制贝塞尔曲线
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    // 绘制箭头
    _drawArrow(canvas, start, end, controlPoint, color);
  }

  Offset _calculateControlPoint(Offset start, Offset end, int index, Size size, int relationType) {
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;

    // 判断起点类型（是否从信息栏出发）
    final isFromInfoBar = start.dy < 120; // 信息栏在Y<120区域

    if (isFromInfoBar) {
      // 从信息栏出发的连线，弧度向外侧弯曲
      // 月建（左侧）连线向左弧，日辰（右侧）连线向右弧
      final isFromLeft = start.dx < size.width / 2;
      final arcOffset = 20.0 + (index % 4) * 10;

      if (isFromLeft) {
        // 月建连线：控制点向左偏移，形成向左的弧线
        return Offset(start.dx - arcOffset, midY - 10);
      } else {
        // 日辰连线：控制点向右偏移，形成向右的弧线
        return Offset(start.dx + arcOffset, midY - 10);
      }
    } else {
      // 爻到爻的连线（动爻到静爻、变爻到动爻等）
      // 根据关系类型区分弧度方向：
      // - 冲合（relationChong=1, relationHe=2, relationSanHe=3, relationBanHe=4）：弧度向上弯曲
      // - 生克（relationSheng=5, relationKe=6）：弧度向下弯曲

      final isChongHe = relationType >= 1 && relationType <= 4; // 冲合类
      final isShengKe = relationType >= 5 && relationType <= 6; // 生克类

      // 弧度偏移量
      final verticalOffset = 15.0 + (index % 3) * 8;
      final horizontalOffset = 25.0 + (index % 2) * 15;

      // 根据起点和终点的相对位置决定弧线基础方向
      final isGoingRight = end.dx > start.dx;

      if (isChongHe) {
        // 冲合线：弧度向上弯曲（负方向）
        return Offset(midX + (isGoingRight ? -horizontalOffset : horizontalOffset),
                      midY - verticalOffset);
      } else if (isShengKe) {
        // 生克线：弧度向下弯曲（正方向）
        return Offset(midX + (isGoingRight ? horizontalOffset : -horizontalOffset),
                      midY + verticalOffset);
      } else {
        // 默认：向上弯曲
        return Offset(midX + (isGoingRight ? -horizontalOffset : horizontalOffset),
                      midY - verticalOffset);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Offset control, Color color) {
    // 简化的箭头绘制：在终点附近绘制小三角形
    final angle = atan2(end.dy - control.dy, end.dx - control.dx);
    const arrowSize = 6.0;
    const arrowAngle = pi / 7;

    final path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowSize * cos(angle - arrowAngle),
      end.dy - arrowSize * sin(angle - arrowAngle),
    );
    path.lineTo(
      end.dx - arrowSize * cos(angle + arrowAngle),
      end.dy - arrowSize * sin(angle + arrowAngle),
    );
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
