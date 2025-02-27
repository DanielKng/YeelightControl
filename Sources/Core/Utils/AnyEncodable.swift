import Foundation

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    
    public init<T: Encodable>(_ value: T) {
        _encode = value.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

extension AnyEncodable: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self.init(Optional<String>.none as Any)
    }
}

extension AnyEncodable: ExpressibleByBooleanLiteral {
    init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

extension AnyEncodable: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension AnyEncodable: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension AnyEncodable: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(value)
    }
} 