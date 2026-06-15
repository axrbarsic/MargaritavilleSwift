import SwiftUI

struct CartConsumableQuantityRuler: View {
    let quantity: Int
    let maximum: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(0...maximum, id: \.self) { index in
                VStack(spacing: 7) {
                    Rectangle()
                        .fill(MatrixConsumableStyle.green.opacity(index <= quantity ? 0.94 : 0.42))
                        .frame(width: index % 5 == 0 ? 2 : 1, height: index % 5 == 0 ? 34 : 26)

                    Text("\(index)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(MatrixConsumableStyle.green)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
