# 六爻排盘 (Liuyao Divination App)

六爻排盘软件，支持输入摇卦数字或在线起卦排盘，数据存储在用户手机本地，可离线运行。解卦记录保存后可单独或批量导出，支持通过OCR识别排盘截图，主要针对易青岚的排盘和作业卦截图。

基于 Flutter 的跨平台应用，遵循传统京房纳甲法。

## 功能

- 铜钱手动输入 / 在线模拟摇卦 / 时间起卦
- **拍照导入排盘**（本地OCR识别，无需API Key）
- 干支转换（公历 → 六十甲子）
- 纳甲装卦（京房八宫纳甲）
- 六亲 / 六神 / 世应 / 旬空 / 伏神 / 神煞
- 本卦 / 变卦 / 互卦
- 辅助解卦功能（数字量化、冲合生克连线）
- 历史记录存储（SQLite）
- 解卦笔记

## 技术栈

- Flutter 3.x / Dart 3.x
- sqflite + Provider
- Google ML Kit（本地OCR）

## 项目结构

```
lib/
├── algorithms/    # 核心算法（纯 Dart，零 UI 依赖）
├── models/        # 数据模型
├── database/      # SQLite 数据库层
├── providers/     # 状态管理
├── screens/       # 页面
├── widgets/       # 可复用组件
├── services/      # 服务层（OCR识别等）
└── utils/         # 工具函数
```

## ⚠️ 重要约定

### 内外卦 / 64卦编号

本项目的 64 卦索引公式为：

```
idx64 = (innerGuaId - 1) × 8 + (outerGuaId - 1)
```

- `innerGuaId` = 内卦/下卦（初二三爻）编号 1-8
- `outerGuaId` = 外卦/上卦（四五上爻）编号 1-8  
- 八卦编号：1=乾 2=兑 3=离 4=震 5=巽 6=坎 7=艮 8=坤
- 卦名格式：**上卦名+下卦名**（如"天火同人"=上乾下离，"火天大有"=上离下乾）
- **不可混淆内外卦顺序**，否则卦名会颠倒（天风姤 ↔ 风天小畜）

详见 [DEVELOPMENT_SPEC.md](DEVELOPMENT_SPEC.md) 第 12 节。

## 运行测试

```bash
flutter test test/algorithms/
```

## 开发文档

- [DESIGN.md](DESIGN.md) — 六爻排盘理论知识
- [DEVELOPMENT_SPEC.md](DEVELOPMENT_SPEC.md) — 完整开发规格
- [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md) — 开发指南
- [IMAGE_IMPORT_SPEC.md](IMAGE_IMPORT_SPEC.md) — 图像导入功能规格
- [BUG_REPORT.md](BUG_REPORT.md) — 已知 Bug 与修复记录