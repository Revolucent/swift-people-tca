//
//  Extensions.swift
//  People
//
//  Created by Gregory Higley on 2024-06-21.
//

import Foundation

extension Collection where Index == Int {
  subscript(offsets offsets: IndexSet) -> [Element] {
    offsets.compactMap { indices.contains($0) ? self[$0] : nil }
  }
}
