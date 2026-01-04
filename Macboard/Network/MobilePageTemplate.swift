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
                padding: 20px;
                padding-top: env(safe-area-inset-top, 20px);
                padding-bottom: env(safe-area-inset-bottom, 20px);
            }
            
            .header {
                text-align: center;
                margin-bottom: 24px;
            }
            
            .header h1 {
                font-size: 24px;
                font-weight: 600;
                background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                margin-bottom: 8px;
            }
            
            .header p {
                font-size: 14px;
                color: rgba(255, 255, 255, 0.6);
            }
            
            .connection-status {
                display: inline-flex;
                align-items: center;
                gap: 6px;
                padding: 6px 12px;
                border-radius: 20px;
                font-size: 12px;
                margin-top: 12px;
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
                width: 8px;
                height: 8px;
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
            
            .input-container {
                flex: 1;
                display: flex;
                flex-direction: column;
            }
            
            textarea {
                flex: 1;
                min-height: 130px;
                max-height: 200px;
                padding: 16px;
                border: none;
                border-radius: 16px;
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                -webkit-backdrop-filter: blur(10px);
                color: #fff;
                font-size: 16px;
                line-height: 1.6;
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
                margin-top: 16px;
                display: flex;
                gap: 12px;
            }
            
            button {
                flex: 1;
                padding: 16px 24px;
                border: none;
                border-radius: 12px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.3s ease;
            }
            
            .send-btn {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: #fff;
                box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
            }
            
            .send-btn:active {
                transform: scale(0.98);
                box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
            }
            
            .send-btn:disabled {
                opacity: 0.6;
                cursor: not-allowed;
            }
            
            .clear-btn {
                background: rgba(255, 255, 255, 0.1);
                color: rgba(255, 255, 255, 0.8);
                flex: 0.4;
            }
            
            .clear-btn:active {
                background: rgba(255, 255, 255, 0.15);
            }
            
            .status {
                margin-top: 16px;
                text-align: center;
                font-size: 14px;
                min-height: 20px;
            }
            
            .status.success {
                color: #4ade80;
            }
            
            .status.error {
                color: #f87171;
            }
            
            .history {
                margin-top: 24px;
            }
            
            .history-title {
                font-size: 14px;
                color: rgba(255, 255, 255, 0.6);
                margin-bottom: 12px;
            }
            
            .history-list {
                display: flex;
                flex-direction: column;
                gap: 8px;
                max-height: 150px;
                overflow-y: auto;
            }
            
            .history-item {
                padding: 12px;
                background: rgba(255, 255, 255, 0.08);
                border-radius: 8px;
                font-size: 14px;
                color: rgba(255, 255, 255, 0.8);
                white-space: nowrap;
                overflow: hidden;
                text-overflow: ellipsis;
                cursor: pointer;
                transition: background 0.2s ease;
            }
            
            .history-item:active {
                background: rgba(255, 255, 255, 0.15);
            }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>📋 Macboard 同步</h1>
            <p>输入文本后点击发送，即可同步到 Mac 剪贴板</p>
            <div class="connection-status checking" id="connectionStatus">
                <span class="status-dot pulse"></span>
                <span id="connectionText">检测连接中...</span>
            </div>
        </div>
        
        <div class="input-container">
            <textarea id="content" placeholder="在此输入要同步的文本..."></textarea>
        </div>
        
        <div class="button-container">
            <button class="clear-btn" onclick="clearInput()">清空</button>
            <button class="send-btn" id="sendBtn" onclick="sendContent()">发送到 Mac</button>
        </div>
        
        <div class="status" id="status"></div>
        
        <div class="history" id="historySection" style="display: none;">
            <div class="history-title">最近发送</div>
            <div class="history-list" id="historyList"></div>
        </div>
        
        <script>
            const textarea = document.getElementById('content');
            const sendBtn = document.getElementById('sendBtn');
            const status = document.getElementById('status');
            const historySection = document.getElementById('historySection');
            const historyList = document.getElementById('historyList');
            
            // 从 localStorage 加载历史
            let history = JSON.parse(localStorage.getItem('macboard_history') || '[]');
            renderHistory();
            
            // 检查连接状态
            const connectionStatus = document.getElementById('connectionStatus');
            const connectionText = document.getElementById('connectionText');
            let isConnected = false;
            
            async function checkConnection() {
                try {
                    const response = await fetch('/sync', {
                        method: 'OPTIONS',
                        signal: AbortSignal.timeout(3000)
                    });
                    if (response.ok || response.status === 204) {
                        setConnected(true);
                    } else {
                        setConnected(false);
                    }
                } catch (error) {
                    setConnected(false);
                }
            }
            
            function setConnected(connected) {
                isConnected = connected;
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
            
            // 初始检查并定期检查连接
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
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ content })
                    });
                    
                    const result = await response.json();
                    
                    if (result.success) {
                        showStatus('✓ 已同步到 Mac 剪贴板', 'success');
                        addToHistory(content);
                        textarea.value = '';
                    } else {
                        showStatus('发送失败: ' + (result.error || '未知错误'), 'error');
                    }
                } catch (error) {
                    showStatus('连接失败，请确保与 Mac 在同一网络', 'error');
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
                    }, 3000);
                }
            }
            
            function addToHistory(content) {
                // 移除重复项
                history = history.filter(item => item !== content);
                // 添加到开头
                history.unshift(content);
                // 最多保留 10 条
                history = history.slice(0, 10);
                // 保存
                localStorage.setItem('macboard_history', JSON.stringify(history));
                renderHistory();
            }
            
            function renderHistory() {
                if (history.length === 0) {
                    historySection.style.display = 'none';
                    return;
                }
                
                historySection.style.display = 'block';
                historyList.innerHTML = history.map(item => 
                    `<div class="history-item" onclick="fillFromHistory('${escapeHtml(item)}')">${escapeHtml(item)}</div>`
                ).join('');
            }
            
            function fillFromHistory(content) {
                textarea.value = content;
                textarea.focus();
            }
            
            function escapeHtml(text) {
                const div = document.createElement('div');
                div.textContent = text;
                return div.innerHTML.replace(/'/g, "\\\\'");
            }
            
            // 支持 Ctrl+Enter / Cmd+Enter 发送
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
