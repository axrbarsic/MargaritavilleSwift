import SwiftUI

struct CartConsumableQuantityEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.interactionFeedback) private var feedback

    @State private var draftSelection: Int
    let maximum: Int
    let onSelect: (Int) -> Void

    init(selection: Int, maximum: Int, onSelect: @escaping (Int) -> Void) {
        self._draftSelection = State(initialValue: min(max(0, selection), maximum))
        self.maximum = maximum
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Количество")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(MatrixConsumableStyle.green)

                Spacer(minLength: 12)

                Text("\(draftSelection)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MatrixConsumableStyle.green)
                    .frame(minWidth: 68, alignment: .trailing)
            }

            CartConsumableQuantityRuler(quantity: draftSelection, maximum: maximum)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(MatrixConsumableStyle.green.opacity(0.95), lineWidth: 1.2)
                }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(0...maximum, id: \.self) { value in
                    Button {
                        choose(value)
                    } label: {
                        Text("\(value)")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(value == draftSelection ? .black : MatrixConsumableStyle.green)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(buttonFill(for: value), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(MatrixConsumableStyle.green.opacity(0.92), lineWidth: 1.1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                dismiss()
                feedback.deselect()
            } label: {
                Text("Отмена")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(MatrixConsumableStyle.green)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(MatrixConsumableStyle.green.opacity(0.72), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(Color.black.ignoresSafeArea())
    }

    private func buttonFill(for value: Int) -> Color {
        value == draftSelection ? MatrixConsumableStyle.green : .black.opacity(0.28)
    }

    private func choose(_ value: Int) {
        draftSelection = value
        feedback.select()
        onSelect(value)
    }
}
