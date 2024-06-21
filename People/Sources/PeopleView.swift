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
  
  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case onDelete(IndexSet)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case let .onDelete(indexSet):
        // TODO: Add a confirmation
        let deletions = state.people[offsets: indexSet]
        try? database.delete(deletions)
        state.fetchPeople()
        return .none
      }
    }
  }
}

struct PeopleView: View {
  @Bindable var store: StoreOf<PeopleFeature>
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  public var body: some View {
    NavigationStack {
      List {
        ForEach(store.people) { person in
          if horizontalSizeClass == .compact {
            VStack(alignment: .leading, spacing: 8) {
              Text(person.name)
              Text(person.address).lineLimit(nil)
            }
          } else {
            HStack {
              Text(person.name)
                .frame(width: 200, alignment: .leading)
              Text(person.address).lineLimit(nil)
            }
          }
        }
        .onDelete { indices in
          store.send(.onDelete(indices))
        }
      }.navigationTitle("People")
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
