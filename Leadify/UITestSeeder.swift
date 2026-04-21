#if DEBUG
import SwiftData

/// Seeds deterministic test data when the app is launched with --uitesting.
/// All song names are fictional. Content uses chord-chart format (sections + chords, no lyrics).
enum UITestSeeder {
    @MainActor
    static func seed(in context: ModelContext) {
        // MARK: - Songs (short trigger sheets, like real gig use)

        let songs = [
            // Title-only — known by heart
            Song(title: "Canal Morning", content: ""),
            Song(title: "Bakery Lane", content: ""),
            Song(title: "Harbour Bell", content: "", reminder: "3/4 time"),
            Song(title: "Clocktower Waltz", content: ""),

            // One-liner chords
            Song(title: "Painted Sky", content: "Cm G Eb Fm G"),
            Song(title: "Velvet Dusk", content: "Am F C G", reminder: "Capo 2"),
            Song(title: "Paper Lanterns", content: "D Bm G A"),

            // A few sections
            Song(title: "Foxglove Road", content: """
            # Refrein
            E B7 A G# C#m
            E B7 A G# C#m C#m A G#

            ## Couplet
            C#m G#m F# B G# C#m (2x)

            ## Pre-refrein
            E B7 G#7 C#m
            E B7 A G#
            C#m
            """, reminder: "Key of E"),

            Song(title: "Thistlewood Fair", content: """
            ## Verse
            G C / G C
            D Dsus4 D / C G C G (x2)

            ## Chorus
            C G / Am F
            C G / Am F
            C G
            """),

            Song(title: "Run to Copperville", content: """
            ## Intro
            Am F (x4)

            ## Verse
            Am F / C G
            Am F / C G (x2)

            ## Chorus
            Dm Am / F G
            C G / Am F
            """, reminder: "Slow build"),

            // Long — with tabs
            Song(title: "Last Train Home", content: """
            ## Intro
            ```
            e|-------------------------------|
            B|12-13-12-x-x-x-12-13-12-13-12--|
            G|12-12-12-x-x-x-12-12-12-12-12--|
            D|12-------x-x-x-12--------------|
            A|---------x-x-x-----------------|
            E|-------------------------------|
            ```

            ## Couplet
            G Em
            G C G Am G D (2x)

            ## Refrein
            ```
            e|-----------------------------------------------7----|
            B|-5-----6-6---5-5-----6-6---5-5-----5----------------|
            G|-5-7-5-5-5---5-5-7-5-5-5---5-5-7-5---7-7-7-6/7------|
            D|-5-----------5-5-----------5-5----------------------|
            A|----------------------------------------------------|
            E|----------------------------------------------------|
            ```
            """, reminder: "Build dynamics"),

            // Extra songs for medleys
            Song(title: "Passengers", content: "F#m D A E"),
            Song(title: "Riverside Glow", content: ""),
        ]

        for song in songs { context.insert(song) }

        // MARK: - Medleys

        let medleyA = Medley(name: "Folk Trio")
        context.insert(medleyA)
        medleyA.addEntry(MedleyEntry(song: songs[1]))   // Bakery Lane
        medleyA.addEntry(MedleyEntry(song: songs[3]))   // Clocktower Waltz
        medleyA.addEntry(MedleyEntry(song: songs[0]))   // Canal Morning

        let medleyB = Medley(name: "Evening Set")
        medleyB.displayMode = .combined
        context.insert(medleyB)
        medleyB.addEntry(MedleyEntry(song: songs[6]))   // Paper Lanterns
        medleyB.addEntry(MedleyEntry(song: songs[5]))   // Velvet Dusk

        // MARK: - Setlist with all entry types

        let setlist = Setlist(name: "Friday Night Gig")
        context.insert(setlist)

        setlist.addEntry(SetlistEntry(song: songs[0]))   // Canal Morning (empty)
        setlist.addEntry(SetlistEntry(song: songs[4]))   // Painted Sky (one-liner)
        setlist.addEntry(SetlistEntry(song: songs[7]))   // Foxglove Road (few sections)

        let breakTacet = Tacet(label: "Break")
        context.insert(breakTacet)
        setlist.addEntry(SetlistEntry(tacet: breakTacet))

        setlist.addEntry(SetlistEntry(medley: medleyA))  // Folk Trio medley
        setlist.addEntry(SetlistEntry(song: songs[12]))  // Passengers (one-liner)
        setlist.addEntry(SetlistEntry(song: songs[5]))   // Velvet Dusk (one-liner)
        setlist.addEntry(SetlistEntry(song: songs[8]))   // Thistlewood Fair (short)

        let encoreTacet = Tacet(label: "Encore")
        context.insert(encoreTacet)
        setlist.addEntry(SetlistEntry(tacet: encoreTacet))

        setlist.addEntry(SetlistEntry(medley: medleyB))  // Evening Set medley
        setlist.addEntry(SetlistEntry(song: songs[2]))   // Harbour Bell (empty)
        setlist.addEntry(SetlistEntry(song: songs[11]))  // Last Train Home (long, tabs)
        setlist.addEntry(SetlistEntry(song: songs[9]))   // Run to Copperville (medium)

        try? context.save()
    }
}
#endif
