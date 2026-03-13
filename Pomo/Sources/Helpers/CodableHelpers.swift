import Foundation

func encode<T: Encodable>(_ value: T) throws -> Data {
    try JSONEncoder().encode(value)
}

func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    try JSONDecoder().decode(type, from: data)
}
