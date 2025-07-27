import Foundation

struct AnyCodable: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let val = try? container.decode(Int.self) {
            value = val
        } else if let val = try? container.decode(Double.self) {
            value = val
        } else if let val = try? container.decode(Bool.self) {
            value = val
        } else if let val = try? container.decode(String.self) {
            value = val
        } else if container.decodeNil() {
            value = ()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let val as Int: try container.encode(val)
        case let val as Double: try container.encode(val)
        case let val as Bool: try container.encode(val)
        case let val as String: try container.encode(val)
        default: try container.encodeNil()
        }
    }
}

