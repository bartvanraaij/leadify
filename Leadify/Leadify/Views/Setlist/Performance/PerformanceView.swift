import SwiftUI

struct PerformanceView: View {
    let setlist: Setlist
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PerformanceViewModel

    init(setlist: Setlist) {
        self.setlist = setlist
        self._viewModel = State(initialValue: PerformanceViewModel(entries: setlist.sortedEntries))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            PerformanceTheme.background
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(setlist.sortedEntries) { entry in
                            let id = viewModel.entryID(entry)
                            Group {
                                switch entry.itemType {
                                case .song:
                                    SongBlock(song: entry.song!, entryID: id, viewModel: viewModel)
                                case .tacet:
                                    TacetBlock(tacet: entry.tacet!, entryID: id, viewModel: viewModel)
                                }
                            }
                            .id(id)
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 80)
                }
                .overlay(alignment: .top) {
                    tapZone(direction: .up) {
                        if let target = viewModel.snapUpTargetID {
                            withAnimation { proxy.scrollTo(target, anchor: .top) }
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    tapZone(direction: .down) {
                        if let target = viewModel.snapDownTargetID {
                            withAnimation { proxy.scrollTo(target, anchor: .top) }
                        }
                    }
                    // Lift the tap zone 60 pt above the safe-area bottom so it clears
                    // the iOS home-indicator gesture zone.
                    .padding(.bottom, 60)
                }
            }

            if let upNext = viewModel.upNextSong {
                HStack {
                    Spacer()
                    Text("next: \(upNext.title)")
                        .font(.system(size: PerformanceTheme.upNextSize))
                        .foregroundStyle(PerformanceTheme.upNextColor)
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                }
                .allowsHitTesting(false)
            }
        }
        // No .ignoresSafeArea() here — ScrollView overlays must stay above the
        // system home-gesture zone. The background Color has its own .ignoresSafeArea().
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
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

    // MARK: - Tap Zones

    enum TapDirection { case up, down }

    @ViewBuilder
    private func tapZone(direction: TapDirection, action: @escaping () -> Void) -> some View {
        Rectangle()
            .foregroundStyle(Color.clear)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .contentShape(Rectangle())
            .overlay(alignment: direction == .up ? .top : .bottom) {
                Image(systemName: direction == .up ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(PerformanceTheme.tapZoneIndicatorColor)
                    .padding(8)
            }
            .onTapGesture { action() }
    }
}
