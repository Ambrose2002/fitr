//
//  WorkoutsView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import SwiftUI

struct WorkoutsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Workouts")
                    .font(.title)
            }
            .navigationTitle("WORKOUTS")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

//#Preview {
//    WorkoutsView()
//}
