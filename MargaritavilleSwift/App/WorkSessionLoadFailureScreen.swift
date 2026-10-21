import SwiftUI

/// Показывается вместо смены, если сохранённые данные не прочитались.
/// Пустая редактируемая смена здесь опасна: первое же изменение перезаписало бы
/// базу, поэтому пользователь видит ошибку и может только повторить загрузку.
struct WorkSessionLoadFailureScreen: View {
    let failure: WorkSessionLoadFailure
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            AppBackgroundView()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.yellow)
                Text("Смена не загрузилась")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Сохранённые данные не изменены. Изменения не сохраняются, пока загрузка не пройдёт.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                Text(failure.message)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
                Button("Повторить", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(24)
        }
    }
}
