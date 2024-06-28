//
//  ID.swift
//  People
//
//  Created by Gregory Higley on 2024-06-24.
//

import Foundation
import GRDB

infix operator =~=: ComparisonPrecedence

protocol IDEquatable {
  func idEquatable(with other: Self) -> Bool
}

func =~= <ID: IDEquatable>(lhs: ID, rhs: ID) -> Bool {
  lhs.idEquatable(with: rhs)
}

enum ID<Stored: Hashable & Codable & DatabaseValueConvertible>: Hashable {
  case stored(Stored)
  case ephemeral(UUID)
  
  var value: Stored? {
    switch self {
    case let .stored(stored):
      stored
    case .ephemeral:
      nil
    }
  }
  
  var isEphemeral: Bool {
    switch self {
    case .ephemeral:
      true
    case .stored:
      false
    }
  }
  
  init(stored: Stored? = nil) {
    if let stored {
      self = .stored(stored)
    } else {
      self = .ephemeral(UUID())
    }
  }
}

extension ID: Codable {
  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let stored = try container.decode(Stored?.self) {
      self = .stored(stored)
    } else {
      self = .ephemeral(UUID())
    }
  }
  
  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}

extension ID: ExpressibleByNilLiteral {
  init(nilLiteral: ()) {
    self = .ephemeral(UUID())
  }
}

extension ID: Comparable where Stored: Comparable {
  static func < (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.stored(lhs), .stored(rhs)):
      lhs < rhs
    case let (.ephemeral(lhs), .ephemeral(rhs)):
      lhs < rhs
    case (.ephemeral, .stored):
      true
    case (.stored, .ephemeral):
      false
    }
  }
}

extension ID: DatabaseValueConvertible {
  static func fromDatabaseValue(_ dbValue: DatabaseValue) -> ID<Stored>? {
    ID(stored: Stored.fromDatabaseValue(dbValue))
  }
  
  var databaseValue: DatabaseValue {
    value?.databaseValue ?? .null
  }
}

extension ID: IDEquatable {
  func idEquatable(with other: ID<Stored>) -> Bool {
    switch (self, other) {
    case let (.stored(lhs), .stored(rhs)):
      lhs == rhs
    case (.ephemeral, .ephemeral):
      true
    default:
      false
    }
  }
}

extension Array: IDEquatable where Element: IDEquatable {
  func idEquatable(with other: [Element]) -> Bool {
    guard count == other.count else { return false }
    return zip(self, other).allSatisfy { $0.0 =~= $0.1 }
  }
}
