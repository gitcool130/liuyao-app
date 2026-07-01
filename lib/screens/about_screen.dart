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

                    _buildStep(1, '设置起卦时间', '点击"修改时间"选择起卦的日期和时辰，系统会自动计算对应的干支。'),
                    const SizedBox(height: 12),

                    _buildStep(2, '填写起卦人信息', '可填写姓名和性别（可选），方便日后查阅。'),
                    const SizedBox(height: 12),

                    _buildStep(3, '输入所问问题', '填写您想要咨询的问题（可选）。'),
                    const SizedBox(height: 12),

                    _buildStep(4, '选择起卦方式', '• 在线摇卦：模拟抛掷三枚铜钱，共六次\n• 手动输入：直接输入六次抛掷的背面数\n• 拍照导入：拍摄或选择排盘图片，自动识别'),
                    const SizedBox(height: 12),

                    _buildStep(5, '查看排盘结果', '排盘完成后可查看本卦、变卦、六爻详情等信息，并可保存到历史记录。'),

                    const SizedBox(height: 16),

                    // 拍照导入详细说明
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
                                  '拍照导入排盘',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '无需手动输入，通过拍照或选择图片即可导入已有排盘：',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),

                            _buildPhotoStep(1, '选择图片', '点击"拍照"使用相机拍摄，或点击"相册"从手机中选择排盘图片。'),
                            const SizedBox(height: 8),

                            _buildPhotoStep(2, '开始识别', '点击"开始识别"按钮，系统将自动识别图片中的排盘信息。识别完全在本地进行，无需网络。'),
                            const SizedBox(height: 8),

                            _buildPhotoStep(3, '编辑修正', '识别完成后，可对主要信息进行编辑修正：\n• 性别、占问内容\n• 干支四柱（年柱、月柱、日柱、时柱）\n• 本卦、变卦卦名'),
                            const SizedBox(height: 8),

                            _buildPhotoStep(4, '校正排盘', '点击"校正排盘"按钮，系统将根据识别/编辑的信息，自动计算完整的排盘数据：\n• 动爻位置（从本卦变卦推算）\n• 六神、六亲、地支（纳甲装卦）\n• 世应位置\n• 伏神、神煞\n• 旬空（算法校正）'),
                            const SizedBox(height: 12),

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
                                      '提示：只需识别卦名和日柱干支即可排盘，其他信息由算法自动推算。占问内容支持多行识别。',
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '排盘结果页和历史详情页提供以下辅助解卦工具：',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    _buildFeatureItem(
                      '数字量化',
                      '显示每个爻位地支的数字量化值。正值（红色）表示有利，负值（蓝色）表示不利，日冲显示"*"，0值显示灰色。数值来源于月建和日辰对该地支的作用强度。',
                      Colors.purple,
                    ),
                    const SizedBox(height: 10),

                    _buildFeatureItem(
                      '冲合生克连线',
                      '直观显示爻位之间的五行关系：\n• 冲（红色）：相冲关系\n• 合（绿色）：相合关系\n• 生（橙色）：相生关系\n• 克（蓝色）：相克关系',
                      Colors.red,
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      '连线来源说明：',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    _buildRelationSource('月建', '从日期栏的月建干支发出，指向相关爻位'),
                    _buildRelationSource('日辰', '从日期栏的日辰干支发出，指向相关爻位'),
                    _buildRelationSource('动爻', '从动爻发出，指向静爻或伏神'),
                    _buildRelationSource('变爻', '从变爻发出，指向本位动爻（仅影响自身）'),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF8B4513),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
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
            width: 50,
            alignment: Alignment.center,
            child: Text(
              back,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$coins → $type'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRelationSource(String source, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              source,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8B4513),
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStep(int number, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.teal.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}