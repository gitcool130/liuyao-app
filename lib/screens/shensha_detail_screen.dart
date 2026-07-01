/// 神煞详解页面
/// 16项神煞的详细说明与用法
library;

import 'package:flutter/material.dart';

/// 神煞详解内容
class ShenshaDetail {
  final String name;
  final String starName;    // 星宿名
  final String meaning;     // 含义
  final String usage;       // 用法
  final String condition;   // 条件
  final String effect;      // 吉凶效应

  const ShenshaDetail({
    required this.name,
    required this.starName,
    required this.meaning,
    required this.usage,
    required this.condition,
    required this.effect,
  });
}

const List<ShenshaDetail> shenshaDetails = [
  ShenshaDetail(
    name: '天乙贵人',
    starName: '天乙星',
    meaning: '最吉之神，主贵人相助、遇难呈祥。天乙乃是紫微垣中一星，主贵人、福禄。',
    usage: '天乙贵人为六爻中最重要的吉神之一。当日辰或月建临天乙贵人时，代表有贵人暗中相助。'
        '用神临天乙贵人，主事情有人帮衬，顺遂吉祥。世爻临天乙贵人，主自身有贵人缘。'
        '天乙贵人临官鬼，主贵人为官宦之人；临妻财，主贵人为富商；临子孙，主贵人为晚辈或僧道。'
        '天乙贵人逢空亡，贵人无力或贵人不在；逢冲，贵人变动。',
    condition: '以日干查之。甲戊庚日见丑未，乙己日见申子，丙丁日见亥酉，'
        '辛日见寅午，壬癸日见卯巳。',
    effect: '诸事遇之皆吉，主有人相助、遇难呈祥、转危为安。',
  ),
  ShenshaDetail(
    name: '驿马',
    starName: '驿马星',
    meaning: '主奔波、出行、变动、迁移。驿马为五行中生处，主动荡奔跑。',
    usage: '驿马发动或临用神，主出行、调动、变动。'
        '测行人用神临驿马，行人已动身或将动身。'
        '测事业官星临驿马，主工作调动、升迁。'
        '测求财财临驿马，主财来财去、奔波得财。'
        '驿马逢合，为绊住，不能动或行动受阻。'
        '驿马逢冲，动得更快更急。'
        '测疾病驿马临用神，病有转移或需转院治疗。',
    condition: '以日支查之。申子辰日见寅，寅午戌日见申，巳酉丑日见亥，亥卯未日见巳。',
    effect: '主动、变。出行吉利，居家则多奔波劳碌。',
  ),
  ShenshaDetail(
    name: '华盖',
    starName: '华盖星',
    meaning: '主艺术、才华、孤独、清高。华盖为帝座之星，主孤傲清高。',
    usage: '华盖临用神或世爻，主人有艺术才华、有独特见解、性格清高孤傲。'
        '华盖临官鬼，主宗教、玄学缘分，适合研究命理、风水等。'
        '华盖临父母，主学术研究、文化技艺。'
        '华盖逢空亡，才华不得施展。'
        '华盖临桃花，主艺术魅力，但也主感情上的孤独感。'
        '测修行、灵修之事，华盖为吉星。测婚姻，华盖则主孤独之象。',
    condition: '以年支查之。申子辰年见辰，寅午戌年见戌，巳酉丑年见丑，亥卯未年见未。',
    effect: '吉凶参半。主才华艺术则吉，主孤独清高则凶。',
  ),
  ShenshaDetail(
    name: '咸池',
    starName: '桃花星',
    meaning: '又称桃花，主感情、异性、魅力。咸池为天池星，主淫邪、美貌。',
    usage: '咸池临用神或世爻，主人有魅力、异性缘好。'
        '咸池临官鬼，主因色惹祸、桃花劫。咸池临妻财，主因色得财。'
        '咸池动而生世，主有桃花运。咸池动而克世，主因色招灾。'
        '咸池临玄武，主暗昧淫邪之事。咸池临白虎，主因色伤身。'
        '测婚姻，咸池临用神为感情丰富；测官司，咸池主因色起讼。'
        '咸池逢空亡，桃花落空；逢冲，桃花变动或结束。',
    condition: '以日支查之。申子辰日见酉，寅午戌日见卯，巳酉丑日见午，亥卯未日见子。',
    effect: '吉凶参半。主魅力感情则吉，主淫邪灾祸则凶。',
  ),
  ShenshaDetail(
    name: '禄神',
    starName: '禄神星',
    meaning: '主财富、地位、俸禄。禄为官俸，主衣食之禄。',
    usage: '禄神临用神或世爻，主衣食无忧、有福禄之象。'
        '禄神临官鬼，主有官职俸禄。禄神临妻财，主财富丰厚。'
        '禄神临父母，主靠技艺或学问得财。禄神临兄弟，主靠合作得财。'
        '测事业禄神为要，禄神旺象则职位稳、俸禄厚。'
        '禄神逢空亡，福禄虚空。逢冲，禄有变动。入墓，禄被埋没。'
        '身弱遇禄神，为有福之人；身旺遇禄神，锦上添花。',
    condition: '以日干查之。甲日见寅，乙日见卯，丙戊日见巳，丁己日见午，'
        '庚日见申，辛日见酉，壬日见亥，癸日见子。',
    effect: '大吉。主得财、升职、福禄来临。',
  ),
  ShenshaDetail(
    name: '天医',
    starName: '天医星',
    meaning: '主健康、医疗、贵人相助。天医为天之医神，主医药健康。',
    usage: '天医临用神或世爻，主身体康健、有良医救治。'
        '天医临官鬼，主因病得福、遇良医。天医临子孙，主无忧无病。'
        '测疾病，天医临用神为吉，主有救、遇良医。'
        '天医逢空亡，医药无力。逢冲，需换医生或换药。'
        '天医临白虎，主需外科手术。天医临青龙，主用良药调理。',
    condition: '按月支查之。寅月见丑，卯月见寅，辰月见卯，巳月见辰，'
        '午月见巳，未月见午，申月见未，酉月见申，戌月见酉，亥月见戌，子月见亥，丑月见子。',
    effect: '大吉。主健康、遇良医、疾病可愈。',
  ),
  ShenshaDetail(
    name: '文昌',
    starName: '文昌星',
    meaning: '主学业、文书、考试、文采。文昌为文曲之星，主功名学业。',
    usage: '文昌临用神或世爻，主学业有成、文采出众。'
        '文昌临父母，主考试顺利、金榜题名。'
        '文昌临子孙，主才华横溢、聪明智慧。'
        '测考试，文昌为重中之重，旺象则学业顺遂。'
        '文昌逢空，学业受阻、考试失利。逢冲，学业变动或改专业。'
        '文昌临青龙，主文采斐然。临朱雀，主口才辩论之才。',
    condition: '以日干查之。甲日见巳，乙日见午，丙戊日见申，丁己日见酉，'
        '庚日见亥，辛日见子，壬日见寅，癸日见卯。',
    effect: '大吉。主学业有成、考试顺利、文采出众。',
  ),
  ShenshaDetail(
    name: '将星',
    starName: '将星',
    meaning: '主权柄、领导力、才能。将星为武曲之星，主掌权领军。',
    usage: '将星临用神或世爻，主人有领导才能、能掌权。'
        '将星临官鬼，主有官职权柄。将星临兄弟，主有号召力。'
        '测事业，将星旺象则能掌权、有领导地位。'
        '将星逢空，权柄失落。逢冲，权柄被夺或变动。'
        '将星临白虎，主武职、军警之权。临青龙，主文职管理之权。'
        '将星入墓，权柄被收或退居二线。',
    condition: '以日支查之。申子辰日见子，寅午戌日见午，巳酉丑日见酉，亥卯未日见卯。',
    effect: '大吉。主权在握、领导有力、事业有成。',
  ),
  ShenshaDetail(
    name: '羊刃',
    starName: '羊刃星',
    meaning: '主刚强、果断，过则为血光。羊刃为刚猛之星，主刚烈决断。',
    usage: '羊刃临用神或世爻，主人果断刚强、有魄力。'
        '羊刃临官鬼，主子女性刚强、事业有成的女强人，但也主性格强势。'
        '羊刃临白虎，主血光之灾、手术、争斗。'
        '羊刃克世，主自身刚愎自用、性格过刚。'
        '测官司，羊刃主激烈对抗。测疾病，主需手术。'
        '羊刃逢冲，刚烈之性更甚，易有争斗。'
        '羊刃宜制不宜扶，制则成器，扶则为祸。'
        '身旺遇羊刃为忌，身弱遇羊刃可助身。',
    condition: '以日干查之。甲日见卯，丙戊日见午，庚日见酉，壬日见子，'
        '乙日见寅，丁己日见巳，辛日见申，癸日见亥。',
    effect: '吉凶参半。主刚强果断则吉，主血光争斗则凶。',
  ),
  ShenshaDetail(
    name: '红鸾',
    starName: '红鸾星',
    meaning: '主婚恋、喜庆、姻缘。红鸾为婚缘之星，主婚姻喜庆。',
    usage: '红鸾临用神或世爻，主有婚姻之喜、恋爱之象。'
        '红鸾临官鬼，主男方有婚恋之意。红鸾临妻财，主女方有婚恋之象。'
        '测婚姻，红鸾为重要参考，旺象则婚事可成。'
        '红鸾逢空，婚恋无着落。逢冲，婚恋有变。'
        '红鸾合世，主有姻缘来临。红鸾冲世，主姻缘错过。'
        '红鸾动，主近期有婚恋之事。',
    condition: '以日支查之。子日见卯，丑日见寅，寅日见丑，卯日见子，'
        '辰日见亥，巳日见戌，午日见酉，未日见申，申日见未，酉日见午，戌日见巳，亥日见辰。',
    effect: '大吉。主婚恋喜事、姻缘到来。',
  ),
  ShenshaDetail(
    name: '天喜',
    starName: '天喜星',
    meaning: '主喜庆、添丁、好事临近。天喜为欢庆之星，主喜事临门。',
    usage: '天喜临用神或世爻，主有喜事、好事来临。'
        '天喜临子孙，主添丁进口、怀孕之喜。'
        '天喜临妻财，主有财喜。天喜临官鬼，主有事业之喜。'
        '测生育，天喜临子孙为吉兆。'
        '天喜逢空，喜事成空。逢冲，喜事有变或推迟。'
        '天喜与红鸾同现，主双重喜事或婚喜同至。',
    condition: '以日支查之。红鸾对冲位，子日见酉，丑日见申，寅日见未，卯日见午，'
        '辰日见巳，巳日见辰，午日见卯，未日见寅，申日见丑，酉日见子，戌日见亥，亥日见戌。',
    effect: '大吉。主喜事临门、好事将近。',
  ),
  ShenshaDetail(
    name: '劫煞',
    starName: '劫煞星',
    meaning: '主劫难、破财、小人。劫煞为凶煞之星，主劫夺灾祸。',
    usage: '劫煞临用神或世爻，主有劫难、破财之事。'
        '劫煞临官鬼，主官非劫难。劫煞临兄弟，主破财、被人夺财。'
        '劫煞临玄武，主被盗被劫。劫煞临白虎，主意外伤害。'
        '劫煞克用神，主用神受损、事情不利。'
        '劫煞逢空亡，凶力减弱。逢合，劫难被化解。'
        '测出行劫煞动，防被盗被抢。测财运劫煞动，防破财。'
        '劫煞宜静不宜动，静则无事，动则有灾。',
    condition: '以日支查之。申子辰日见巳，寅午戌日见亥，巳酉丑日见寅，亥卯未日见申。',
    effect: '大凶。主破财、劫难、小人侵扰。',
  ),
  ShenshaDetail(
    name: '灾煞',
    starName: '灾煞星',
    meaning: '主灾祸、意外、病灾。灾煞为凶星，主意外灾祸。',
    usage: '灾煞临用神或世爻，主有灾祸临头。'
        '灾煞临白虎，主血光之灾、外伤意外。'
        '灾煞临官鬼，主官非之灾。灾煞临父母，主长辈有灾。'
        '灾煞克世，主自身有灾。灾煞生世，灾祸可化解。'
        '灾煞逢空，灾祸虚惊。逢合，灾祸被化解或推迟。'
        '测出行灾煞动，防灾祸发生。测疾病灾煞动，防病情加重。',
    condition: '以年支查之。申子辰年见午，寅午戌年见子，巳酉丑年见卯，亥卯未年见酉。',
    effect: '大凶。主意外灾祸、病伤之事。',
  ),
  ShenshaDetail(
    name: '亡神',
    starName: '亡神星',
    meaning: '主失物、走失、神魂不定。亡神为失亡之星，主遗失走失。',
    usage: '亡神临用神，主所测之人或物有走失、遗失之象。'
        '亡神临官鬼，主因官非而失。亡神临兄弟，主因朋友而失。'
        '亡神克世，主自身失魂落魄、精神不集中。'
        '测失物，亡神为重要参考信息。'
        '亡神逢空，失物可寻回。逢冲，失物有转移。'
        '亡神临玄武，主被盗。亡神临白虎，主被抢。',
    condition: '以日支查之。申子辰日见亥，寅午戌日见巳，巳酉丑日见申，亥卯未日见寅。',
    effect: '大凶。主走失、遗失、精神恍惚。',
  ),
  ShenshaDetail(
    name: '孤辰',
    starName: '孤辰星',
    meaning: '主孤独、无依、性格孤僻。孤辰为孤独之星，主孤寡离群。',
    usage: '孤辰临世爻，主自身性格孤僻、不合群。'
        '孤辰临官鬼，男主婚姻晚。孤辰临妻财，女主婚姻迟。'
        '测婚姻，孤辰为不利信息，主晚婚或婚姻不顺。'
        '孤辰逢空，孤独感可化解。逢冲，孤独状态会改变。'
        '孤辰临青龙，主清高自许。临玄武，主孤独隐士之象。'
        '测修行，孤辰反为吉象，主适合独修。',
    condition: '以年支查之。亥子丑年见戌，寅卯辰年见巳，巳午未年见申，申酉戌年见亥。',
    effect: '凶。主孤独、婚姻不顺、性格孤僻。',
  ),
  ShenshaDetail(
    name: '寡宿',
    starName: '寡宿星',
    meaning: '主寡居、鳏独、与亲缘淡薄。寡宿为孤寡之星，主亲情淡薄。',
    usage: '寡宿临世爻，主亲情缘薄、与家人关系疏远。'
        '寡宿临官鬼，男主鳏居之象。寡宿临妻财，女主寡居之象。'
        '测婚姻，寡宿为忌神，主婚姻不长久或配偶缘薄。'
        '寡宿逢空，孤独状态可改变。逢冲，孤寡之象被冲破。'
        '寡宿与孤辰同现，孤独之象更重。'
        '测子女，寡宿临子孙主子女缘薄。',
    condition: '以年支查之。亥子丑年见寅，寅卯辰年见丑，巳午未年见辰，申酉戌年见未。',
    effect: '凶。主孤寡、亲情淡薄、婚姻不顺。',
  ),
];

class ShenshaDetailScreen extends StatelessWidget {
  const ShenshaDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('神煞详解')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: shenshaDetails.map((detail) => _ShenshaCard(detail: detail)).toList(),
      ),
    );
  }
}

class _ShenshaCard extends StatelessWidget {
  final ShenshaDetail detail;

  const _ShenshaCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(_getIcon(detail.name), size: 20, color: _getColor(detail.effect)),
            const SizedBox(width: 8),
            Text(detail.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Text(
          detail.meaning.length > 30 ? '${detail.meaning.substring(0, 30)}...' : detail.meaning,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('含义', detail.meaning),
                _section('用法', detail.usage),
                _section('查法', detail.condition),
                _section('效应', detail.effect, color: _getColor(detail.effect)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String label, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(fontSize: 14, height: 1.6, color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  Color _getColor(String effect) {
    if (effect.contains('大吉')) return const Color(0xFF2E7D32);
    if (effect.contains('吉凶参半')) return Colors.orange;
    if (effect.contains('大凶') || effect.contains('凶')) return Colors.red;
    if (effect.contains('吉')) return const Color(0xFF2E7D32);
    return Colors.black87;
  }

  IconData _getIcon(String name) {
    switch (name) {
      case '天乙贵人': return Icons.star;
      case '驿马': return Icons.directions_run;
      case '华盖': return Icons.diamond;
      case '咸池': return Icons.favorite;
      case '禄神': return Icons.trending_up;
      case '天医': return Icons.local_hospital;
      case '文昌': return Icons.book;
      case '将星': return Icons.military_tech;
      case '羊刃': return Icons.flash_on;
      case '红鸾': return Icons.favorite_border;
      case '天喜': return Icons.celebration;
      case '劫煞': return Icons.warning_amber;
      case '灾煞': return Icons.report_problem;
      case '亡神': return Icons.search_off;
      case '孤辰': return Icons.person_off;
      case '寡宿': return Icons.bed;
      default: return Icons.star_border;
    }
  }
}
