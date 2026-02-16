//
//  MainAppView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/15/26.
//

import SwiftUI

struct MainAppView: View {
    
    let workouts = [
        ("Apr 18", "Sheen Street", "1:00pm"),
        ("Apr 23", "Sheen Street", "5:00pm"),
        ("Apr 24", "Sheen Street", "6:00pm")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // Header
                HStack {
                    Text("Push Day")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Text("12:05")
                        .font(.title3)
                }
                .padding(.horizontal)
                
                // Main Workout Card
                ZStack(alignment: .bottomLeading) {
                    Image("push_day") // placeholder workout image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Push Day")
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                        
                        Text("5 exercises • 45 min")
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            Button(action: { /* Start workout */ }) {
                                Text("Start Workout")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: { /* Edit */ }) {
                                Text("Edit")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                // Stats Section
                HStack(spacing: 16) {
                    VStack {
                        Text("Weekly Volume")
                            .font(.subheadline)
                        // Simplified chart example
                        HStack(spacing: 4) {
                            ForEach(0..<7) { i in
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: CGFloat.random(in: 20...60))
                                    .cornerRadius(3)
                            }
                        }
                    }
                    VStack {
                        Text("Current Streak")
                            .font(.subheadline)
                        Text("5 Days")
                            .font(.title2)
                            .bold()
                    }
                }
                .padding(.horizontal)
                
                // Recent Workouts
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Workouts")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(workouts, id: \.0) { workout in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(workout.0)
                                    .bold()
                                Text(workout.1)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(workout.2)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
            }
            .padding(.vertical)
        }
    }
}
