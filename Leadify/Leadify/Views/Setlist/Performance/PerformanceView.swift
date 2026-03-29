import SwiftUI

@available(iOS 18.0, *)
struct PerformanceView: View {
    let setlist: Setlist
    @Environment(\.dismiss) private var dismiss

    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var scrollOffset: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0

    var body: some View {
        ZStack {
            PerformanceTheme.background.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(setlist.sortedEntries) { entry in
                        Group {
                            switch entry.itemType {
                            case .song:
                                SongBlock(song: entry.song!)
                            case .tacet:
                                TacetBlock(tacet: entry.tacet!)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 80)
            }
            .scrollPosition($scrollPosition)
            .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) { _, y in
                scrollOffset = y
            }
            .onScrollGeometryChange(for: CGFloat.self, of: { $0.containerSize.height }) { _, h in
                viewportHeight = h
            }
            .overlay(alignment: .top) {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: viewportHeight * 0.2)
                    .contentShape(Rectangle())
                    .onTapGesture { scrollUp() }
            }
            .overlay(alignment: .bottom) {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: viewportHeight * 0.2)
                    .contentShape(Rectangle())
                    // Lift above iOS home-indicator gesture zone
                    .padding(.bottom, 20)
                    .onTapGesture { scrollDown() }
            }
        }
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - Scroll

    private func scrollUp() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollPosition.scrollTo(y: max(0, scrollOffset - viewportHeight))
        }
    }

    private func scrollDown() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollPosition.scrollTo(y: scrollOffset + viewportHeight)
        }
    }

    // MARK: - Close button

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PerformanceTheme.closeButtonColor)
                .frame(width: 28, height: 28)
                .background(PerformanceTheme.closeButtonBackground)
                .clipShape(Circle())
        }
        .padding(.top, 20)
        .padding(.trailing, 20)
    }
}
