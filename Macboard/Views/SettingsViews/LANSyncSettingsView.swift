import SwiftUI
import Settings
import Defaults

struct LANSyncSettingsView: View {
    
    @Default(.lanSyncEnabled) var lanSyncEnabled
    @Default(.lanSyncPort) var lanSyncPort
    
    @StateObject private var server = LocalSyncServer.shared
    @State private var qrCodeImage: NSImage?
    
    var body: some View {
        Settings.Container(contentWidth: 350) {
            Settings.Section(title: "") {
                VStack(alignment: .leading, spacing: 16) {
                    // 开关
                    Toggle("启用局域网同步", isOn: $lanSyncEnabled)
                        .onChange(of: lanSyncEnabled) { newValue in
                            if newValue {
                                server.port = lanSyncPort
                                server.start()
                            } else {
                                server.stop()
                            }
                            updateQRCode()
                        }
                    
                    Text("开启后，可以在同一局域网内使用手机访问并输入文本，同步到 Mac 剪贴板。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    if lanSyncEnabled {
                        Divider()
                        
                        // 状态显示
                        HStack {
                            Circle()
                                .fill(server.isRunning ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(server.isRunning ? "服务运行中" : "服务未启动")
                                .font(.footnote)
                        }
                        
                        // 访问地址
                        if let url = server.serverURL {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("访问地址:")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text(url)
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                    
                                    Button {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(url, forType: .string)
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    .buttonStyle(.borderless)
                                    .help("复制地址")
                                }
                            }
                            
                            Divider()
                            
                            // 二维码
                            VStack(alignment: .center, spacing: 8) {
                                Text("手机扫描二维码访问:")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if let qrImage = qrCodeImage {
                                    Image(nsImage: qrImage)
                                        .interpolation(.none)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 150, height: 150)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                } else {
                                    ProgressView()
                                        .frame(width: 150, height: 150)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .onAppear {
                    // 恢复之前的状态
                    if lanSyncEnabled && !server.isRunning {
                        server.port = lanSyncPort
                        server.start()
                    }
                    updateQRCode()
                }
            }
        }
    }
    
    private func updateQRCode() {
        if let url = server.serverURL {
            qrCodeImage = QRCodeGenerator.generate(from: url, size: 150)
        } else {
            qrCodeImage = nil
        }
    }
}
