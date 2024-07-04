//
//  StupidView.swift
//  People
//
//  Created by Gregory Higley on 2024-07-04.
//

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct StupidFeature {}

struct StupidView: View {
  let store: StoreOf<StupidFeature>
  
  var body: some View {
    EmptyView()
  }
}
