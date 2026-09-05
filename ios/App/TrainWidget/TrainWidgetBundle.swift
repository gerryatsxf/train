//
//  TrainWidgetBundle.swift
//  TrainWidget
//
//  Created by Gerardo Mijares on 04/09/26.
//

import WidgetKit
import SwiftUI

@main
struct TrainWidgetBundle: WidgetBundle {
    var body: some Widget {
        TrainWidget()
        TrainWidgetControl()
        TrainWidgetLiveActivity()
    }
}
