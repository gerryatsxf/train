//
//  TrainWidgetLiveActivity.swift
//  TrainWidget
//
//  Created by Gerardo Mijares on 04/09/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

/// El tipo `RestAttributes` vive en la app y debe pertenecer también a este target:
/// selecciona RestAttributes.swift y marca TrainWidgetExtension en Target Membership.
struct TrainWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestAttributes.self) { context in
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("DESCANSO")
                        .font(.system(size: 11, weight: .bold))
                        .kerning(1.2)
                        .foregroundStyle(.secondary)
                    Text(context.state.exercise)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                    if !context.state.setLabel.isEmpty {
                        Text("Serie \(context.state.setLabel)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                Text(timerInterval: context.state.startedAt...context.state.endAt, countsDown: true)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(width: 108)
                    .foregroundStyle(.cyan)
            }
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.55))
            .activitySystemActionForegroundColor(.cyan)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.setLabel.isEmpty ? "Serie" : context.state.setLabel,
                          systemImage: "dumbbell.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.startedAt...context.state.endAt, countsDown: true)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .frame(width: 78)
                        .foregroundStyle(.cyan)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.exercise)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(.cyan)
            } compactTrailing: {
                Text(timerInterval: context.state.startedAt...context.state.endAt, countsDown: true)
                    .monospacedDigit()
                    .frame(width: 42)
                    .foregroundStyle(.cyan)
            } minimal: {
                Image(systemName: "timer").foregroundStyle(.cyan)
            }
        }
    }
}
