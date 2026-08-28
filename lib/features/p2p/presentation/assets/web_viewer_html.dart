/// 【Phase 5: P2P Web配信】ブラウザで表示される超軽量リアルタイムスコアボードHTML
class WebViewHtml {
  static String build({required String hostIp, required int port}) {
    return '''
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>kendo OS - リアルタイム観戦ビュアー</title>
  <style>
    :root {
      --bg: #121214;
      --card-bg: #1C1C1E;
      --text: #FFFFFF;
      --subtext: #8E8E93;
      --red: #E02424;
      --white: #FFFFFF;
      --gold: #FFD700;
      --accent: #3F51B5;
    }
    body {
      margin: 0;
      padding: 16px;
      background-color: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      box-sizing: border-box;
      display: flex;
      flex-direction: column;
      align-items: center;
      min-height: 100vh;
    }
    .header {
      width: 100%;
      max-width: 600px;
      text-align: center;
      margin-bottom: 16px;
      padding-bottom: 12px;
      border-bottom: 1px solid #2C2C2E;
    }
    .title {
      font-size: 1.2rem;
      font-weight: bold;
      color: var(--gold);
      margin-bottom: 4px;
    }
    .status {
      font-size: 0.85rem;
      color: #34C759;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      background-color: #34C759;
      border-radius: 50%;
      animation: pulse 1.5s infinite;
    }
    @keyframes pulse {
      0% { opacity: 0.4; }
      50% { opacity: 1; }
      100% { opacity: 0.4; }
    }
    .scoreboard {
      width: 100%;
      max-width: 600px;
      background-color: var(--card-bg);
      border-radius: 16px;
      padding: 20px;
      box-sizing: border-box;
      box-shadow: 0 8px 24px rgba(0,0,0,0.5);
      border: 1px solid #2C2C2E;
    }
    .match-info {
      text-align: center;
      font-size: 1rem;
      color: var(--subtext);
      margin-bottom: 16px;
    }
    .battle-grid {
      display: grid;
      grid-template-columns: 1fr auto 1fr;
      align-items: center;
      gap: 12px;
    }
    .side {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 12px;
      border-radius: 12px;
    }
    .side.red {
      background: linear-gradient(180deg, rgba(224, 36, 36, 0.15) 0%, rgba(224, 36, 36, 0.05) 100%);
      border: 1px solid rgba(224, 36, 36, 0.3);
    }
    .side.white {
      background: linear-gradient(180deg, rgba(255, 255, 255, 0.12) 0%, rgba(255, 255, 255, 0.03) 100%);
      border: 1px solid rgba(255, 255, 255, 0.2);
    }
    .team-label {
      font-size: 0.9rem;
      color: var(--subtext);
      margin-bottom: 4px;
    }
    .player-name {
      font-size: 1.3rem;
      font-weight: bold;
      margin-bottom: 12px;
      text-align: center;
    }
    .score {
      font-size: 3.5rem;
      font-weight: 900;
      line-height: 1;
    }
    .score.red-text { color: var(--red); }
    .score.white-text { color: var(--white); }
    .points-badges {
      margin-top: 8px;
      display: flex;
      gap: 4px;
      min-height: 24px;
    }
    .badge {
      background-color: var(--gold);
      color: #000;
      font-size: 0.75rem;
      font-weight: bold;
      padding: 2px 6px;
      border-radius: 4px;
    }
    .vs-divider {
      font-size: 1.5rem;
      font-weight: 900;
      color: var(--subtext);
    }
    .timer-box {
      margin-top: 20px;
      text-align: center;
      padding: 12px;
      background: #121214;
      border-radius: 10px;
      border: 1px solid #2C2C2E;
    }
    .timer {
      font-size: 2.2rem;
      font-weight: bold;
      font-variant-numeric: tabular-nums;
      color: #FFD700;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="title">⚔️ kendo OS リアルタイム観戦</div>
    <div class="status"><div class="status-dot"></div><span id="conn-status">現地記録端末と接続中 (0遅延)</span></div>
  </div>

  <div class="scoreboard">
    <div class="match-info" id="match-info">試合準備中...</div>
    <div class="battle-grid">
      <div class="side red">
        <div class="team-label" id="red-team">赤</div>
        <div class="player-name" id="red-name">選手</div>
        <div class="score red-text" id="red-score">0</div>
        <div class="points-badges" id="red-badges"></div>
      </div>
      <div class="vs-divider">VS</div>
      <div class="side white">
        <div class="team-label" id="white-team">白</div>
        <div class="player-name" id="white-name">選手</div>
        <div class="score white-text" id="white-score">0</div>
        <div class="points-badges" id="white-badges"></div>
      </div>
    </div>
    <div class="timer-box">
      <div class="timer" id="timer-display">03:00</div>
    </div>
  </div>

  <script>
    const wsUrl = "ws://" + location.hostname + ":" + location.port + "/ws";
    let ws;

    function connect() {
      ws = new WebSocket(wsUrl);
      ws.onopen = () => {
        document.getElementById("conn-status").innerText = "現地記録端末と同期中 (リアルタイム)";
      };
      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          updateUI(data);
        } catch (e) { console.error(e); }
      };
      ws.onclose = () => {
        document.getElementById("conn-status").innerText = "再接続中...";
        setTimeout(connect, 1500);
      };
    }

    function updateUI(data) {
      if (data.redName) {
        const rParts = data.redName.split(':');
        document.getElementById("red-team").innerText = rParts[0] || "赤";
        document.getElementById("red-name").innerText = rParts[1] || rParts[0];
      }
      if (data.whiteName) {
        const wParts = data.whiteName.split(':');
        document.getElementById("white-team").innerText = wParts[0] || "白";
        document.getElementById("white-name").innerText = wParts[1] || wParts[0];
      }
      document.getElementById("red-score").innerText = data.redScore ?? 0;
      document.getElementById("white-score").innerText = data.whiteScore ?? 0;
      if (data.matchType) {
        document.getElementById("match-info").innerText = (data.category ? data.category + " - " : "") + data.matchType;
      }
      if (data.remainingSeconds !== undefined) {
        const m = Math.floor(data.remainingSeconds / 60);
        const s = data.remainingSeconds % 60;
        document.getElementById("timer-display").innerText = 
          String(m).padStart(2, '0') + ":" + String(s).padStart(2, '0');
      }
    }

    connect();
  </script>
</body>
</html>
''';
  }
}
