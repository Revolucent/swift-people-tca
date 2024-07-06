//
//  Database.swift
//  People
//
//  Created by Gregory Higley on 2024-06-21.
//

import ComposableArchitecture
import Foundation
import Dependencies
import GRDB

class Database {
  private let queue: DatabaseQueue
  
  init(path: String = ":memory:") throws {
    queue = try DatabaseQueue(path: path)
    try migrate()
  }
  
  func save<T>(_ records: any Sequence<T>) throws where T: PersistableRecord {
    try queue.write { db in
      for record in records {
        try record.save(db)
      }
    }
  }
  
  func save<T: PersistableRecord>(_ records: T...) throws {
    try save(records)
  }
  
  func delete<T>(_ records: any Sequence<T>) throws where T: PersistableRecord {
    try queue.write { db in
      for record in records {
        try record.delete(db)
      }
    }
  }
  
  func delete<T: PersistableRecord>(_ records: T...) throws {
    try delete(records)
  }
  
  func fetchAll<T: FetchableRecord & TableRecord>(_ request: QueryInterfaceRequest<T>) throws -> some Sequence<T> {
    try queue.read { db in
      try request.fetchAll(db)
    }
  }
  
  func fetchAll<T: FetchableRecord & TableRecord>(_ type: T.Type = T.self) throws -> some Sequence<T> {
    try fetchAll(T.all())
  }
  
  func fetchIdentifiedArray<T: FetchableRecord & TableRecord & Identifiable>(_ request: QueryInterfaceRequest<T>) throws -> IdentifiedArrayOf<T> {
    try IdentifiedArray(uniqueElements: fetchAll(request))
  }
  
  func fetchIdentifiedArray<T: FetchableRecord & TableRecord & Identifiable>(of type: T.Type = T.self) throws -> IdentifiedArrayOf<T> {
    try IdentifiedArray(uniqueElements: fetchAll())
  }
  
  func fetchGenders() throws -> IdentifiedArrayOf<Gender> {
    try fetchIdentifiedArray(Gender.order(Column("sort"), Column("name")))
  }
  
  private func migrate() throws {
    var migrator = DatabaseMigrator()
    migrator.registerMigration("v1") { db in
      try db.create(table: "gender") { table in
        table.column("code", .text).primaryKey().notNull()
        table.column("name", .text).unique().notNull()
        table.column("sort", .integer).notNull().defaults(to: 100)
      }
      try db.create(table: "person") { table in
        table.autoIncrementedPrimaryKey("id").notNull()
        table.column("name", .text).notNull()
        table.column("gender", .text).notNull().references("gender", column: "code")
        table.column("address", .text).notNull()
        table.column("updatedAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
        table.uniqueKey(["name", "address"])
      }
    }
    try migrator.migrate(queue)
  }
}

extension Database: DependencyKey {
  static var liveValue: Database {
    let database = try! Database()
    let previewGenders = [
      Gender(code: "m", name: "Male", sort: 0),
      Gender(code: "f", name: "Female", sort: 1),
      Gender(code: "ns", name: "Not Specified", sort: 2),
      Gender(code: "mv", name: "Maverique"),
      Gender(code: "nb", name: "Non-Binary"),
      Gender(code: "gq", name: "Genderquivering"),
      Gender(code: "gp", name: "Genderpunk"),
      Gender(code: "gv", name: "Gendervoid")
    ]
    try! database.save(previewGenders)
    let previewPeople = [
      Person(name: "Genghis Khan", address: "555 5th Street\nQueens NY 10000"),
      Person(name: "Flip MacGillicuddy", address: "103 Whiskey Road\nDublin FL 34222"),
      Person(name: "Blob McBlobbins", address: "947 Skipadoo Alley\nWashing Nuts WA 98001"),
      Person(name: "Eric Bloodaxe", address: "780 Annodomini Avenue\nNorway MA 02108"),
      Person(name: "Zaphod Beeblebrox", address: "555 Arthur St\nDent MI 48001"),
      Person(name: "Hugh Jass", address: "123 Nowhere Fast Ave.\nSmiths Village FL 34000"),
    ]
    try! database.save(previewPeople)
    return database
  }
}

struct Gender: Codable, Equatable, PersistableRecord, FetchableRecord, TableRecord, Identifiable {
  var id: String { code }
  var code: String
  var name: String
  var sort: Int64 = 100
}

struct Person: Codable, Equatable, PersistableRecord, FetchableRecord, TableRecord, Identifiable {
  var id: ID<Int64> = nil
  var name: String = ""
  var gender: String = "m"
  var address: String = ""
  var updatedAt: Date = .now
  
  mutating func prepareForValidation() {
    name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    address = address.trimmingCharacters(in: .whitespacesAndNewlines)
    address = address.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
  }
}
