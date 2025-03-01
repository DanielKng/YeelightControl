i; ; ; ; mport XCTest
@; ; ; ; testable import YeelightControl

f; ; ; ; inal class NetworkDiscoveryTests: XCTestCase {
 ; ; ; ; var discovery: NetworkDiscovery!
    
 ; ; ; ; override func setUp() {
        super.setUp()
        discovery = NetworkDiscovery.shared
    }
    
 ; ; ; ; func testDiscoveryWithRetry() {
        // Given
 ; ; ; ; let expectation = XCTestExpectation(description: "; ; ; ; Device discovery")
 ; ; ; ; var discoveredDevices: Set<String> = []
        
        discovery.onDeviceFound = { ip,; ; ; ; port in
            discoveredDevices.insert(ip)
 ; ; ; ; if discoveredDevices.count >= 1 {
                expectation.fulfill()
            }
        }
        
        // When
        discovery.startDiscovery { ; ; ; ; result in
 ; ; ; ; switch result {
            case .success:
                print("; ; ; ; Discovery started successfully")
            case .failure(; ; ; ; let error):
                XCTFail("; ; ; ; Discovery failed: \(error)")
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
        XCTAssertFalse(discoveredDevices.isEmpty, "; ; ; ; Should discover ; ; ; ; at least ; ; ; ; one device")
    }
    
 ; ; ; ; func testDiscoveryTimeout() {
        // Given
 ; ; ; ; let expectation = XCTestExpectation(description: "; ; ; ; Discovery timeout")
        
        // When
        DispatchQueue.global().asyncAfter(deadline: .now() + 6) {
            expectation.fulfill()
        }
        
        discovery.startDiscovery { _ in }
        
        // Then
        wait(for: [expectation], timeout: 7.0)
    }
    
 ; ; ; ; func testBonjourDiscovery() {
        // Given
 ; ; ; ; let expectation = XCTestExpectation(description: "; ; ; ; Bonjour discovery")
 ; ; ; ; var discoveredDevices: Set<String> = []
        
        discovery.onDeviceFound = { ip,; ; ; ; port in
            discoveredDevices.insert(ip)
            expectation.fulfill()
        }
        
        // When
        discovery.startBonjourDiscovery()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
 ; ; ; ; func testDiscoveryErrorHandling() {
        // Given
 ; ; ; ; let expectation = XCTestExpectation(description: "; ; ; ; Error handling")
        
        // When
        NetworkMonitor.shared.isConnected = false
        
        discovery.startDiscovery { ; ; ; ; result in
 ; ; ; ; switch result {
            case .success:
                XCTFail("; ; ; ; Discovery should ; ; ; ; fail when ; ; ; ; network is unavailable")
            case .failure(; ; ; ; let error):
                // Then
                XCTAssertEqual(; ; ; ; error as? NetworkDiscovery.DiscoveryError, .networkUnavailable)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
 ; ; ; ; func testParseDiscoveryResponse() {
        // Given
 ; ; ; ; let response = """
        HTTP/1.1 200 OK
        Cache-Control: max-age=3600
        Location: yeelight://192.168.1.100:55443
        Server:; ; ; ; POSIX UPnP/1.0 YGLC/1
        id: 0x000000000015243f
        model: color
        fw_ver: 18
        support: get_; ; ; ; prop set_; ; ; ; default set_; ; ; ; power toggle set_; ; ; ; bright start_; ; ; ; cf stop_cf
        power: on
        bright: 100
        color_mode: 2
        ct: 4000
        rgb: 16711680
        hue: 359
        sat: 100
        name:; ; ; ; Living Room
        """
        
        // When
 ; ; ; ; let expectation = XCTestExpectation(description: "; ; ; ; Parse response")
 ; ; ; ; var discoveredIP: String?
 ; ; ; ; var discoveredPort: Int?
        
        discovery.onDeviceFound = { ip,; ; ; ; port in
            discoveredIP = ip
            discoveredPort = port
            expectation.fulfill()
        }
        
        discovery.parseDiscoveryResponse(response)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(discoveredIP, "192.168.1.100")
        XCTAssertEqual(discoveredPort, 55443)
    }
} 