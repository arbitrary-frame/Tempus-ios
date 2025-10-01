//
//  TempusWidgetBundle.swift
//  TempusWidget
//
//  Created by Ronak Pattani on 01/10/2025.
//

import WidgetKit
import SwiftUI

@main
struct TempusWidgetBundle: WidgetBundle {
    var body: some Widget {
        GoalProgressWidget()
        ExercisesWidget()
        WeightWidget()
        CombinedStatsWidget()
    }
}
