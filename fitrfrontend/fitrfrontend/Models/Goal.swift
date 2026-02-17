//
//  Goal.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a user's fitness goal.
enum Goal: String, Codable, CaseIterable {
    case strength = "STRENGTH"
    case hypertrophy = "HYPERTROPHY"
    case fatLoss = "FAT_LOSS"
    case general = "GENERAL"
}
