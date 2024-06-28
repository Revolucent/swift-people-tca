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
  struct State: Equatable {
    @ObservationStateIgnored private var originalPerson: Person
    var person: Person
    var validations = ValidationState<Person>()
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
        let validateName = Validate<Person> { person in
          person.name.isNotEmpty.else("Name should not be empty.")
          person.name.count(greaterThanOrEqualTo: 4).else("Name should contain at least 4 characters.")
        }
        let validateAddress = Validate<Person> { person in
          person.address.isNotEmpty.else("Address should not be empty.")
          person.address.count(greaterThanOrEqualTo: 20).else("Address must contain at least 20 characters.")
        }
        state.person.prepareForValidation()
        state.validations.validate(state.person) {
          validateName
          validateAddress
        }
        if state.validations.allValid && state.isDirty {
          try! database.save(state.person)
          return .run { send in
            await send(.delegate(.saved))
            await dismiss()
          }
        }
        return .none
      }
    }
  }
}

struct PersonView: View {
  @Bindable var store: StoreOf<PersonFeature>
  
  var body: some View {
    NavigationStack {
      Form {
        ValidationResultView(store.validations.name) {
          TextField("Name", text: $store.person.name)
        }
        ValidationResultView(store.validations.address) {
          TextField("Address", text: $store.person.address, axis: .vertical)
            .lineLimit(5)
        }
      }
      .toolbar {
        Button("Save") {
          store.send(.saveButtonTapped)
        }
      }
    }
  }
}

struct ValidationResultView<Content: View>: View {
  let result: ValidationResult
  let content: () -> Content
  
  init(_ result: ValidationResult, @ViewBuilder content: @escaping () -> Content) {
    self.result = result
    self.content = content
  }
  
  var body: some View {
    if result.isValid {
      content()
    } else {
      VStack(alignment: .leading) {
        content()
        HStack(alignment: .top) {
          Image(systemName: "exclamationmark.circle")
            .foregroundStyle(Color.red)
          Text(result.error!)
            .lineLimit(nil)
            .italic()
            .foregroundStyle(Color.red)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }
}

struct ValidationView: View {
  let result: ValidationResult
  
  var body: some View {
    if result.isValid {
      EmptyView()
    } else {
      Label(result.error!, systemImage: "exclamationmark.triangle")
        .foregroundStyle(Color.red)
        .font(.callout)
        .italic()
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
