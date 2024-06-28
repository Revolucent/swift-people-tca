import Foundation
import XCTest

@testable import People

struct Something: IDEquatable, Equatable, Codable {
  var id: ID<UUID> = nil
  var name: String
  
  func idEquatable(with other: Something) -> Bool {
    id =~= other.id && name == other.name
  }
}

final class PeopleTests: XCTestCase {
  func testID() throws {
    let ids = [ID(stored: 7), nil]
    let encoder = JSONEncoder()
    let encoded = try encoder.encode(ids)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode([ID<Int>].self, from: encoded)
    XCTAssert(ids =~= decoded)
  }
  
  func testRecords() throws {
    let somethings = [Something(name: "Bob"), Something(name: "Fred")]
    let encoder = JSONEncoder()
    let encoded = try encoder.encode(somethings)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode([Something].self, from: encoded)
    XCTAssert(somethings =~= decoded)
  }
}
