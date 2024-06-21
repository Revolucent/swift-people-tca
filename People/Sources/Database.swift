//
//  Database.swift
//  People
//
//  Created by Gregory Higley on 2024-06-21.
//

import Foundation
import Dependencies
import GRDB

class Database {
  private let queue: DatabaseQueue
  
  init(path: String = ":memory:") throws {
    queue = try DatabaseQueue(path: path)
    try migrate()
  }
  
  func save<T: PersistableRecord>(_ records: [T]) throws {
    try queue.write { db in
      for record in records {
        try record.save(db)
      }
    }
  }
  
  func save<T: PersistableRecord>(_ records: T...) throws {
    try save(records)
  }
  
  func delete<T: PersistableRecord>(_ records: [T]) throws {
    try queue.write { db in
      for record in records {
        try record.delete(db)
      }
    }
  }
  
  func delete<T: PersistableRecord>(_ records: T...) throws {
    try delete(records)
  }
  
  func fetchAllPeople() throws -> [Person] {
    try queue.read { db in
      try Person.order(Column("name")).fetchAll(db)
    }
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
    ]
    try! database.save(previewPeople)
    return database
  }
  
  static var previewValue: Database {
    let database = try! Database()
    let previewPeople = [
      NewPerson(name: "Genghis Khan", address: "555 5th Street\nQueens NY 10000"),
      NewPerson(name: "Flip MacGillicuddy", address: "103 Whiskey Road\nDublin FL 34222"),
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
