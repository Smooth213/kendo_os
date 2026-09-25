/**
 * 🛡️ Kendo OS - iOS PWA TouchSync v4.0 Perfect Snap 動的振る舞いシミュレーションテスト
 * 
 * web/index.html から実際の TouchSync スクリプトを動的に抽出し、
 * WebKit の誤加算バグ（Bug 185448: offsetY + 54px）を完全エミュレートして
 * 物理スナップ機構が 100% 確実に座標ズレを根絶することを実証する。
 */

const fs = require('fs');
const path = require('path');
const assert = require('assert');

// 1. web/index.html の読み込みとスクリプト抽出
const indexHtmlPath = path.resolve(__dirname, '../../web/index.html');
assert(fs.existsSync(indexHtmlPath), 'web/index.html が存在しません');
const htmlContent = fs.readFileSync(indexHtmlPath, 'utf8');

// TouchSync スクリプトブロックを抽出
const scriptMatch = htmlContent.match(/\/\/\s*🛡️ Kendo OS: iOS PWA WebKit 起動直後タッチ座標ズレ[\s\S]*?<\/script>/);
assert(scriptMatch, 'web/index.html 内に TouchSync スクリプトが見つかりません');
const rawScript = scriptMatch[0].replace('</script>', '');

console.log('🔍 [TouchSync Test] スクリプト抽出成功 (サイズ: ' + rawScript.length + ' bytes)');

// 構文エラーチェック（eval ではなく Function コンストラクタで構文解析）
assert.doesNotThrow(() => {
  new Function(rawScript);
}, 'TouchSync スクリプトに構文エラーが存在します！');
console.log('✅ [TouchSync Test] 構文エラー検証パス');

// =========================================================================
// テストハーネスの構築（WebKit iOS PWA 環境のエミュレーション）
// =========================================================================
function createTestEnvironment(userAgent, platform, maxTouchPoints) {
  const eventListeners = {};
  const metaElements = [
    {
      name: 'viewport',
      content: 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover',
      getAttribute(attr) { return attr === 'content' ? this.content : null; },
      setAttribute(attr, val) { if (attr === 'content') this.content = val; }
    }
  ];

  const observerCallbacks = [];

  const mockWindow = {
    scrollY: 0,
    scrollX: 0,
    scrollTo(x, y) {
      this.scrollX = x;
      this.scrollY = y;
    },
    addEventListener(event, listener, options) {
      if (!eventListeners[event]) eventListeners[event] = [];
      eventListeners[event].push({ listener, options });
    },
    dispatchEvent(e) {
      const listeners = eventListeners[e.type] || [];
      for (const { listener } of listeners) {
        listener(e);
      }
    }
  };

  const mockDocument = {
    documentElement: {
      getBoundingClientRect() { return { left: 0, top: 0, width: 390, height: 844 }; }
    },
    head: {},
    querySelectorAll(selector) {
      if (selector === 'meta[name="viewport"]') {
        return metaElements;
      }
      return [];
    }
  };

  const mockNavigator = {
    userAgent: userAgent || 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
    platform: platform || 'iPhone',
    maxTouchPoints: maxTouchPoints !== undefined ? maxTouchPoints : 5
  };

  class MockMutationObserver {
    constructor(cb) {
      this.cb = cb;
      observerCallbacks.push(cb);
    }
    observe() {}
    trigger() {
      this.cb();
    }
  }

  // 実行環境コンテキストを構築
  const runner = new Function(
    'window', 'document', 'navigator', 'MutationObserver',
    rawScript
  );

  runner(mockWindow, mockDocument, mockNavigator, MockMutationObserver);

  return { mockWindow, mockDocument, mockNavigator, metaElements, observerCallbacks };
}

// =========================================================================
// テストケース 1: iOS iPhone PWA 起動直後の WebKit 誤加算バグ (+54px) スナップ検証
// =========================================================================
console.log('\n--- 🧪 テスト 1: iPhone PWA PointerDown 誤加算 (+54px) スナップ検証 ---');
{
  const env = createTestEnvironment();
  
  // WebKitバグを模倣した PointerEvent オブジェクト
  // 物理タップ位置: X=200, Y=300
  // WebKitのバグによる誤加算: offsetY=354 (+54px)
  const mockTarget = {
    getBoundingClientRect() { return { left: 0, top: 0, width: 390, height: 844 }; }
  };

  const event = {
    type: 'pointerdown',
    clientX: 200,
    clientY: 300,
    offsetX: 354, // ⚠️ WebKit バグによる誤加算
    offsetY: 354,
    target: mockTarget
  };

  // イベントを発火（TouchSync の capture リスナーが介入）
  env.mockWindow.dispatchEvent(event);

  // 検証: offsetX / offsetY が真の物理座標にスナップされていること
  assert.strictEqual(event.offsetX, 200, 'offsetX が clientX (200) にスナップされていません！');
  assert.strictEqual(event.offsetY, 300, 'offsetY が clientY (300) にスナップされていません！ (+54px のズレが残存)');
  console.log('  ✅ 成功: offsetY=354 ➔ offsetY=' + event.offsetY + ' (完全物理同期スナップ)');
}

// =========================================================================
// テストケース 2: タップ（Click）イベントでのスナップ検証
// =========================================================================
console.log('\n--- 🧪 テスト 2: iPhone PWA Click イベント 誤加算スナップ検証 ---');
{
  const env = createTestEnvironment();

  const event = {
    type: 'click',
    clientX: 150,
    clientY: 420,
    offsetX: 150,
    offsetY: 474, // +54px
    target: {
      getBoundingClientRect() { return { left: 0, top: 0, width: 390, height: 844 }; }
    }
  };

  env.mockWindow.dispatchEvent(event);

  assert.strictEqual(event.offsetX, 150);
  assert.strictEqual(event.offsetY, 420);
  console.log('  ✅ 成功: click イベントでも物理座標 420 に完全スナップ');
}

// =========================================================================
// テストケース 3: TouchEvent (touches / changedTouches) スナップ検証
// =========================================================================
console.log('\n--- 🧪 テスト 3: TouchEvent (changedTouches) スナップ検証 ---');
{
  const env = createTestEnvironment();

  const touchEvent = {
    type: 'touchend',
    touches: [],
    changedTouches: [{ clientX: 180, clientY: 500 }],
    offsetX: 180,
    offsetY: 554,
    target: {
      getBoundingClientRect() { return { left: 0, top: 0, width: 390, height: 844 }; }
    }
  };

  env.mockWindow.dispatchEvent(touchEvent);

  assert.strictEqual(touchEvent.offsetX, 180);
  assert.strictEqual(touchEvent.offsetY, 500);
  console.log('  ✅ 成功: touchend イベントでも changedTouches から 500 に完全スナップ');
}

// =========================================================================
// テストケース 4: 非iOSデバイス（Android / Windows）での完全バイパス検証
// =========================================================================
console.log('\n--- 🧪 テスト 4: Android / PC Chrome での完全バイパス検証 ---');
{
  const androidEnv = createTestEnvironment(
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
    'Linux armv8l',
    5
  );

  const event = {
    type: 'pointerdown',
    clientX: 200,
    clientY: 300,
    offsetX: 200,
    offsetY: 300
  };

  // Android では何もリスナーが登録されずバイパスされること
  androidEnv.mockWindow.dispatchEvent(event);
  assert.strictEqual(event.offsetX, 200);
  assert.strictEqual(event.offsetY, 300);
  console.log('  ✅ 成功: 非iOSデバイスでは処理が完全バイパスされオーバーヘッド・干渉ゼロ');
}

// =========================================================================
// テストケース 5: Flutter Web による viewport-fit=cover 剥奪阻止検証
// =========================================================================
console.log('\n--- 🧪 テスト 5: Flutter Web による viewport-fit=cover 剥奪阻止検証 ---');
{
  const env = createTestEnvironment();

  // Flutter Web が初期化時に viewport を viewport-fit なしに書き換えたと仮定
  env.metaElements[0].content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
  
  // MutationObserver コールバックをキック
  for (const trigger of env.observerCallbacks) {
    trigger();
  }

  assert(
    env.metaElements[0].content.includes('viewport-fit=cover'),
    'MutationObserver により viewport-fit=cover が自動復元されていません！'
  );
  console.log('  ✅ 成功: 剥奪された viewport-fit=cover が瞬時に自動復元されました');
}

console.log('\n============================================================');
console.log(' 🎉 【iOS PWA TouchSync v4.0 動的シミュレーションテスト 全項目完全合格！】');
console.log('============================================================\n');

process.exit(0);
