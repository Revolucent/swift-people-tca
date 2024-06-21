import ComposableArchitecture
import SwiftUI

@Reducer
struct AppFeature {}

public struct ContentView: View {
  public init() {}

  public var body: some View {
    Text("Hello, World!")
      .padding()
  }
}

#Preview {
  ContentView()
}
