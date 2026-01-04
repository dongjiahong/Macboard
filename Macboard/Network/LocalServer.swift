import Foundation
import Network
import Cocoa

/// 局域网同步服务器，使用 NWListener 实现轻量级 HTTP 服务器
class LocalSyncServer: ObservableObject {
    
    static let shared = LocalSyncServer()
    
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    
    @Published var isRunning = false
    @Published var serverURL: String?
    @Published var port: UInt16 = 8899
    
    private init() {}
    
    /// 获取本机局域网 IP
    func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                
                // 只查找 IPv4 地址
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    // en0 通常是 WiFi，en1 可能是有线
                    if name == "en0" || name == "en1" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(
                            interface.ifa_addr,
                            socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname,
                            socklen_t(hostname.count),
                            nil,
                            socklen_t(0),
                            NI_NUMERICHOST
                        )
                        address = String(cString: hostname)
                        break
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
    
    /// 启动服务器
    func start() {
        guard !isRunning else { return }
        
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    DispatchQueue.main.async {
                        self?.isRunning = true
                        if let ip = self?.getLocalIPAddress(), let port = self?.port {
                            self?.serverURL = "http://\(ip):\(port)"
                        }
                    }
                    print("[LocalSyncServer] 服务已启动: \(self?.serverURL ?? "")")
                case .failed(let error):
                    print("[LocalSyncServer] 启动失败: \(error)")
                    DispatchQueue.main.async {
                        self?.isRunning = false
                        self?.serverURL = nil
                    }
                case .cancelled:
                    DispatchQueue.main.async {
                        self?.isRunning = false
                        self?.serverURL = nil
                    }
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.start(queue: .global(qos: .userInitiated))
            
        } catch {
            print("[LocalSyncServer] 创建监听器失败: \(error)")
        }
    }
    
    /// 停止服务器
    func stop() {
        listener?.cancel()
        listener = nil
        connections.forEach { $0.cancel() }
        connections.removeAll()
        
        DispatchQueue.main.async {
            self.isRunning = false
            self.serverURL = nil
        }
        print("[LocalSyncServer] 服务已停止")
    }
    
    /// 处理新连接
    private func handleConnection(_ connection: NWConnection) {
        connections.append(connection)
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receiveRequest(connection)
            case .failed, .cancelled:
                self?.removeConnection(connection)
            default:
                break
            }
        }
        
        connection.start(queue: .global(qos: .userInitiated))
    }
    
    /// 从连接中移除
    private func removeConnection(_ connection: NWConnection) {
        connections.removeAll { $0 === connection }
    }
    
    /// 接收 HTTP 请求
    private func receiveRequest(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let data = data, !data.isEmpty {
                if let request = String(data: data, encoding: .utf8) {
                    self.handleHTTPRequest(request, connection: connection)
                }
            }
            
            if isComplete || error != nil {
                self.removeConnection(connection)
            }
        }
    }
    
    /// 处理 HTTP 请求
    private func handleHTTPRequest(_ request: String, connection: NWConnection) {
        let lines = request.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            sendResponse(connection, statusCode: 400, body: "Bad Request")
            return
        }
        
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            sendResponse(connection, statusCode: 400, body: "Bad Request")
            return
        }
        
        let method = parts[0]
        let path = parts[1]
        
        switch (method, path) {
        case ("GET", "/"):
            // 返回手机端 PWA 页面
            let html = MobilePageTemplate.html
            sendResponse(connection, statusCode: 200, contentType: "text/html; charset=utf-8", body: html)
            
        case ("POST", "/sync"):
            // 解析 POST body
            if let bodyStart = request.range(of: "\r\n\r\n") {
                let body = String(request[bodyStart.upperBound...])
                handleSyncRequest(body: body, connection: connection)
            } else {
                sendResponse(connection, statusCode: 400, body: "No body")
            }
            
        case ("OPTIONS", _):
            // 处理 CORS 预检请求
            sendCORSResponse(connection)
            
        default:
            sendResponse(connection, statusCode: 404, body: "Not Found")
        }
    }
    
    /// 处理同步请求
    private func handleSyncRequest(body: String, connection: NWConnection) {
        // 解析 JSON
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? String else {
            sendResponse(connection, statusCode: 400, body: "{\"success\": false, \"error\": \"无效的请求格式\"}")
            return
        }
        
        // 写入系统剪贴板
        DispatchQueue.main.async {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(content, forType: .string)
            
            // 添加到 Macboard 历史记录
            let context = PersistanceController.shared.container.viewContext
            CoreDataManager().addToClipboard(
                content: content,
                contentType: "Text",
                sourceApp: "局域网同步",
                context: context
            )
        }
        
        sendResponse(connection, statusCode: 200, contentType: "application/json", body: "{\"success\": true}")
    }
    
    /// 发送 HTTP 响应
    private func sendResponse(_ connection: NWConnection, statusCode: Int, contentType: String = "text/plain; charset=utf-8", body: String) {
        let statusText: String
        switch statusCode {
        case 200: statusText = "OK"
        case 400: statusText = "Bad Request"
        case 404: statusText = "Not Found"
        default: statusText = "Unknown"
        }
        
        let response = """
        HTTP/1.1 \(statusCode) \(statusText)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.utf8.count)\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Methods: GET, POST, OPTIONS\r
        Access-Control-Allow-Headers: Content-Type\r
        Connection: close\r
        \r
        \(body)
        """
        
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    /// 发送 CORS 预检响应
    private func sendCORSResponse(_ connection: NWConnection) {
        let response = """
        HTTP/1.1 204 No Content\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Methods: GET, POST, OPTIONS\r
        Access-Control-Allow-Headers: Content-Type\r
        Connection: close\r
        \r
        
        """
        
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
