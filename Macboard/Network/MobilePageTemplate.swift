import Foundation

/// 手机端 PWA 页面模板
struct MobilePageTemplate {
    
    static let html = """
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <meta name="apple-mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
        <title>Macboard 同步</title>
        <style>
            * {
                box-sizing: border-box;
                margin: 0;
                padding: 0;
            }
            
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif;
                background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
                min-height: 100vh;
                display: flex;
                flex-direction: column;
                color: #fff;
                padding: 16px;
                padding-top: env(safe-area-inset-top, 16px);
                padding-bottom: env(safe-area-inset-bottom, 16px);
            }
            
            .header {
                display: flex;
                align-items: center;
                justify-content: space-between;
                margin-bottom: 12px;
            }
            
            .header-left {
                display: flex;
                align-items: center;
                gap: 8px;
            }
            
            .header h1 {
                font-size: 20px;
                font-weight: 600;
                background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
            }
            
            .connection-status {
                display: flex;
                align-items: center;
                gap: 4px;
                padding: 4px 10px;
                border-radius: 12px;
                font-size: 11px;
            }
            
            .connection-status.connected {
                background: rgba(74, 222, 128, 0.2);
                color: #4ade80;
            }
            
            .connection-status.disconnected {
                background: rgba(248, 113, 113, 0.2);
                color: #f87171;
            }
            
            .connection-status.checking {
                background: rgba(251, 191, 36, 0.2);
                color: #fbbf24;
            }
            
            .status-dot {
                width: 6px;
                height: 6px;
                border-radius: 50%;
                background: currentColor;
            }
            
            .status-dot.pulse {
                animation: pulse 1.5s infinite;
            }
            
            @keyframes pulse {
                0%, 100% { opacity: 1; }
                50% { opacity: 0.4; }
            }
            
            .input-section {
                display: flex;
                flex-direction: column;
                gap: 8px;
            }
            
            textarea {
                min-height: 120px;
                max-height: 180px;
                padding: 14px;
                border: none;
                border-radius: 12px;
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                -webkit-backdrop-filter: blur(10px);
                color: #fff;
                font-size: 16px;
                line-height: 1.5;
                resize: none;
                outline: none;
                transition: all 0.3s ease;
            }
            
            textarea::placeholder {
                color: rgba(255, 255, 255, 0.4);
            }
            
            textarea:focus {
                background: rgba(255, 255, 255, 0.15);
                box-shadow: 0 0 0 2px rgba(102, 126, 234, 0.5);
            }
            
            .button-container {
                display: flex;
                gap: 8px;
            }
            
            button {
                padding: 12px 16px;
                border: none;
                border-radius: 10px;
                font-size: 15px;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.2s ease;
            }
            
            .send-btn {
                flex: 1;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: #fff;
                box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
            }
            
            .send-btn:active {
                transform: scale(0.98);
            }
            
            .send-btn:disabled {
                opacity: 0.6;
                cursor: not-allowed;
            }
            
            .clear-btn {
                background: rgba(255, 255, 255, 0.1);
                color: rgba(255, 255, 255, 0.8);
                padding: 12px 20px;
            }
            
            .clear-btn:active {
                background: rgba(255, 255, 255, 0.15);
            }
            
            .status {
                margin-top: 8px;
                text-align: center;
                font-size: 13px;
                min-height: 18px;
            }
            
            .status.success { color: #4ade80; }
            .status.error { color: #f87171; }
            
            .history {
                margin-top: 16px;
                flex: 1;
                display: flex;
                flex-direction: column;
                min-height: 0;
            }
            
            .history-header {
                display: flex;
                align-items: center;
                justify-content: space-between;
                margin-bottom: 8px;
            }
            
            .history-title {
                font-size: 13px;
                color: rgba(255, 255, 255, 0.5);
            }
            
            .clear-history-btn {
                padding: 4px 10px;
                font-size: 11px;
                background: rgba(248, 113, 113, 0.15);
                color: #f87171;
                border-radius: 6px;
            }
            
            .clear-history-btn:active {
                background: rgba(248, 113, 113, 0.25);
            }
            
            .history-list {
                flex: 1;
                display: flex;
                flex-direction: column;
                gap: 6px;
                overflow-y: auto;
                -webkit-overflow-scrolling: touch;
            }
            
            .history-item {
                padding: 10px 12px;
                background: rgba(255, 255, 255, 0.06);
                border-radius: 8px;
                font-size: 13px;
                color: rgba(255, 255, 255, 0.75);
                white-space: nowrap;
                overflow: hidden;
                text-overflow: ellipsis;
                cursor: pointer;
                transition: background 0.2s ease;
                flex-shrink: 0;
            }
            
            .history-item:active {
                background: rgba(255, 255, 255, 0.12);
            }
            
            .empty-history {
                text-align: center;
                padding: 20px;
                color: rgba(255, 255, 255, 0.3);
                font-size: 13px;
            }
        </style>
    </head>
    <body>
        <div class="header">
            <div class="header-left">
                <h1>📋 Macboard</h1>
            </div>
            <div class="connection-status checking" id="connectionStatus">
                <span class="status-dot pulse"></span>
                <span id="connectionText">检测中</span>
            </div>
        </div>
        
        <div class="input-section">
            <textarea id="content" placeholder="输入要同步的文本..."></textarea>
            <div class="button-container">
                <button class="clear-btn" onclick="clearInput()">清空</button>
                <button class="send-btn" id="sendBtn" onclick="sendContent()">发送到 Mac</button>
            </div>
        </div>
        
        <div class="status" id="status"></div>
        
        <div class="history" id="historySection">
            <div class="history-header">
                <span class="history-title">最近发送</span>
                <button class="clear-history-btn" onclick="clearHistory()">清除</button>
            </div>
            <div class="history-list" id="historyList"></div>
        </div>
        
        <script>
            const textarea = document.getElementById('content');
            const sendBtn = document.getElementById('sendBtn');
            const status = document.getElementById('status');
            const historySection = document.getElementById('historySection');
            const historyList = document.getElementById('historyList');
            
            let history = JSON.parse(localStorage.getItem('macboard_history') || '[]');
            renderHistory();
            
            const connectionStatus = document.getElementById('connectionStatus');
            const connectionText = document.getElementById('connectionText');
            
            async function checkConnection() {
                try {
                    const response = await fetch('/sync', {
                        method: 'OPTIONS',
                        signal: AbortSignal.timeout(3000)
                    });
                    setConnected(response.ok || response.status === 204);
                } catch (error) {
                    setConnected(false);
                }
            }
            
            function setConnected(connected) {
                const dot = connectionStatus.querySelector('.status-dot');
                if (connected) {
                    connectionStatus.className = 'connection-status connected';
                    connectionText.textContent = '已连接';
                    dot.classList.remove('pulse');
                } else {
                    connectionStatus.className = 'connection-status disconnected';
                    connectionText.textContent = '未连接';
                    dot.classList.add('pulse');
                }
            }
            
            checkConnection();
            setInterval(checkConnection, 5000);
            
            async function sendContent() {
                const content = textarea.value.trim();
                if (!content) {
                    showStatus('请输入内容', 'error');
                    return;
                }
                
                sendBtn.disabled = true;
                sendBtn.textContent = '发送中...';
                
                try {
                    const response = await fetch('/sync', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ content })
                    });
                    
                    const result = await response.json();
                    
                    if (result.success) {
                        showStatus('✓ 已同步', 'success');
                        addToHistory(content);
                        textarea.value = '';
                    } else {
                        showStatus('失败: ' + (result.error || '未知错误'), 'error');
                    }
                } catch (error) {
                    showStatus('连接失败', 'error');
                }
                
                sendBtn.disabled = false;
                sendBtn.textContent = '发送到 Mac';
            }
            
            function clearInput() {
                textarea.value = '';
                textarea.focus();
            }
            
            function showStatus(message, type) {
                status.textContent = message;
                status.className = 'status ' + type;
                
                if (type === 'success') {
                    setTimeout(() => {
                        status.textContent = '';
                        status.className = 'status';
                    }, 2000);
                }
            }
            
            function addToHistory(content) {
                history = history.filter(item => item !== content);
                history.unshift(content);
                history = history.slice(0, 10);
                localStorage.setItem('macboard_history', JSON.stringify(history));
                renderHistory();
            }
            
            function clearHistory() {
                if (confirm('确定清除所有历史记录？')) {
                    history = [];
                    localStorage.removeItem('macboard_history');
                    renderHistory();
                }
            }
            
            function renderHistory() {
                if (history.length === 0) {
                    historyList.innerHTML = '<div class="empty-history">暂无记录</div>';
                    return;
                }
                
                historyList.innerHTML = history.map(item => 
                    `<div class="history-item" onclick="fillFromHistory(this)">${escapeHtml(item)}</div>`
                ).join('');
            }
            
            function fillFromHistory(el) {
                textarea.value = el.textContent;
                textarea.focus();
            }
            
            function escapeHtml(text) {
                const div = document.createElement('div');
                div.textContent = text;
                return div.innerHTML;
            }
            
            textarea.addEventListener('keydown', function(e) {
                if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                    e.preventDefault();
                    sendContent();
                }
            });
        </script>
    </body>
    </html>
    """
}
