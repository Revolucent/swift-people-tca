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
    case deletePerson(ID<Int64>)
  }
  
  @ObservableState
  struct State {
    @Presents var confirm: ConfirmationDialogState<ConfirmationAction>?
    @Presents var person: PersonFeature.State?
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
    case addButtonTapped
    case confirm(PresentationAction<ConfirmationAction>)
    case person(PresentationAction<PersonFeature.Action>)
    case binding(BindingAction<State>)
    case onDeleteButtonPressed(ID<Int64>)
    case onRowTapped(Person)
    case onPullToRefresh
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        state.person = .init()
        return .none
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
      case let .person(.presented(.delegate(action))):
        switch action {
        case .saved:
          state.fetchPeople()
          return .none
        }
      case .person:
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
      case let .onRowTapped(person):
        state.person = .init(person: person)
        return .none
      }
    }
    .ifLet(\.$confirm, action: \.confirm)
    .ifLet(\.$person, action: \.person) {
      PersonFeature()
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
            ZStack(alignment: .topTrailing) {
              VStack(alignment: .leading, spacing: 8) {
                Text(person.name)
                Text(person.address)
                  .lineLimit(nil)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
//              Button {
//                store.send(.onDeleteButtonPressed(person.id))
//              } label: {
//                Image(systemName: "trash")
//                  .foregroundStyle(Color.red)
//              }
//              .contentShape(Rectangle())
            }
            .padding(.vertical, 4)
            .onTapGesture {
              store.send(.onRowTapped(person))
            }
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
      .toolbar {
        Button {
          store.send(.addButtonTapped)
        } label: {
          Image(systemName: "plus")
        }
      }
      .confirmationDialog(store: store.scope(state: \.$confirm, action: \.confirm))
      .sheet(item: $store.scope(state: \.person, action: \.person)) { store in
        PersonView(store: store)
      }
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
