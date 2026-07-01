import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../version.dart';
import 'privacy_screen.dart';

/// 应用说明页面
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使用说明'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 应用介绍
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, size: 24, color: const Color(0xFF8B4513)),
                        const SizedBox(width: 8),
                        const Text(
                          '六爻助手',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '本应用采用传统纳甲筮法，支持摇卦和手动输入两种起卦方式，自动计算六爻、六亲、六神、伏神、神煞等信息。',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 使用方法
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, size: 24, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '使用方法',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildStep(1, '设置起卦时间', '点击"修改时间"选择起卦的日期和时辰，系统会自动计算对应的干支和节气信息。'),
                    const SizedBox(height: 12),

                    _buildStep(2, '填写起卦人信息', '可填写姓名和性别（可选），方便日后查阅。OCR导入时自动填入识别日期时间。'),
                    const SizedBox(height: 12),

                    _buildStep(3, '输入所问问题', '填写您想要咨询的问题（可选）。'),
                    const SizedBox(height: 12),

                    _buildStep(4, '选择起卦方式', '• 在线摇卦：模拟抛掷三枚铜钱，共六次\n• 手动输入：直接输入六次抛掷的背面数\n• 拍照/剪贴板导入：拍摄排盘图片或粘贴文字，自动识别'),
                    const SizedBox(height: 12),

                    _buildStep(5, '查看排盘结果', '排盘完成后可查看本卦、变卦、六爻详情、冲合生克连线等信息，并可保存到历史记录。'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 在线摇卦
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.casino, size: 24, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '在线摇卦',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '点击"抛铜钱"按钮，三枚铜钱会以3D翻转动画模拟抛掷过程，完成后自动显示本次结果。',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '共抛掷六次，从初爻到上爻。每次结果会实时显示，六次完成后可点击"查看排盘"进入结果页。',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 18, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '支持手机摇动触发抛掷（需传感器权限）。动画播放期间按钮自动禁用。',
                              style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 导入排盘
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.camera_alt, size: 24, color: Colors.teal.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '导入排盘',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '支持三种方式导入已有排盘：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    _buildPhotoStep(1, '拍照导入', '使用相机拍摄排盘图片，系统自动识别图片中的文字。点击"开始识别"后，完全在本地进行OCR识别，无需网络。'),
                    const SizedBox(height: 8),
                    _buildPhotoStep(2, '相册选择', '从手机相册中选择排盘图片，识别流程与拍照相同。'),
                    const SizedBox(height: 8),
                    _buildPhotoStep(3, '从剪贴板导入', '复制排盘文字后，点击"从剪贴板导入"，系统直接解析文本内容，等同于OCR识别结果。'),
                    const SizedBox(height: 12),

                    const Text('识别完成后可编辑修正干支、卦名等信息，点击"校正排盘"自动计算完整排盘数据。',
                        style: TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 历史记录与导出
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, size: 24, color: Colors.indigo.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '历史记录与导出',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '所有保存的排盘记录按时间倒序排列，每条记录显示起卦时间、创建时间、起卦人、问题和卦象。',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem('搜索', '按问题关键词或起卦人姓名模糊搜索记录', Colors.blue),
                    const SizedBox(height: 6),
                    _buildFeatureItem('多选操作', '长按进入选择模式，可批量选中多条记录', Colors.indigo),
                    const SizedBox(height: 6),
                    _buildFeatureItem('导出Markdown', '选中单条或多条记录，导出为Markdown格式文件，可通过系统分享发送到微信、飞书、邮件等', Colors.green),
                    const SizedBox(height: 12),
                    const Text(
                      '解卦笔记：在排盘结果页底部可编辑解卦内容，点击"完成"自动保存。收到他人分享的排盘时自动弹窗提示，确认后自动保存当前编辑内容再跳转。',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 背面数说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 24, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '背面数含义',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '每次掷三枚铜钱，统计背面（反面）数量：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildRuleRow('0背', '三个正面', '老阴（动爻）'),
                    _buildRuleRow('1背', '两正一反', '少阳（静爻）'),
                    _buildRuleRow('2背', '一正两反', '少阴（静爻）'),
                    _buildRuleRow('3背', '三个反面', '老阳（动爻）'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 辅助解卦功能说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_fix_high, size: 24, color: Colors.purple.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '辅助解卦功能',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '排盘结果页和历史详情页提供以下辅助工具（开关在爻表下方）：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    _buildFeatureItem(
                      '数字量化',
                      '显示每个爻位地支的数字量化值。正值（红色）表示有利，负值（蓝色）表示不利，日冲显示"*"，0值显示灰色。',
                      Colors.purple,
                    ),
                    const SizedBox(height: 10),

                    _buildFeatureItem(
                      '冲合生克连线',
                      '直观显示月建、日辰、动爻之间的五行关系：冲（红色）、合（绿色）、生（橙色）、克（蓝色）。'
                      '连线涵盖：月日对六爻、动爻对静爻、动爻对动爻、变爻对动爻、动爻对伏神。',
                      Colors.red,
                    ),
                    const SizedBox(height: 10),

                    _buildFeatureItem(
                      '三合局分析',
                      '自动识别卦中三合局（申子辰、寅午戌、巳酉丑、亥卯未），标注成局爻位和日月参与信息。中神（子午卯酉）必须在卦爻上，三爻缺一不可。',
                      Colors.teal,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 设置
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, size: 24, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '个性化设置',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '点击首页右上角齿轮图标进入设置，包含三个分页：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem('颜色', '自定义静爻(默认黑)/动爻(默认红)颜色、连线颜色、五行彩色显示开关、干支彩色显示开关', Colors.orange),
                    const SizedBox(height: 6),
                    _buildFeatureItem(
                      '字体',
                      '调整爻象字体(默认10)、干支字体(默认15)、旬空字体(默认13)、神煞字体(默认12)、信息栏字体(默认12)大小。字体过大时自动换行。',
                      Colors.blue,
                    ),
                    const SizedBox(height: 6),
                    _buildFeatureItem(
                      '神煞',
                      '全部16项神煞列表（天乙贵人、驿马、华盖、咸池、禄神、天医、文昌、将星、羊刃、'
                      '红鸾、天喜、劫煞、灾煞、亡神、孤辰、寡宿），可勾选需要在排盘结果中显示的项目。',
                      Colors.amber,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 易青岚学员专享
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.stars, size: 24, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '易青岚学员专享',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '通过验证码解锁以下高级功能（首页底部"易青岚学员专享"板块进入）：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem('神煞详解', '16项神煞的完整说明、用法指导、查法条件、吉凶效应，可折叠展开浏览。', Colors.purple),
                    const SizedBox(height: 6),
                    _buildFeatureItem('易青岚高级课笔记', '40课时六爻进阶课程全文笔记（第一至六课总结至第四十五课十二长生总结），目录列表+详情页。', Colors.brown),
                    const SizedBox(height: 6),
                    _buildFeatureItem('易青岚论坛', '内置WebView浏览器访问bbs.qlyxt.com，解锁后可直接在App内浏览论坛。', Colors.blue),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 隐私说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, size: 24, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '隐私说明',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• OCR识别完全在本地进行，图片不会上传到任何服务器\n'
                      '• 所有排盘数据仅存储在本地数据库中\n'
                      '• 节气数据使用内置天文算法计算，无需网络\n'
                      '• 内置浏览器访问论坛需网络连接',
                      style: TextStyle(fontSize: 14, height: 1.8),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 联系方式
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.feedback, size: 24, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          '问题反馈',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '使用中如有问题或建议，欢迎联系反馈：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.chat, size: 20, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            '微信号：FlyingKool',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: 'FlyingKool'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已复制微信号')),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('复制', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 隐私政策
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                child: const Text('隐私政策', style: TextStyle(fontSize: 13)),
              ),
            ),
            // 版本号
            Center(
              child: Text(
                'v$appVersion ($appBuildNumber)',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: const Color(0xFF8B4513), shape: BoxShape.circle),
          child: Center(child: Text('$number',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleRow(String back, String coins, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 50, alignment: Alignment.center,
            child: Text(back, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('$coins → $type')),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 18, height: 18, margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoStep(int number, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 22, height: 22,
            decoration: BoxDecoration(color: Colors.teal.shade700, shape: BoxShape.circle),
            child: Center(child: Text('$number',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(content, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}
