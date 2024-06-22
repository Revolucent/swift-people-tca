//
//  PeopleView.swift
//  People
//
//  Created by Gregory Higley on 2024-06-21.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import GRDB

@Reducer
struct PeopleFeature {
  @Dependency(Database.self) var database

  enum ConfirmationAction {
    case deletePerson(Int64)
  }
  
  @ObservableState
  struct State {
    @Presents var confirm: ConfirmationDialogState<ConfirmationAction>?
    var people: IdentifiedArrayOf<Person> = []
    
    init() {
      fetchPeople()
    }
    
    mutating func fetchPeople() {
      @Dependency(Database.self) var database
      let sort = Person.order(Column("name"))
      people = (try? database.fetchIdentifiedArray(sort)) ?? []
    }
  }
  
  enum Action: BindableAction {
    case confirm(PresentationAction<ConfirmationAction>)
    case binding(BindingAction<State>)
    case onDeleteButtonPressed(Int64)
    case onPullToRefresh
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .confirm(.presented(action)):
        switch action {
        case let .deletePerson(id):
          guard let deleted = state.people[id: id] else { return .none }
          do {
            try database.delete(deleted)
            state.people.remove(id: id)
          } catch {
            
          }
          return .none
        }
      case .confirm:
        return .none
      case .binding:
        return .none
      case let .onDeleteButtonPressed(id):
        guard let person = state.people[id: id] else {
          return .none
        }
        state.confirm = ConfirmationDialogState(
          title: TextState("Are you sure you want to delete \(person.name)?"),
          message: TextState("Are you sure you want to delete \(person.name)? This action cannot be undone."),
          buttons: [
            .cancel(TextState("Don't Delete")),
            .destructive(
              TextState("Delete"),
              action: .send(.deletePerson(id))
            )
         ]
        )
        return .none
      case .onPullToRefresh:
        state.fetchPeople()
        return .none
      }
    }
    .ifLet(\.$confirm, action: \.confirm)
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
            ZStack(alignment: .topTrailing) {
              VStack(alignment: .leading, spacing: 8) {
                Text(person.name)
                Text(person.address)
                  .lineLimit(nil)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              Button {
                store.send(.onDeleteButtonPressed(person.id))
              } label: {
                Image(systemName: "trash")
                  .foregroundStyle(Color.red)
              }
            }
            .padding(.vertical, 4)
          } else {
            HStack {
              Text(person.name)
                .frame(width: 200, alignment: .leading)
              Text(person.address).lineLimit(nil)
            }
          }
        }
        .navigationTitle("People")
        .refreshable {
          store.send(.onPullToRefresh)
        }
      }
      .confirmationDialog(store: store.scope(state: \.$confirm, action: \.confirm))
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
