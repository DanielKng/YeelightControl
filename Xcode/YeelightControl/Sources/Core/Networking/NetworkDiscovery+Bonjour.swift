extension NetworkDiscovery: NetServiceDelegate {
    private func setupBonjourDiscovery() {
        let service = NetService(domain: "local.", type: "_yeelight._tcp.", name: "")
        service.delegate = self
        service.schedule(in: .current, forMode: .common)
        service.searchForServices(ofType: "_yeelight._tcp.", inDomain: "local.")
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses else { return }
        
        for address in addresses {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            var port = [CChar](repeating: 0, count: Int(NI_MAXSERV))
            
            let result = address.withUnsafeBytes { pointer in
                guard let sockaddr = pointer.baseAddress?.assumingMemoryBound(to: sockaddr.self) else { return -1 }
                return getnameinfo(
                    sockaddr,
                    socklen_t(address.count),
                    &hostname,
                    socklen_t(hostname.count),
                    &port,
                    socklen_t(port.count),
                    NI_NUMERICHOST | NI_NUMERICSERV
                )
            }
            
            if result == 0,
               let ip = String(cString: hostname, encoding: .utf8),
               let portString = String(cString: port, encoding: .utf8),
               let portNumber = Int(portString) {
                if !discoveredDevices.contains(ip) {
                    discoveredDevices.insert(ip)
                    DispatchQueue.main.async {
                        self.onDeviceFound?(ip, portNumber)
                    }
                }
            }
        }
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        print("Failed to resolve Bonjour service: \(errorDict)")
    }
} 