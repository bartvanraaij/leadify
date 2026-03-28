import SwiftUI

struct PerformanceView: View {
    let setlist: Setlist
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Text("Performance Mode — coming in Plan 2")
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .ignoresSafeArea()
            .onTapGesture(count: 3) { dismiss() }
    }
}
