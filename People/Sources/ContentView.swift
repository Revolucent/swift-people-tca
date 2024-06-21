import ComposableArchitecture
import SwiftUI

@Reducer
struct AppFeature {
  struct State {
    var people: PeopleFeature.State = .init()
  }
  
  enum Action {
    case people(PeopleFeature.Action)
  }
  
  var body: some ReducerOf<AppFeature> {
    Scope(state: \.people, action: \.people) { PeopleFeature() }
  }
}

public struct ContentView: View {
  var store: StoreOf<AppFeature> = .init(
    initialState: .init(),
    reducer: { AppFeature() }
  )

  public var body: some View {
    PeopleView(store: store.scope(state: \.people, action: \.people))
  }
}

#Preview {
  ContentView()
}
