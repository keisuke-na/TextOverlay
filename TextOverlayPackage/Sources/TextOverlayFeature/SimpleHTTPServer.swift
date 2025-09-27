import Foundation

@MainActor
class SimpleHTTPServer: NSObject {
    private var serverSocket: CFSocket?
    private let port: UInt16 = 8080
    weak var delegate: CommentManager?

    func start() {
        var context = CFSocketContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = Unmanaged.passUnretained(self).toOpaque()

        serverSocket = CFSocketCreate(kCFAllocatorDefault,
                                      PF_INET,
                                      SOCK_STREAM,
                                      IPPROTO_TCP,
                                      CFSocketCallBackType.acceptCallBack.rawValue,
                                      { (socket, type, address, data, info) in
                                          guard let info = info else { return }
                                          let server = Unmanaged<SimpleHTTPServer>.fromOpaque(info).takeUnretainedValue()
                                          if type == .acceptCallBack {
                                              let nativeHandle = data!.assumingMemoryBound(to: CFSocketNativeHandle.self).pointee
                                              server.handleNewConnection(nativeHandle)
                                          }
                                      },
                                      &context)

        guard let serverSocket = serverSocket else {
            print("Failed to create socket")
            return
        }

        var sin = sockaddr_in()
        sin.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        sin.sin_family = sa_family_t(AF_INET)
        sin.sin_port = port.bigEndian
        sin.sin_addr.s_addr = INADDR_ANY

        let addressData = NSData(bytes: &sin, length: MemoryLayout<sockaddr_in>.size) as CFData

        if CFSocketSetAddress(serverSocket, addressData) != .success {
            print("Failed to bind to port \(port)")
            return
        }

        let runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, serverSocket, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)

        print("HTTP Server started on port \(port)")
    }

    private func handleNewConnection(_ handle: CFSocketNativeHandle) {
        DispatchQueue.global().async { [weak self] in
            var buffer = [UInt8](repeating: 0, count: 4096)
            let bytesRead = recv(handle, &buffer, buffer.count, 0)

            if bytesRead > 0 {
                if let request = String(bytes: buffer[0..<bytesRead], encoding: .utf8) {
                    // Handle CORS preflight request
                    if request.contains("OPTIONS /message") {
                        let response = """
                        HTTP/1.1 200 OK\r
                        Access-Control-Allow-Origin: *\r
                        Access-Control-Allow-Methods: POST, OPTIONS\r
                        Access-Control-Allow-Headers: Content-Type\r
                        Content-Length: 0\r
                        \r
                        """
                        response.withCString { cstring in
                            send(handle, cstring, strlen(cstring), 0)
                        }
                        close(handle)
                        return
                    }

                    if request.contains("POST /message") {
                        // Extract JSON body
                        if let bodyRange = request.range(of: "\r\n\r\n") {
                            let bodyStart = request.index(bodyRange.upperBound, offsetBy: 0)
                            let jsonBody = String(request[bodyStart...])

                            if let jsonData = jsonBody.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                               let text = json["text"] as? String {

                                DispatchQueue.main.async {
                                    self?.delegate?.addComment(text)
                                }

                                let response = """
                                HTTP/1.1 200 OK\r
                                Content-Length: 0\r
                                Access-Control-Allow-Origin: *\r
                                Access-Control-Allow-Methods: POST, OPTIONS\r
                                Access-Control-Allow-Headers: Content-Type\r
                                \r
                                """
                                response.withCString { cstring in
                                    send(handle, cstring, strlen(cstring), 0)
                                }
                                close(handle)
                                return
                            }
                        }
                    }
                }
            }

            let response = """
            HTTP/1.1 400 Bad Request\r
            Content-Length: 0\r
            Access-Control-Allow-Origin: *\r
            \r
            """
            response.withCString { cstring in
                send(handle, cstring, strlen(cstring), 0)
            }
            close(handle)
        }
    }

    func stop() {
        if let serverSocket = serverSocket {
            CFSocketInvalidate(serverSocket)
            self.serverSocket = nil
        }
    }
}
