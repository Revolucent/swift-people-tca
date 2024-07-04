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
  
  @Reducer
  enum Destination {
  case person(PersonFeature)
  case stupid(StupidFeature)
  }
  
  @ObservableState
  struct State {
    @Presents var confirm: ConfirmationDialogState<ConfirmationAction>?
    @Presents var destination: Destination.State?
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
    case destination(PresentationAction<Destination.Action>)
    case binding(BindingAction<State>)
    case onDeleteButtonTapped(ID<Int64>)
    case onRowTapped(Person)
    case onPullToRefresh
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        state.destination = .person(.init())
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
      case .destination(.presented(.person(.delegate(let delegate)))):
        switch delegate {
        case .saved:
          state.fetchPeople()
          return .none
        }
      case .destination:
        return .none
      case .binding:
        return .none
      case .onDeleteButtonTapped:
        state.destination = .stupid(.init())
//        guard let person = state.people[id: id] else {
//          return .none
//        }
//        state.confirm = ConfirmationDialogState(
//          title: TextState("Are you sure you want to delete \(person.name)?"),
//          message: TextState("Are you sure you want to delete \(person.name)? This action cannot be undone."),
//          buttons: [
//            .cancel(TextState("Don't Delete")),
//            .destructive(
//              TextState("Delete"),
//              action: .send(.deletePerson(id))
//            )
//         ]
//        )
        return .none
      case .onPullToRefresh:
        state.fetchPeople()
        return .none
      case let .onRowTapped(person):
        state.destination = .person(.init(person: person))
        return .none
      }
    }
    .ifLet(\.$confirm, action: \.confirm)
    .ifLet(\.$destination, action: \.destination)
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
            Row(person: person) {
              store.send(.onRowTapped(person))
            } delete: {
              store.send(.onDeleteButtonTapped(person.id))
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
      .sheet(item: $store.scope(state: \.destination?.person, action: \.destination.person)) { store in
        PersonView(store: store)
          .interactiveDismissDisabled()
      }
      .sheet(item: $store.scope(state: \.destination?.stupid, action: \.destination.stupid)) { store in
        StupidView(store: store)
      }
    }
  }
}

struct Row: View {
  let person: Person
  let action: () -> Void
  let delete: () -> Void
  
  var body: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 8) {
        Text(person.name)
        Text(person.address)
          .lineLimit(nil)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
      .onTapGesture {
        action()
      }
      Button {
        delete()
      } label: {
        Image(systemName: "trash")
          .foregroundStyle(Color.red)
      }
    }
    .padding(.vertical, 4)
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
