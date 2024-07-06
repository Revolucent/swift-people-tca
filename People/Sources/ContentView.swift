import ComposableArchitecture
import SwiftUI

@Reducer
struct AppFeature {
  enum Tab {
    case one
    case two
  }
  
  @ObservableState
  struct State {
    var selectedTab: Tab = .one
    var people: PeopleFeature.State = .init()
    var navex: NavexFeature.State = .init()
  }
  
  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case people(PeopleFeature.Action)
    case navex(NavexFeature.Action)
  }
  
  var body: some ReducerOf<AppFeature> {
    BindingReducer()
    Scope(
      state: \.people,
      action: \.people
    ) { PeopleFeature() }
    Scope(
      state: \.navex,
      action: \.navex
    ) {
      NavexFeature()
    }
  }
}

public struct ContentView: View {
  @Bindable var store: StoreOf<AppFeature> = .init(
    initialState: .init(),
    reducer: { AppFeature() }
  )

  public var body: some View {
    TabView(selection: $store.selectedTab) {
      PeopleView(store: store.scope(state: \.people, action: \.people))
        .tabItem { Text("One") }
        .tag(AppFeature.Tab.one)
      NavexView(store: store.scope(state: \.navex, action: \.navex))
        .tabItem { Text("Two") }
        .tag(AppFeature.Tab.two)
    }
  }
}

#Preview {
  ContentView()
}
