//
//  PersonView.swift
//  People
//
//  Created by Gregory Higley on 2024-06-23.
//

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct PersonFeature {
  @Dependency(Database.self) var database
  @Dependency(\.dismiss) var dismiss
  
  @ObservableState
  struct State {
    @ObservationStateIgnored private var originalPerson: Person
    var person: Person
    
    init(person: Person = Person()) {
      self.originalPerson = person
      self.person = person
    }
    
    var isDirty: Bool {
      originalPerson != person
    }
  }
  
  enum Action: BindableAction {
    enum Delegate {
      case saved
    }
    
    case binding(BindingAction<State>)
    case delegate(Delegate)
    case saveButtonTapped
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case .delegate:
        return .none
      case .saveButtonTapped:
        if state.isDirty {
          try! database.save(state.person)
          return .run { send in
            await send(.delegate(.saved))
            await dismiss()
          }
        } else {
          return .run { _ in
            await dismiss()
          }
        }
      }
    }
  }
}

struct PersonView: View {
  @Bindable var store: StoreOf<PersonFeature>
  
  var body: some View {
    NavigationStack {
      Form {
        TextField("Name", text: $store.person.name)
        TextEditor(text: $store.person.address)
      }
      .toolbar {
        Button("Save") {
          store.send(.saveButtonTapped)
        }
      }
    }
  }
}

#Preview {
  PersonView(
    store: .init(
      initialState: .init(person: Person(name: "Preview", address: "123 Preview St\nPreview PV 00000"))
    ) {
      PersonFeature()
    }
  )
}
