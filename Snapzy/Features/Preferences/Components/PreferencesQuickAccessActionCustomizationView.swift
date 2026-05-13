//
//  PreferencesQuickAccessActionCustomizationView.swift
//  Snapzy
//
//  Quick Access card preview and action ordering controls.
//

import SwiftUI

struct QuickAccessActionCustomizationView: View {
  @ObservedObject var manager: QuickAccessManager
  @ObservedObject private var actionStore = QuickAccessActionConfigurationStore.shared

  var body: some View {
    Section(L10n.PreferencesQuickAccess.previewSection) {
      HStack {
        Spacer()
        QuickAccessSettingsPreviewCard(
          scale: CGFloat(manager.overlayScale),
          actionStore: actionStore
        )
        Spacer()
      }
      .padding(.vertical, 10)
    }

    Section(L10n.PreferencesQuickAccess.quickActionsSection) {
      VStack(alignment: .leading, spacing: 10) {
        Text(L10n.PreferencesQuickAccess.quickActionsDescription)
          .font(.caption)
          .foregroundColor(.secondary)

        List {
          ForEach(actionStore.actionOrder) { action in
            QuickAccessActionConfigurationRow(
              action: action,
              assignedSlot: actionStore.assignedSlot(for: action),
              isEnabled: Binding(
                get: { actionStore.isEnabled(action) },
                set: { actionStore.setEnabled(action, enabled: $0) }
              )
            )
          }
          .onMove { source, destination in
            actionStore.moveAction(from: source, to: destination)
          }
        }
        .frame(minHeight: 190)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        HStack {
          Spacer()
          Button(L10n.PreferencesQuickAccess.resetActions) {
            actionStore.resetToDefaults()
          }
        }
      }
      .padding(.vertical, 4)
    }
  }
}

private struct QuickAccessActionConfigurationRow: View {
  let action: QuickAccessActionKind
  let assignedSlot: QuickAccessActionSlot?
  @Binding var isEnabled: Bool

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: action.systemImage)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(width: 18)

      Text(action.settingsTitle)
        .lineLimit(1)

      Spacer()

      Text(assignedSlot?.settingsTitle ?? L10n.PreferencesQuickAccess.notOnCard)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.quaternary, in: Capsule())

      Toggle("", isOn: $isEnabled)
        .labelsHidden()
    }
    .padding(.vertical, 2)
    .onDrag {
      QuickAccessActionDragPayload.itemProvider(action: action, source: .actionList)
    }
  }
}
