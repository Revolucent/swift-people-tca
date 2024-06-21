//
//  PeopleView.swift
//  People
//
//  Created by Gregory Higley on 2024-06-21.
//

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct PeopleFeature {
  @Dependency(Database.self) var database
  
  @ObservableState
  struct State {
    var people: IdentifiedArrayOf<Person> = []
    
    init() {
      fetchPeople()
    }
    
    mutating func fetchPeople() {
      @Dependency(Database.self) var database
      people = IdentifiedArray(
        uniqueElements: (try? database.fetchAllPeople()) ?? []
      )
    }
  }
}

struct PeopleView: View {
  var store: StoreOf<PeopleFeature>

  public var body: some View {
    Table(store.people) {
      TableColumn("Name", value: \.name)
    }
  }
}

#Preview {
  PeopleView(store:
    .init(
      initialState: .init(),
      reducer: { PeopleFeature() }
    )
  )
}
