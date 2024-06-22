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
  
  private func migrate() throws {
    var migrator = DatabaseMigrator()
    migrator.registerMigration("v1") { db in
      try db.create(table: "person") { table in
        table.autoIncrementedPrimaryKey("id").notNull()
        table.column("name", .text).notNull()
        table.column("address", .text).notNull()
        table.uniqueKey(["name", "address"])
      }
    }
    try migrator.migrate(queue)
  }
}

extension Database: DependencyKey {
  static var liveValue: Database {
    let database = try! Database()
    let previewPeople = [
      NewPerson(name: "Genghis Khan", address: "555 5th Street\nQueens NY 10000"),
      NewPerson(name: "Flip MacGillicuddy", address: "103 Whiskey Road\nDublin FL 34222"),
      NewPerson(name: "Blob McBlobbins", address: "947 Skipadoo Alley\nWashing Nuts WA 98001"),
      NewPerson(name: "Eric Bloodaxe", address: "780 Annodomini Avenue\nNorway MA 02108"),
      NewPerson(name: "Zaphod Beeblebrox", address: "555 Arthur St\nDent MI 48001"),
      NewPerson(name: "Hugh Jass", address: "123 Nowhere Fast Ave.\nSmiths Village FL 34000"),
    ]
    try! database.save(previewPeople)
    return database
  }
}

struct NewPerson: Codable, Equatable, PersistableRecord {
  static let databaseTableName: String = "person"
  
  var name: String
  var address: String
}

struct Person: Codable, Equatable, PersistableRecord, FetchableRecord, TableRecord, Identifiable {
  var id: Int64
  var name: String
  var address: String
}
