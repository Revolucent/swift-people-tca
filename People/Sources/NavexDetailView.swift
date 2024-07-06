//
//  NavexDetailView.swift
//  People
//
//  Created by Gregory Higley on 2024-07-05.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct NavexDetailFeature {}

struct NavexDetailView: View {
  var store: StoreOf<NavexDetailFeature>
  
  var body: some View {
    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
  }
}
