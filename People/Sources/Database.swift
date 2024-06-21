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
  }
}

extension Database: DependencyKey {
  static var liveValue: Database {
    try! .init()
  }
}
