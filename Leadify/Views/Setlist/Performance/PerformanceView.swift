import SwiftUI

// Tracks the content's Y position relative to the scroll container.
// Negating minY gives us the scroll offset (how far the user has scrolled down).
private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct PerformanceView: View {
    let setlist: Setlist
    @Environment(\.dismiss) private var dismiss

    @State private var scrollPosition = ScrollPosition()
    @State private var scrollOffset: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
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
                    // Report content position relative to the named coordinate space so
                    // we can derive the current scroll offset reliably.
                    .background(GeometryReader { contentGeo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: -contentGeo.frame(in: .named("scrollContainer")).minY
                        )
                    })
                }
                .coordinateSpace(name: "scrollContainer")
                .scrollPosition($scrollPosition)
                .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
                // Corrects scrollOffset to the actual clamped position after animations
                // (e.g. the last scroll down hits the bottom before travelling a full vh).
                .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) { _, y in
                    scrollOffset = y
                }
                // Top 20% — scroll up one viewport
                .overlay(alignment: .top) {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: geo.size.height * 0.2)
                        .contentShape(Rectangle())
                        .simultaneousGesture(TapGesture().onEnded { scrollUp() })
                }
                // Bottom 20% — scroll down one viewport
                // Lifted 20 pt to clear the iOS home-indicator gesture area.
                .overlay(alignment: .bottom) {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: geo.size.height * 0.2)
                        .contentShape(Rectangle())
                        .padding(.bottom, 20)
                        .simultaneousGesture(TapGesture().onEnded { scrollDown() })
                }
            }
            .onAppear { viewportHeight = geo.size.height }
            .onChange(of: geo.size.height) { _, h in viewportHeight = h }
        }
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - Scroll

    private func scrollUp() {
        let target = max(0, scrollOffset - viewportHeight)
        scrollOffset = target   // update immediately so rapid taps use the correct offset
        withAnimation(.easeOut(duration: 0.2)) {
            scrollPosition.scrollTo(y: target)
        }
    }

    private func scrollDown() {
        let target = scrollOffset + viewportHeight
        scrollOffset = target   // update immediately so rapid taps use the correct offset
        withAnimation(.easeOut(duration: 0.2)) {
            scrollPosition.scrollTo(y: target)
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
