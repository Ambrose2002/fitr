//
//  PlansView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import SwiftUI

struct PlansView: View {
    @EnvironmentObject var sessionStore: SessionStore
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Plans")
                    .font(.title)
            }
            .navigationTitle("PLANS")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

//#Preview {
//    PlansView()
//}
