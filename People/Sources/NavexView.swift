//
//  NavexView.swift
//  People
//
//  Created by Gregory Higley on 2024-07-05.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct NavexFeature {
  @Reducer
  enum Path {
    case detail(NavexDetailFeature)
  }

  @ObservableState
  struct State {
    var path = StackState<Path.State>()
  }
  
  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case showDetail
    case path(StackAction<Path.State, Path.Action>)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case .path:
        return .none
      case .showDetail:
        state.path.append(.detail(.init()))
        return .none
      }
    }.forEach(\.path, action: \.path)
  }
}

struct NavexView: View {
  @Bindable var store: StoreOf<NavexFeature>
  
  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      Button {
        store.send(.showDetail)
      } label: {
        Text("Details")
      }
      .navigationTitle("Root")
    } destination: { pathStore in
      switch pathStore.case {
      case let .detail(store):
        NavexDetailView(store: store)
          .navigationTitle("Details")
      }
    }
  }
}
