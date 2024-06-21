import ComposableArchitecture
import SwiftUI

@Reducer
struct AppFeature {
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

public struct ContentView: View {
  var store: StoreOf<AppFeature> = .init(
    initialState: .init(),
    reducer: { AppFeature() }
  )

  public var body: some View {
    Text("Hello, World!")
      .padding()
  }
}

#Preview {
  ContentView()
}
