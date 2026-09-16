//
//  TrainWidgetLiveActivity.swift
//  TrainWidget
//
//  Created by Gerardo Mijares on 04/09/26.
//

import ActivityKit
import AppIntents
import WidgetKit
import SwiftUI

/// El tipo `RestAttributes` vive en la app y debe pertenecer también a este target:
/// selecciona RestAttributes.swift y marca TrainWidgetExtension en Target Membership.
struct TrainWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestAttributes.self) { context in
            // El botón va en su propia fila: en pantallas de 375 pt no cabe junto al contador.
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(headline(context.state, done: context.isStale))
                            .font(.system(size: 11, weight: .bold))
                            .kerning(1.2)
                            .foregroundStyle(context.state.registered ? Color.green : Color.secondary)
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
                    // `Text(timerInterval:)` no tiene tamaño intrínseco: sin frame explícito se colapsa
                    if context.state.registered {
                        Text(clock(context.state.registeredSeconds))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .frame(width: 104, alignment: .trailing)
                    } else {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(timerInterval: context.state.startedAt...context.state.endAt, countsDown: true)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.white)
                                .frame(width: 104, alignment: .trailing)
                            totalRunning(context.state.startedAt)
                        }
                    }
                }
                if #available(iOS 17.0, *), !context.state.registered {
                    registerButton(context.state, wide: true)
                }
            }
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.55))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.setLabel.isEmpty ? "Serie" : context.state.setLabel,
                          systemImage: "dumbbell.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.registered {
                        Text(clock(context.state.registeredSeconds))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.green)
                    } else {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(timerInterval: context.state.startedAt...context.state.endAt, countsDown: true)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .frame(width: 78, alignment: .trailing)
                                .foregroundStyle(.white)
                            totalRunning(context.state.startedAt)
                                .frame(width: 78, alignment: .trailing)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if #available(iOS 17.0, *), !context.state.registered {
                        registerButton(context.state, wide: true)
                    } else {
                        Text(context.state.exercise)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.registered ? "checkmark.circle.fill" : "timer")
                    .foregroundStyle(context.state.registered ? Color.green : Color.white)
            } compactTrailing: {
                if context.state.registered {
                    Text(clock(context.state.registeredSeconds))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                } else {
                    Text(timerInterval: context.state.startedAt...context.state.endAt, countsDown: true)
                        .monospacedDigit()
                        .frame(width: 42)
                        .foregroundStyle(.white)
                }
            } minimal: {
                Image(systemName: context.state.registered ? "checkmark.circle.fill" : "timer")
                    .foregroundStyle(context.state.registered ? Color.green : Color.white)
            }
        }
    }

    private func headline(_ s: RestAttributes.ContentState, done: Bool) -> String {
        if s.registered { return "REGISTRADO" }
        return done ? "DESCANSO TERMINADO" : "DESCANSO"
    }

    private func clock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    /// Cuenta hacia arriba sin parar: cuando la cuenta atrás llega a 0:00 esto sigue
    /// avanzando y deja claro que el descanso se está acumulando. No necesita updates.
    private func totalRunning(_ startedAt: Date) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "stopwatch")
                .font(.system(size: 10, weight: .semibold))
            Text(timerInterval: startedAt...startedAt.addingTimeInterval(24 * 3600),
                 countsDown: false)
                .monospacedDigit()
                .frame(width: 46, alignment: .leading)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(.secondary)
        .frame(width: 104, alignment: .trailing)
    }

    @available(iOS 17.0, *)
    private func registerButton(_ s: RestAttributes.ContentState, wide: Bool) -> some View {
        // apariencia propia: los estilos de botón del sistema no se dibujan igual en widgets
        Button(intent: RegisterRestIntent(exId: s.exId, setIndex: s.setIndex,
                                          week: s.week, startedAt: s.startedAt)) {
            Label("Registrar descanso", systemImage: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: wide ? .infinity : nil, minHeight: 26)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Color.purple, in: Capsule())
                // el toque fuera del botón cae en la tarjeta, y eso abre la app
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
