//
//  ID.swift
//  People
//
//  Created by Gregory Higley on 2024-06-24.
//

import Foundation
import GRDB

enum Value<Stored: Hashable & Comparable & Codable & DatabaseValueConvertible>: Hashable {
  case stored(Stored)
  case ephemeral(UUID)
  
  init(value: Stored? = nil) {
    if let value {
      self = .stored(value)
    } else {
      self = .ephemeral(UUID())
    }
  }
  
  var value: Stored? {
    switch self {
    case let .stored(value):
      return value
    case .ephemeral:
      return nil
    }
  }
  
  var isEphemeral: Bool {
    value == nil
  }
}

extension Value: Comparable {
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

extension Value: ExpressibleByNilLiteral {
  init(nilLiteral: ()) {
    self = .ephemeral(UUID())
  }
}

extension Value: Codable {
  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(value: container.decode(Stored?.self))
  }
  
  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}

extension Value: DatabaseValueConvertible {
  static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Value<Stored>? {
    .init(value: Stored.fromDatabaseValue(dbValue))
  }
  
  var databaseValue: DatabaseValue {
    value?.databaseValue ?? .null
  }
}

struct ID<Stored: Hashable & Comparable & Codable & DatabaseValueConvertible>: Hashable {
  private let _value: Value<Stored>
  
  init(value: Stored? = nil) {
    _value = .init(value: value)
  }
  
  var value: Stored? {
    _value.value
  }
  
  var isEphemeral: Bool {
    _value.isEphemeral
  }
}

extension ID: ExpressibleByNilLiteral {
  init(nilLiteral: ()) {
    self.init()
  }
}

extension ID: Codable {
  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    _value = try container.decode(Value<Stored>.self)
  }
  
  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(_value)
  }
}

extension ID: DatabaseValueConvertible {
  static func fromDatabaseValue(_ dbValue: DatabaseValue) -> ID<Stored>? {
    ID(value: Stored.fromDatabaseValue(dbValue))
  }
  
  var databaseValue: DatabaseValue {
    value?.databaseValue ?? .null
  }
}
