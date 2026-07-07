# 六爻社区解卦平台 — 项目规划方案

## 一、项目概述

在现有六爻助手排盘功能基础上，构建一个用户间互助解卦的社交平台。用户起卦后不会解，可以发布求助并设置悬赏；其他用户（卦师）接单解卦获取报酬。

### 核心价值
- 解决"会排不会解"的痛点
- 为资深卦师提供知识变现渠道
- 积累大量真实解卦案例数据

---

## 二、整体架构

```
┌─────────────────────────────────────────────────┐
│                   客户端 (Flutter)                │
│  ┌─────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │排盘模块  │ │社区模块   │ │个人中心          │  │
│  │(复用现   │ │·求助发布  │ │·钱包/账单        │  │
│  │有代码)   │ │·求助列表  │ │·接单记录/评价    │  │
│  │         │ │·接单/解卦 │ │·卦师等级/积分    │  │
│  └─────────┘ └──────────┘ └──────────────────┘  │
└──────────────────────┬──────────────────────────┘
                       │ HTTPS / WebSocket
┌──────────────────────┴──────────────────────────┐
│                 后端服务 (Node.js/Express)        │
│  ┌────────┐ ┌──────────┐ ┌──────┐ ┌─────────┐  │
│  │用户认证 │ │求助/接单  │ │支付  │ │消息推送  │  │
│  │微信登录 │ │业务逻辑   │ │微信  │ │WebSocket│  │
│  │JWT     │ │评价/等级  │ │支付  │ │         │  │
│  └────────┘ └──────────┘ └──────┘ └─────────┘  │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────┐
│              数据库 (SQLite / better-sqlite3)      │
│  用户表 | 求助表 | 接单调 | 交易表 | 评价表      │
│  等级表 | 提现表 | 消息表                        │
└─────────────────────────────────────────────────┘
```

### 2.1 域名与服务器

| 项目 | 说明 |
|------|------|
| 域名 | `www.bobolovesu.cn`（已备案） |
| 服务器 | 现有的阿里云 ECS（100.64.7.62） |
| 运行方式 | 独立 PM2 进程，与现有六爻助手服务端共存 |
| 端口规划 | 现有服务 3456，新服务 3457（或通过 Nginx 反向代理 /api/v2） |
| 数据库 | SQLite（better-sqlite3），数据文件放在 `/opt/liuyao-community/data/` |

### 2.2 项目结构

```
liuyao-community/          # 新项目根目录
├── client/                # Flutter 客户端
│   ├── lib/
│   │   ├── algorithms/    # 排盘算法（从 liuyao-app 复制，保持一致）
│   │   ├── models/        # 数据模型（与服务器端对应）
│   │   ├── screens/
│   │   │   ├── auth/      # 微信登录
│   │   │   ├── home/      # 首页（求助列表）
│   │   │   ├── request/   # 发布求助、查看详情
│   │   │   ├── divination/# 接单解卦
│   │   │   ├── profile/   # 个人中心、钱包、等级
│   │   │   └── admin/     # 管理员后台
│   │   ├── services/      # API 调用、WebSocket
│   │   └── widgets/       # 共享组件
│   └── pubspec.yaml
├── server/                # Node.js 后端
│   ├── src/
│   │   ├── routes/        # API 路由
│   │   ├── middleware/    # 认证、权限
│   │   ├── db/            # 数据库初始化 + schema (better-sqlite3)
│   │   ├── services/      # 支付、推送等业务逻辑
│   │   └── utils/         # 工具函数
│   └── package.json
└── docs/                  # 文档
```

---

## 三、数据模型设计

### 3.1 用户系统

```sql
-- 用户表
CREATE TABLE users (
  id                SERIAL PRIMARY KEY,
  wechat_openid     VARCHAR(64) UNIQUE NOT NULL,   -- 微信 OpenID
  nickname          VARCHAR(64),                    -- 微信昵称
  avatar_url        TEXT,                           -- 微信头像
  phone             VARCHAR(20),                    -- 手机号（可选绑定）
  role              VARCHAR(16) DEFAULT 'user',     -- user / diviner / admin
  diviner_level     INTEGER DEFAULT 0,              -- 卦师等级 0=非卦师
  total_orders      INTEGER DEFAULT 0,              -- 累计解卦数
  total_earnings    INTEGER DEFAULT 0,              -- 累计收入（分）
  balance           INTEGER DEFAULT 0,              -- 账户余额（分）

  -- 多维评价（卦师维度）
  rating_satisfaction_sum   INTEGER DEFAULT 0,      -- 整体满意度总分
  rating_theory_sum         INTEGER DEFAULT 0,      -- 解卦理论水平总分
  rating_match_sum          INTEGER DEFAULT 0,      -- 与实际匹配度总分
  rating_guidance_sum       INTEGER DEFAULT 0,      -- 对用户指导作用总分
  rating_clarity_sum        INTEGER DEFAULT 0,      -- 讲解清晰程度总分
  rating_count              INTEGER DEFAULT 0,      -- 评价次数

  -- 拒绝率跟踪（求助者维度）
  total_requests    INTEGER DEFAULT 0,              -- 累计发布求助数
  total_rejections  INTEGER DEFAULT 0,              -- 累计拒绝卦师次数
  max_bounty_level  INTEGER DEFAULT 1,              -- 当前可发布的最高悬赏等级

  -- 卦师被拒绝跟踪（卦师维度）
  diviner_rejected_times  INTEGER DEFAULT 0,        -- 被求助者拒绝的总次数
  diviner_completed_times INTEGER DEFAULT 0,        -- 被求助者确认完成的总次数

  created_at        TIMESTAMP DEFAULT NOW(),
  updated_at        TIMESTAMP DEFAULT NOW()
);

-- 卦师等级表
CREATE TABLE diviner_levels (
  level           INTEGER PRIMARY KEY,            -- 等级 1-10
  title          VARCHAR(32),                     -- 称号：初级卦师、高级卦师等
  min_orders     INTEGER DEFAULT 0,               -- 最低解卦数
  min_rating     DECIMAL(3,2) DEFAULT 0,          -- 最低好评率 0.00-5.00
  min_earnings   INTEGER DEFAULT 0,               -- 最低累计收入（分）
  max_bounty     INTEGER DEFAULT 0,               -- 可接单最高悬赏金额（分，0=不限）
};

-- 用户等级变更记录
CREATE TABLE level_logs (
  id              SERIAL PRIMARY KEY,
  user_id         INTEGER REFERENCES users(id),
  old_level       INTEGER,
  new_level       INTEGER,
  reason          TEXT,
  created_at      TIMESTAMP DEFAULT NOW()
);
```

### 3.2 求助/接单系统

```sql
-- 求助表
CREATE TABLE requests (
  id                  SERIAL PRIMARY KEY,
  user_id             INTEGER REFERENCES users(id),     -- 发起人
  title               VARCHAR(128),                     -- 求助标题
  description         TEXT,                             -- 问题描述
  bounty              INTEGER NOT NULL,                 -- 悬赏金额（分）
  min_diviner_level   INTEGER DEFAULT 1,                -- 最低卦师等级
  status              VARCHAR(16) DEFAULT 'open',       -- open/assigned/completed/cancelled/refunded
  divination_data     JSONB,                            -- 排盘数据（与现有 record 格式兼容）
  rejection_count     INTEGER DEFAULT 0,                -- 当前已拒绝次数
  max_rejections      INTEGER DEFAULT 3,                -- 最大允许拒绝次数
  reject_history      JSONB DEFAULT '[]',               -- [{"assignment_id":1,"diviner_id":2,"reason":"不满意","rejected_at":"..."}]
  source_request_id   INTEGER,                          -- 拒绝后重新发布的来源求助ID（追踪链条）
  created_at          TIMESTAMP DEFAULT NOW(),
  updated_at          TIMESTAMP DEFAULT NOW()
);

-- 接单调（保存完整的接单和解卦记录，用户和卦师均可查阅）
CREATE TABLE assignments (
  id              SERIAL PRIMARY KEY,
  request_id      INTEGER REFERENCES requests(id),
  diviner_id      INTEGER REFERENCES users(id),    -- 接单卦师
  divination_text TEXT,                             -- 解卦内容（最终版）
  status          VARCHAR(16) DEFAULT 'assigned',  -- assigned/completed/rejected_by_seeker/confirmed/refunded
  reject_reason   TEXT,                             -- 求助者拒绝原因
  diviner_rejected_count INTEGER DEFAULT 0,        -- 该卦师被拒绝次数（累计，用于等级评估）
  revision_history JSONB DEFAULT '[]',             -- 解卦修改历史 [{"version":1, "text":"...", "submitted_at":"..."}]
  assigned_at     TIMESTAMP DEFAULT NOW(),
  completed_at    TIMESTAMP,
  confirmed_at    TIMESTAMP,                        -- 求助者确认时间
  UNIQUE(request_id, diviner_id)                    -- 同一求助每个卦师只能接一次
);

-- 评价表（多维评分）
CREATE TABLE ratings (
  id              SERIAL PRIMARY KEY,
  request_id      INTEGER REFERENCES requests(id),
  from_user_id    INTEGER REFERENCES users(id),    -- 评价人（发起求助者）
  to_user_id      INTEGER REFERENCES users(id),    -- 被评价人（卦师）
  type            VARCHAR(16) DEFAULT 'diviner',   -- diviner(评价卦师) / seeker(评价求助者)

  -- 对卦师的多维评分（1-5分）
  satisfaction    INTEGER CHECK(satisfaction >= 1 AND satisfaction <= 5),  -- 整体满意度
  theory          INTEGER CHECK(theory >= 1 AND theory <= 5),              -- 解卦理论水平
  match_accuracy  INTEGER CHECK(match_accuracy >= 1 AND match_accuracy <= 5), -- 与实际匹配度
  guidance        INTEGER CHECK(guidance >= 1 AND guidance <= 5),          -- 对用户指导作用
  clarity         INTEGER CHECK(clarity >= 1 AND clarity <= 5),            -- 讲解清晰程度

  -- 对求助者的评价
  reject_rate     DECIMAL(3,2) DEFAULT 0,          -- 该求助者当前拒绝率（系统填写）
  seeker_comment  TEXT,                             -- 卦师对求助者的评价

  comment         TEXT,                             -- 总体评价文字
  created_at      TIMESTAMP DEFAULT NOW()
);
```

> **SQLite 兼容说明**：以上 SQL 基于 PostgreSQL 语法做设计参考。实际使用 SQLite 时：
> - `SERIAL` → `INTEGER PRIMARY KEY AUTOINCREMENT`
> - `JSONB` → `TEXT`（配合 `json_extract()` 查询）
> - `DECIMAL` → `REAL`
> - `TIMESTAMP DEFAULT NOW()` → `TEXT DEFAULT (datetime('now','localtime'))`
> - 数据库文件：`/opt/liuyao-community/data/community.db`

### 3.3 支付/结算系统

```sql
-- 交易流水表
CREATE TABLE transactions (
  id              SERIAL PRIMARY KEY,
  user_id         INTEGER REFERENCES users(id),
  type            VARCHAR(16),                     -- payment(支付) / income(收入) / withdraw(提现)
  amount          INTEGER NOT NULL,                -- 金额（分）
  balance_before  INTEGER,
  balance_after   INTEGER,
  related_type    VARCHAR(16),                     -- request / withdraw
  related_id      INTEGER,
  external_id     VARCHAR(128),                    -- 微信支付订单号
  status          VARCHAR(16) DEFAULT 'pending',   -- pending/success/failed
  created_at      TIMESTAMP DEFAULT NOW()
);

-- 提现申请表
CREATE TABLE withdrawals (
  id              SERIAL PRIMARY KEY,
  user_id         INTEGER REFERENCES users(id),
  amount          INTEGER NOT NULL,                -- 金额（分）
  account_type    VARCHAR(16),                     -- wechat
  account_info    JSONB,                           -- 微信实名信息
  status          VARCHAR(16) DEFAULT 'pending',   -- pending/approved/rejected/done
  admin_id        INTEGER REFERENCES users(id),
  remark          TEXT,
  created_at      TIMESTAMP DEFAULT NOW(),
  processed_at    TIMESTAMP
);
```

---

## 四、排盘数据格式兼容

两个项目之间的排盘数据格式需要保持互通，用户从六爻助手排盘后可一键发布到社区求助。

### 4.1 数据互通方案

```
六爻助手 DivinationRecord JSON 格式
         │
         ▼
社区平台接收同一 JSON 格式
         │
         ▼
求助详情页直接渲染排盘结果（复用现有 YaoTable 等组件）
```

现有 `DivinationRecord` 的 JSON 格式（含 `backCounts`、`yaoLines`、`shensha` 等）可以直接作为 `requests.divination_data` 字段存储。社区项目复用 `liuyao-app/lib/algorithms/` 目录下的排盘算法代码。

---

## 五、支付接入方案

### 5.1 初期方案：微信支付 Native (JSAPI)

| 接入项 | 说明 |
|--------|------|
| 服务商 | **微信支付商户平台**（个人可申请，需营业执照）|
| 接入难度 | 中等 |
| 费率 | 0.6% |
| 结算周期 | T+1 |
| 必要条件 | ✅ 已备案域名、❌ 需营业执照开通商户号 |

### 5.2 替代方案：第三方聚合支付

如果个人用户暂时没有营业执照，可以考虑：

| 方案 | 说明 | 优势 | 劣势 |
|------|------|------|------|
| **XorPay（xorpay.com）** | 个人可接入微信/支付宝 | 无需营业执照，当天到账 | 费率略高 1-2% |
| **PayJs（payjs.cn）** | 个人微信支付接口 | 个人可申请 | 有手续费 |
| **虎皮椒（xunhupay.com）** | 聚合支付 | 支持个人、接口简单 | 需实名认证 |

**初期推荐 XorPay**：个人用户即可开通微信+支付宝收款，接入简单，API 文档齐全。

### 5.3 支付流程

```
用户充值/支付
    │
    ▼
客户端请求创建支付 → 后端生成支付订单
    │
    ▼
后端调用第三方支付API → 获取支付链接/二维码
    │
    ▼
客户端展示二维码 → 用户扫码支付
    │
    ▼
支付平台异步通知 → 后端更新订单状态 → 更新用户余额
```

### 5.4 资金流

```
用户甲充值 100 元 → 账户余额 100 元
用户甲发布求助悬赏 30 元 → 冻结余额 30 元
卦师乙接单完成 → 用户甲确认 → 30 元转入卦师乙账户
卦师乙提现 30 元 → 管理员审核 → 微信转账到卦师乙
```

---

## 六、卦师等级体系

### 6.1 等级与称号

| 等级 | 称号 | 升级条件 | 可接悬赏上限 |
|------|------|---------|------------|
| 0 | 普通用户 | 注册即可 | 不可接单 |
| 1 | 见习卦师 | 完成5单 | 50元 |
| 2 | 初级卦师 | 完成15单，评分≥3.5 | 100元 |
| 3 | 中级卦师 | 完成30单，评分≥4.0，收入≥200元 | 200元 |
| 4 | 高级卦师 | 完成60单，评分≥4.3，收入≥500元 | 500元 |
| 5 | 资深卦师 | 完成100单，评分≥4.5，收入≥1000元 | 1000元 |
| 6 | 金牌卦师 | 完成200单，评分≥4.6，收入≥3000元 | 3000元 |
| 7 | 首席卦师 | 完成500单，评分≥4.7，收入≥10000元 | 10000元 |
| 8 | 大师 | 完成1000单，评分≥4.8，收入≥30000元 | 不限 |
| 9 | 宗师 | 完成2000单，评分≥4.9，收入≥100000元 | 不限 |
| 10 | 传奇 | 特邀/荣誉卦师 | 不限 |

### 6.2 自动升/降级机制

```
升级：满足条件后自动升级，推送通知
保级：每月至少接1单维持当前等级

降级条件：
  1. 连续30天无接单且等级≥3 → 降1级（防止占位）
  2. 被求助者拒绝累计达以下阈值 → 强制降级：
     - 等级1-2：被拒绝≥3次 → 降回普通用户
     - 等级3-4：被拒绝≥5次 → 降1级
     - 等级5-7：被拒绝≥10次 → 降1级
     - 等级8+：被拒绝≥15次 → 降1级
  3. 接单完成率低于60%（完成数/(完成数+被拒绝数)）→ 降1级
```

**被拒绝率计算公式**：
```
被拒绝率 = 被拒绝次数 / (被拒绝次数 + 完成次数) × 100%
被拒绝次数 = assignments 表中该卦师 status='rejected_by_seeker' 的记录数
```

### 6.3 求助者拒绝率限制

为防止滥用拒绝机制，对求助者进行约束：

| 拒绝率 | 限制 |
|--------|------|
| < 20% | 无限制 |
| 20%-40% | 最高只能发布中级（200元以下）悬赏 |
| 40%-60% | 最高只能发布初级（100元以下）悬赏 |
| > 60% | 禁止发布求助，需联系客服申诉 |

```
拒绝率 = 累计拒绝次数 / 累计发布求助数 × 100%
累计拒绝次数 = 对被接单的卦师拒绝的次数（非求助取消）
```

求助者每次拒绝后，系统提示当前拒绝率及可能的影响。

---

## 七、App功能模块

### 7.1 首页 — 求助广场

```
┌──────────────────────────┐
│ 🔍 搜索/筛选             │
│ ┌──────────────────────┐ │
│ │ 求助标题...    50元   │ │
│ │ 描述摘要    ⭐4.5     │ │
│ │ 3小时前   已接1单     │ │
│ ├──────────────────────┤ │
│ │ 另一个求助...   30元   │ │
│ │ ...                    │ │
│ └──────────────────────┘ │
│  [发布求助]  [我的接单]  │
└──────────────────────────┘
```

### 7.2 发布求助流程

```
1. 排盘（可用六爻助手排完直接分享过来）
2. 填写求助标题+问题描述
3. 设置悬赏金额
4. 设置最低卦师等级（可选）
5. 冻结悬赏金额 → 发布成功
```

### 7.3 接单解卦流程

```
1. 浏览求助列表，选择感兴趣的
2. 查看排盘数据和问题描述（可看到该任务是第几次重新发布）
3. 点击"接单" → 锁定任务（24小时完成）
4. 输入解卦内容（编辑区支持富文本/图片）
5. 提交解卦 → 等待求助者确认
6a. 求助者确认满意 → 悬赏到账 → 多维评价卦师
6b. 求助者不满意，拒绝 → 返回列表，重新发布
    - 第1/2次拒绝：卦师无收入，求助者可重新发布，冻结金额不变
    - 第3次拒绝：自动退款给求助者，该求助关闭
    - 接单卦师能看到该任务是第几次拒绝后的任务
7. 卦师也可在完成后评价求助者（配合度、拒绝历史等）
```

### 7.4 我的页面 — 普通用户视角

```
┌──────────────────────────────┐
│ 头像  昵称                    │
│ ┌──────┬──────┬──────┐       │
│ │求助数│已完成│支出¥XX│       │
│ └──────┴──────┴──────┘       │
│                               │
│ 📋 我发布的求助（含排盘+解卦记录） │
│   ├─ 进行中（待接单/已接单）     │
│   ├─ 待确认（卦师已交解卦，可审阅）│
│   │   ├─ 确认完成 → 评价卦师    │
│   │   └─ 拒绝（填原因）→ 重新发布│
│   └─ 已完成/已退款              │
│   每条可查看：排盘数据、解卦全文、│
│   卦师信息、评价详情             │
│                               │
│ ⭐ 我的评价（收到的+给出的）       │
│ 💰 我的钱包（充值/账单）          │
│ ⚙️ 设置                         │
└──────────────────────────────┘
```

### 7.5 我的页面 — 卦师视角

```
┌──────────────────────────────┐
│ 头像  昵称                    │
│ ⭐ 4.8  中级卦师              │
│ ┌──────┬──────┬──────┐       │
│ │接单50│好评49│收入¥XXX│       │
│ └──────┴──────┴──────┘       │
│                               │
│ 📋 我的解卦（完整记录）           │
│   ├─ 进行中（已接单未完成）      │
│   ├─ 待确认（已提交待用户确认）   │
│   └─ 历史记录                   │
│       ├─ ✅ 已完成/已收款       │
│       │   可查看：用户评价多维度评分│
│       └─ ❌ 被拒绝              │
│           可查看拒绝原因          │
│                               │
│ 📋 求助广场（浏览可接单的求助）    │
│ 💰 我的钱包（收入/提现）          │
│ ⭐ 我的评价（多维度评分明细）      │
│ ⚙️ 卦师设置/行为规范             │
└──────────────────────────────┘
```

### 7.6 卦师被拒绝处理逻辑

```
状态流转：
  用户确认完成  → 卦师：完成数+1，收入到账，等级加分
  用户拒绝      → 卦师：被拒绝数+1，该单无收入，等级减分

被拒绝后展示：
  卦师可在"我的解卦→被拒绝"中查看：
  · 求助者昵称
  · 排盘数据
  · 自己提交的解卦内容
  · 用户填写的拒绝原因

申诉机制：
  如卦师认为拒绝不合理，可点击"申诉"
  → 提交申诉内容 + 证据
  → 管理员审核（3个工作日内）
  → 申诉通过：记录清除，恢复等级分
  → 申诉驳回：维持原判

自动降级触发：
  被拒绝次数达到阈值（见6.2节）→ 自动降级并通知

降级通知模板（被拒绝导致）：
  ⚠️ 您的卦师等级已调整为{new_level}级

  原因：被求助者拒绝次数已达降级阈值
  当前被拒绝次数：{rejected_count}
  当前完成次数：{completed_count}
  完成率：{completion_rate}%

  建议：仔细阅读用户问题描述，确保解卦质量后再接单
```

---

## 八、开发路线图

### Phase 1 — 基础框架（2-3周）
- [ ] 创建新 Flutter 项目，复制排盘算法
- [ ] 搭建后端项目框架（Express + PostgreSQL）
- [ ] 实现微信登录（通过微信公众号/开放平台）
- [ ] 用户注册/登录流程

### Phase 2 — 核心功能（3-4周）
- [ ] 发布求助（含排盘数据导入）
- [ ] 求助列表/详情页
- [ ] 接单/解卦编辑
- [ ] 确认完成/评价

### Phase 3 — 支付与等级（2-3周）
- [ ] 接入第三方支付（XorPay/PayJs）
- [ ] 钱包/充值/提现
- [ ] 卦师等级自动计算
- [ ] 交易流水记录

### Phase 4 — 完善与发布（2周）
- [ ] 消息推送（接单通知、确认通知）
- [ ] 管理员后台（审核提现、用户管理）
- [ ] 测试/修复/发布

---

## 九、技术选型建议

| 组件 | 技术方案 | 理由 |
|------|---------|------|
| 客户端 | Flutter（复用现有代码） | 与六爻助手一致 |
| 后端 | Node.js + Express | 与现有服务端统一 |
| 数据库 | SQLite (better-sqlite3) | 与服务端一致，无额外进程，0配置 |
| ORM | 手写SQL + 轻量封装 | better-sqlite3 自带同步API，简单直接 |
| 认证 | JWT | 无状态，简单 |
| 微信登录 | 微信公众号开发平台 | 个人开发者可接入 |
| 支付 | XorPay（初期） | 个人可开通 |
| 消息推送 | WebSocket + 站内通知 | 简单可靠 |
| 图片存储 | 服务器本地文件 + Nginx | 初期够用 |

---

## 十、域名与服务器部署规划

```
www.bobolovesu.cn
    │
    ├── /api/v1/*           → 现有六爻助手服务 (端口 3456)
    ├── /api/v2/*           → 新社区服务 (端口 3457)
    ├── /apk/*              → 现有 APK 下载
    └── /                    → Nginx 静态页
```

通过 Nginx 反向代理将不同路径转发到不同后端进程，两个服务共用同一台服务器。

---

## 十一、法律合规分析

### 11.1 核心结论

周易六爻排盘/解卦作为**传统文化研究工具**，本身不违法。根据律师事务所的专业分析：

> "网上算命本身不构成违法行为，仅是提供一种娱乐或心理安慰的方式。"
> —— 惠诚律师事务所

合法的关键在于：**不涉及非法占有他人财物、不宣扬封建迷信扰乱社会秩序**。

### 11.2 法律红线（绝对不能碰）

| 风险类型 | 具体行为 | 可能触犯的法律 |
|---------|---------|--------------|
| **诈骗罪** | 虚构命运不顺、谎称可消灾、承诺必中 | 《刑法》第266条，最高无期徒刑 |
| **非法经营罪** | 无证从事经营性互联网信息服务 | 《互联网信息服务管理办法》 |
| **封建迷信** | 宣扬"改运""化煞""驱邪"等迷信内容 | 《网络安全法》《网络信息内容生态治理规定》 |
| **敲诈勒索** | 以"不化解会有灾"等威胁手段索财 | 《刑法》第274条 |
| **个人信息** | 泄露用户生辰八字、联系方式 | 《个人信息保护法》 |

### 11.3 需要办理的证照

```
1. ICP备案（阿里云已自动完成）→ www.bobolovesu.cn 已备案
2. 如涉及付费信息服务 → 可能需要 ICP许可证（经营性互联网信息服务）
3. 如用户量较大 → 建议办理《网络文化经营许可证》或咨询当地网信办
```

**初期建议**：先以"传统文化交流""学术研究"定位，避免以"算命""占卜预测"等表述宣传。

### 11.4 用户协议（必含条款）

```
1. 免责声明：明确说明解卦结果仅供娱乐参考，不构成任何决策建议
2. 知识产权：明确解卦内容的版权归属
3. 用户行为规范：禁止发布违反法律法规的内容
4. 隐私保护：明确收集哪些个人信息及用途
5. 纠纷处理：明确拒绝/退款/仲裁规则
6. 未成年人保护：限制未成年人使用付费功能
```

### 11.5 投诉举报应对策略

| 场景 | 应对措施 |
|------|---------|
| **用户投诉解卦不准** | 已明确声明"仅供娱乐参考"，可在用户协议中强化此条款 |
| **用户举报诈骗** | 确保平台不承诺结果、不保证准确性，资金由平台托管 |
| **监管部门问询** | 准备平台定位说明（传统文化研究/学术交流），非"算命" |
| **12315投诉** | 建立客服响应机制，保留完整的交易和沟通记录 |
| **网信办审查** | 建立内容审核机制，敏感词过滤（"改运""消灾""驱邪"等） |

### 11.6 关键规避措施

1. **定位表述**：所有宣传材料使用"传统文化研究""易学交流""六爻学术探讨"，避免"算命""占卜预测"
2. **结果免责**：每条解卦结果末尾自动添加"本结果仅供学术参考，不构成任何实际建议"
3. **不保证结果**：严禁卦师承诺"必中""一定""保证"，违者封号
4. **资金安全**：平台作为第三方担保，非投资理财，无资金池
5. **数据合规**：用户八字/排盘数据加密存储，不用于其他商业目的
6. **内容审核**：自动+人工审核解卦内容，屏蔽违法/迷信言论

---

## 十二、几点建议

1. **先不做即时通讯**：初期以站内通知+评论形式即可，避免 WebSocket 复杂度
2. **资金托管**：平台作为中间担保，用户确认后资金才释放给卦师
3. **纠纷处理**：如果求助者不确认/卦师不履约，设计仲裁流程（管理员介入）
4. **内容审核**：解卦内容先审后发（或举报后审），避免法律风险
5. **冷启动**：初期可以邀请现有六爻助手的活跃用户入驻，提供免费解卦积累案例
