/**
 * 六爻助手 服务端 v2
 * - SQLite 存储（替代 JSON 文件）
 * - 解锁申请/审批流程
 * - AES-256-GCM 加密备注
 * - SHA256 设备ID哈希
 *
 * 保留所有原有功能：更新分发、在线验证码验证、管理员生成验证码
 */
const express = require('express');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');
const app = express();

app.use(express.json());

// ==================== 配置 ====================
const CONFIG = {
  port: process.env.PORT || 3456,
  adminKey: process.env.ADMIN_KEY || 'LiyaoAdmin_Secret_2026',
  secretKey: 'LiuYaoAssistant-2026-KeyCode',
  // AES 加密密钥（用于加密备注，不同于 HMAC 密钥）
  encryptKey: process.env.ENCRYPT_KEY || 'LiyaoEncrypt_2026',
  dataDir: path.join(__dirname, 'data'),
  apkDir: path.join(__dirname, 'public', 'apk'),
};

// ==================== 当前版本 ====================
const CURRENT_VERSION = {
  version: '1.2.3',
  buildNumber: 65,
  url: '/apk/liuyao-assistant.apk',
  md5: '803c80d9d28ce4454f1d9be610beeb98',
  description: '解锁申请流程 + SQLite存储',
  forceUpdate: false,
};

// ==================== 加密工具 ====================

/** SHA256 哈希（用于设备ID） */
function sha256(input) {
  return crypto.createHash('sha256').update(input).digest('hex');
}

/** AES-256-GCM 加密（用于备注） */
function encrypt(text) {
  const key = crypto.scryptSync(CONFIG.encryptKey, 'liuyao_salt', 32);
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const authTag = cipher.getAuthTag().toString('hex');
  // 返回 iv:authTag:ciphertext
  return `${iv.toString('hex')}:${authTag}:${encrypted}`;
}

/** AES-256-GCM 解密 */
function decrypt(encryptedStr) {
  try {
    const parts = encryptedStr.split(':');
    if (parts.length !== 3) return null;
    const key = crypto.scryptSync(CONFIG.encryptKey, 'liuyao_salt', 32);
    const decipher = crypto.createDecipheriv('aes-256-gcm', key, Buffer.from(parts[0], 'hex'));
    decipher.setAuthTag(Buffer.from(parts[1], 'hex'));
    let decrypted = decipher.update(parts[2], 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch { return null; }
}

// ==================== 数据库 ====================

const DB_PATH = path.join(CONFIG.dataDir, 'liuyao.db');
let db;

function initDatabase() {
  // 确保 data 目录存在
  if (!fs.existsSync(CONFIG.dataDir)) {
    fs.mkdirSync(CONFIG.dataDir, { recursive: true });
  }

  db = new Database(DB_PATH);
  
  // 启用 WAL 模式（更好的并发性能）
  db.pragma('journal_mode = WAL');

  // 解锁申请表
  db.exec(`
    CREATE TABLE IF NOT EXISTS unlock_requests (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      device_hash TEXT NOT NULL,
      applicant_ip TEXT,
      remark_encrypted TEXT,
      status TEXT DEFAULT 'pending',
      features TEXT,
      code TEXT,
      expire_date TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      processed_at TEXT,
      admin_note TEXT,
      UNIQUE(device_hash)
    )
  `);

  // 已用验证码表（替代 JSON 存储）
  db.exec(`
    CREATE TABLE IF NOT EXISTS used_codes (
      code TEXT PRIMARY KEY,
      device_id TEXT,
      features TEXT,
      expire_date TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `);

  // 设备解锁记录表
  db.exec(`
    CREATE TABLE IF NOT EXISTS device_unlocks (
      device_hash TEXT PRIMARY KEY,
      features TEXT,
      expire_date TEXT,
      unlocked_at TEXT DEFAULT (datetime('now'))
    )
  `);

  console.log('✅ SQLite 数据库初始化完成');
}

// ==================== HMAC 验证码算法 ====================

function generateCode(deviceId, featureCode, expireDate) {
  const data = `${deviceId}|${featureCode}|${expireDate}`;
  const hmac = crypto.createHmac('sha256', CONFIG.secretKey);
  hmac.update(data);
  return hmac.digest('hex').substring(0, 8).toUpperCase();
}

// ==================== API 路由 ====================

// ---- 1. 检查更新 ----
app.get('/api/check_update', (req, res) => {
  const apkPath = path.join(CONFIG.apkDir, 'liuyao-assistant.apk');
  let apkSize = 0;
  try { apkSize = fs.statSync(apkPath).size; } catch (_) {}

  res.json({
    success: true,
    data: { ...CURRENT_VERSION, apkSize },
  });
});

// ---- 2. 在线验证解锁码 ----
app.post('/api/verify_code', (req, res) => {
  const { deviceId, code } = req.body;
  if (!deviceId || !code) {
    return res.json({ success: false, message: '参数不完整' });
  }

  const deviceHash = sha256(deviceId);

  // 尝试各种可能的功能代码组合
  const features = ['F005', 'F006', 'F007'];
  const allCodes = features.join(',');
  const tryCodes = [...features, allCodes];
  const now = new Date();

  for (const fc of tryCodes) {
    for (let y = now.getFullYear(); y <= 2099; y++) {
      for (let m = 1; m <= 12; m++) {
        const dim = m === 2
          ? (y % 4 === 0 && (y % 100 !== 0 || y % 400 === 0) ? 29 : 28)
          : [1,3,5,7,8,10,12].includes(m) ? 31 : 30;
        for (let d = 1; d <= dim; d++) {
          const ds = `${y}${String(m).padStart(2,'0')}${String(d).padStart(2,'0')}`;
          if (generateCode(deviceId, fc, ds) === code) {
            const expireDt = new Date(y, m-1, d+1);
            if (now < expireDt) {
              const matchedFeatures = fc === allCodes ? features : [fc];
              // 记录
              recordUnlock(deviceHash, matchedFeatures, ds);
              try { saveUsedCode(code, deviceId, matchedFeatures, ds); } catch(_){}
              return res.json({ success: true, data: { valid: true, features: matchedFeatures, expireDate: ds } });
            }
            return res.json({ success: true, data: { valid: false, message: '验证码已过期' } });
          }
        }
      }
    }
  }

  // 4. 尝试查询 used_codes 表（兼容审批生成的随机码）
  try {
    const codeRecord = db.prepare('SELECT features, expire_date FROM used_codes WHERE code = ?').get(code);
    if (codeRecord) {
      const expireDt = new Date(parseInt(codeRecord.expire_date.substring(0,4)), 
        parseInt(codeRecord.expire_date.substring(4,6))-1,
        parseInt(codeRecord.expire_date.substring(6,8))+1);
      if (new Date() < expireDt) {
        const matchedFeatures = JSON.parse(codeRecord.features);
        recordUnlock(deviceHash, matchedFeatures, codeRecord.expire_date);
        return res.json({ success: true, data: { valid: true, features: matchedFeatures, expireDate: codeRecord.expire_date } });
      }
    }
  } catch(_) {}

  res.json({ success: true, data: { valid: false, message: '验证码无效' } });
});

// ---- 3. 管理员生成验证码 ----
app.post('/api/generate_code', (req, res) => {
  const { adminKey, deviceId, features, expireDate } = req.body;
  if (adminKey !== CONFIG.adminKey) {
    return res.status(403).json({ success: false, message: '管理员密钥错误' });
  }
  if (!deviceId || !features || !features.length || !expireDate) {
    return res.json({ success: false, message: '参数不完整' });
  }

  const featureCode = features.join(',');
  const code = generateCode(deviceId, featureCode, expireDate);
  
  try { saveUsedCode(code, deviceId, features, expireDate); } catch(_){}

  res.json({ success: true, data: { code, deviceId, features, expireDate } });
});

// ---- 4. 查询设备解锁状态 ----
app.get('/api/device_status', (req, res) => {
  const { deviceId } = req.query;
  if (!deviceId) return res.json({ success: false, message: '缺少deviceId' });
  const deviceHash = sha256(deviceId);
  const record = db.prepare('SELECT features, expire_date, unlocked_at FROM device_unlocks WHERE device_hash = ?').get(deviceHash);
  res.json({ success: true, data: record || null });
});

// ==================== 新增 API：解锁申请流程 ====================

// ---- 5. 用户提交解锁申请 ----
app.post('/api/submit_request', (req, res) => {
  const { deviceId, remark } = req.body;
  if (!deviceId) {
    return res.json({ success: false, message: '缺少设备ID' });
  }

  const deviceHash = sha256(deviceId);
  const applicantIp = req.ip || req.connection?.remoteAddress || '';
  // IP 截取前 24 位保护隐私，如 "182.92.214.x"
  const maskedIp = applicantIp.split('.').slice(0, 3).join('.') + '.x';
  
  // 备注加密存储
  const remarkEncrypted = remark ? encrypt(remark.substring(0, 200)) : '';

  try {
    // 如果已有待处理的申请，返回已有记录
    const existing = db.prepare('SELECT id, status FROM unlock_requests WHERE device_hash = ?').get(deviceHash);
    if (existing && existing.status === 'pending') {
      return res.json({ success: true, data: { message: '已存在待处理的申请', requestId: existing.id } });
    }
    if (existing && existing.status === 'approved') {
      const unlock = db.prepare('SELECT features, expire_date FROM device_unlocks WHERE device_hash = ?').get(deviceHash);
      return res.json({ success: true, data: { message: '该设备已解锁', approved: true, features: unlock?.features, expireDate: unlock?.expire_date } });
    }

    const stmt = db.prepare(
      'INSERT OR REPLACE INTO unlock_requests (device_hash, applicant_ip, remark_encrypted, status) VALUES (?, ?, ?, ?)'
    );
    const result = stmt.run(deviceHash, maskedIp, remarkEncrypted, 'pending');
    
    res.json({ success: true, data: { requestId: result.lastInsertRowid, message: '申请已提交，请等待管理员审批' } });
  } catch (e) {
    res.json({ success: false, message: '提交失败，请稍后重试' });
  }
});

// ---- 6. 管理员查看待审批申请 ----
app.get('/api/pending_requests', (req, res) => {
  const { adminKey, status } = req.query;
  if (adminKey !== CONFIG.adminKey) {
    return res.status(403).json({ success: false, message: '管理员密钥错误' });
  }

  const filterStatus = status || 'pending';
  const rows = db.prepare(
    'SELECT id, device_hash, applicant_ip, remark_encrypted, status, created_at FROM unlock_requests WHERE status = ? ORDER BY created_at DESC'
  ).all(filterStatus);

  // 解密备注（仅管理员可查看）
  const data = rows.map(row => ({
    id: row.id,
    deviceHash: row.device_hash,
    applicantIp: row.applicant_ip,
    remark: row.remark_encrypted ? decrypt(row.remark_encrypted) : '',
    status: row.status,
    createdAt: row.created_at,
  }));

  res.json({ success: true, data });
});

// ---- 7. 管理员审批解锁申请 ----
app.post('/api/approve_request', (req, res) => {
  const { adminKey, requestId, features, expireDate } = req.body;
  if (adminKey !== CONFIG.adminKey) {
    return res.status(403).json({ success: false, message: '管理员密钥错误' });
  }
  if (!requestId || !features || !features.length || !expireDate) {
    return res.json({ success: false, message: '参数不完整' });
  }

  // 获取申请记录
  const request = db.prepare('SELECT * FROM unlock_requests WHERE id = ?').get(requestId);
  if (!request) {
    return res.json({ success: false, message: '申请记录不存在' });
  }

  // 生成解锁码（需要原始设备ID，但这里只有哈希）
  // 方案：生成一个基于 requestId + 时间戳的验证码
  // 实际上用户需要手动输入设备ID + 生成的验证码
  // 所以这里使用 requestId 的特征生成一个关联码
  
  // 由于我们只有 device_hash（没有原始 deviceId），无法用标准 HMAC 生成验证码
  // 两种方案：
  // 1. 管理员手动输入用户提供的设备ID（在管理员工具中输入）
  // 2. 服务器生成一个随机码并关联到 device_hash
  
  // 采用方案2：生成随机码，存储到数据库，用户通过 check_request_status 自动获取
  const randomCode = crypto.randomBytes(4).toString('hex').toUpperCase();
  const featureCode = features.join(',');

  // 更新申请状态
  const stmt = db.prepare(
    'UPDATE unlock_requests SET status = ?, features = ?, code = ?, expire_date = ?, processed_at = datetime(\'now\') WHERE id = ?'
  );
  stmt.run('approved', featureCode, randomCode, expireDate, requestId);

  // 记录设备解锁
  recordUnlock(request.device_hash, features, expireDate);
  try { saveUsedCode(randomCode, null, features, expireDate); } catch(_){}

  res.json({ success: true, data: { 
    code: randomCode, 
    features, 
    expireDate,
    message: '审批通过，验证码已生成' 
  }});
});

// ---- 8. 用户检查申请状态 ----
app.get('/api/check_request_status', (req, res) => {
  const { deviceId } = req.query;
  if (!deviceId) return res.json({ success: false, message: '缺少deviceId' });

  const deviceHash = sha256(deviceId);
  const request = db.prepare('SELECT status, code, features, expire_date FROM unlock_requests WHERE device_hash = ?').get(deviceHash);

  if (!request) {
    return res.json({ success: true, data: { status: 'none', message: '未找到申请记录' } });
  }

  if (request.status === 'approved' && request.code) {
    return res.json({ success: true, data: { 
      status: 'approved', 
      code: request.code, 
      features: request.features,
      expireDate: request.expire_date,
    }});
  }

  if (request.status === 'rejected') {
    return res.json({ success: true, data: { status: 'rejected', message: '申请未通过' } });
  }

  res.json({ success: true, data: { status: 'pending', message: '申请审批中，请耐心等待' } });
});

// ==================== 辅助函数 ====================

function saveUsedCode(code, deviceId, features, expireDate) {
  db.prepare(
    'INSERT OR IGNORE INTO used_codes (code, device_id, features, expire_date) VALUES (?, ?, ?, ?)'
  ).run(code, deviceId, JSON.stringify(features), expireDate);
}

function recordUnlock(deviceHash, features, expireDate) {
  db.prepare(
    'INSERT OR REPLACE INTO device_unlocks (device_hash, features, expire_date, unlocked_at) VALUES (?, ?, ?, datetime(\'now\'))'
  ).run(deviceHash, JSON.stringify(features), expireDate);
}

// ---- 9. 更新配置（adminKey / secretKey）----
app.post('/api/update_config', (req, res) => {
  const { adminKey, currentPassword, newAdminKey, newSecretKey } = req.body;
  if (adminKey !== CONFIG.adminKey) {
    return res.status(403).json({ success: false, message: '管理员密钥错误' });
  }
  if (currentPassword !== CONFIG.adminKey) {
    return res.json({ success: false, message: '当前密钥验证失败' });
  }

  const changes = {};
  if (newAdminKey) {
    if (newAdminKey.length < 8) return res.json({ success: false, message: '新管理员密钥至少8位' });
    db.prepare('INSERT OR REPLACE INTO app_config (key, value) VALUES (?, ?)').run('adminKey', newAdminKey);
    CONFIG.adminKey = newAdminKey;
    changes.adminKeyChanged = true;
  }
  if (newSecretKey) {
    if (newSecretKey.length < 8) return res.json({ success: false, message: '新解锁码密钥至少8位' });
    db.prepare('INSERT OR REPLACE INTO app_config (key, value) VALUES (?, ?)').run('secretKey', newSecretKey);
    CONFIG.secretKey = newSecretKey;
    changes.secretKeyChanged = true;
  }

  res.json({ success: true, message: '配置已更新，即时生效', data: changes });
});


// ==================== 静态文件 ====================

app.use('/apk', express.static(CONFIG.apkDir));

// ==================== 启动 ====================

initDatabase();

app.listen(CONFIG.port, '0.0.0.0', () => {
  console.log(`✅ 六爻助手服务端 v2 运行中 http://0.0.0.0:${CONFIG.port}`);
  console.log(`   数据库: ${DB_PATH}`);
  console.log(`   APK目录: ${CONFIG.apkDir}`);
});
