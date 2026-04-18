#if DEBUG
import SwiftData

/// Seeds deterministic test data when the app is launched with --uitesting.
/// All song names are fictional. Content uses chord-chart format (sections + chords, no lyrics).
enum UITestSeeder {
    @MainActor
    static func seed(in context: ModelContext) {
        // MARK: - Songs (varying content lengths)
        
        let noContent = ""

        let shortContent = """
        ## Verse
        G C / G C
        D Dsus4 D / C G C G
        (x2)

        ## Chorus
        C G / C G
        """

        let mediumContent = """
        ## Intro
        Am F (x4)

        ## Verse
        Am F / C G
        Am F / C G
        (x2)

        ## Pre-chorus
        Dm Am / F G

        ## Chorus
        C G / Am F
        C G / Am F
        C G

        ## Bridge
        F C Am Em D Dsus4 D (x2)

        ## Outro
        C G (x6)
        C Am
        """

        let longContent = """
        ## Intro
        Em C (x4)

        ## Verse 1
        Em C / Em C
        D Dsus4 D / C G C G
        (x2)

        ## Pre-chorus
        Am G / F Em
        Am G / Dm C

        ## Chorus
        G D / Em C
        G D / Em C
        G D / C

        ## Verse 2
        Em C / Em C
        D Dsus4 D / C G C G
        (x2)

        ## Pre-chorus
        Am G / F Em
        Am G / Dm C

        ## Chorus
        G D / Em C
        G D / Em C
        G D / C

        ## Bridge
        Am Em / F C
        Am Em / F C
        Dm Am / Bb F
        G Gsus4 G

        ## Solo
        (over Chorus chords x2)

        ## Chorus (big)
        G D / Em C
        G D / Em C
        G D / Em C
        G D / C

        ## Outro
        Em C (x8, fade)
        """

        let veryLongContent = """
        ## Intro
        Bm G D A (x4, building)

        ## Verse 1
        Bm G / D A
        Bm G / D A
        F#m Em / D A
        F#m Em / D A

        ## Verse 2
        Bm G / D A
        Bm G / D A
        F#m Em / D A
        F#m Em / D A

        ## Pre-chorus
        G A / Bm F#m
        G A / D

        ## Chorus
        D A / Bm G
        D A / Bm G
        Em F#m / G A
        D

        ## Interlude
        Bm G (x4)

        ## Verse 3
        Bm G / D A
        Bm G / D A
        F#m Em / D A
        F#m Em / D A

        ## Verse 4
        Bm G / D A
        Bm G / D A
        F#m Em / D A
        F#m Em / D A

        ## Pre-chorus
        G A / Bm F#m
        G A / D

        ## Chorus
        D A / Bm G
        D A / Bm G
        Em F#m / G A
        D

        ## Bridge
        G D / Em Bm
        G D / Em Bm
        C G / Am Em
        F#m G A Asus4 A

        ## Verse 5
        Bm G / D A
        Bm G / D A
        F#m Em / D A
        F#m Em / D A

        ## Verse 6
        Bm G / D A
        Bm G / D A
        F#m Em / D A
        F#m Em / D A

        ## Pre-chorus
        G A / Bm F#m
        G A / D

        ## Solo
        (over Verse chords x2)

        ## Chorus (key change up)
        Eb Bb / Cm Ab
        Eb Bb / Cm Ab
        Fm Gm / Ab Bb
        Eb

        ## Breakdown
        Cm Ab (x4, half time)
        Eb Bb / Cm Ab
        Eb Bb / Cm Ab

        ## Final Chorus
        Eb Bb / Cm Ab
        Eb Bb / Cm Ab
        Fm Gm / Ab Bb
        Eb Bb / Cm Ab
        Fm Gm / Ab Bb
        Eb

        ## Outro
        Eb Bb / Cm Ab (x8)
        Eb Bb / Eb
        (hold, fade)
        """

        let chordVarietyContent = """
        ## Verse
        A Bm / C#7 F#m7
        G Em / D A
        G Em D A (x2)

        ## Pre-chorus
        Dm7 Gsus4 / Bb F
        Eb Cm / Ab Fm

        ## Bridge
        F#m G A Asus4 A
        Bmaj7 Cmaj7#5 / D E

        ## Outro
        Am/G D/F# / Em C (x4, building)
        (hold, fade)
        """

        let songs = [
            Song(title: "Canal Morning", content: shortContent, reminder: "Capo 2"),
            Song(title: "Painted Sky", content: mediumContent),
            Song(title: "Run to Copperville", content: longContent, reminder: "Key of Em"),
            Song(title: "Passengers", content: veryLongContent),
            Song(title: "Bakery Lane", content: noContent),
            Song(title: "Velvet Dusk", content: mediumContent, reminder: "Slow tempo"),
            Song(title: "Thistlewood Fair", content: longContent),
            Song(title: "Paper Lanterns", content: mediumContent),
            Song(title: "Clocktower Waltz", content: noContent, reminder: "3/4 time"),
            Song(title: "Harbour Bell", content: noContent),
            Song(title: "Foxglove Road", content: longContent),
            Song(title: "Last Train Home", content: veryLongContent, reminder: "Build dynamics"),
            Song(title: "Chord Variety Test", content: chordVarietyContent, reminder: "All chord types"),
        ]

        for song in songs { context.insert(song) }

        // MARK: - Medleys

        let medleyA = Medley(name: "Folk Trio")
        context.insert(medleyA)
        medleyA.addEntry(MedleyEntry(song: songs[4]))  // Bakery Lane
        medleyA.addEntry(MedleyEntry(song: songs[8]))  // Clocktower Waltz
        medleyA.addEntry(MedleyEntry(song: songs[0]))  // Canal Morning

        let medleyB = Medley(name: "Evening Set")
        medleyB.displayMode = .combined
        context.insert(medleyB)
        medleyB.addEntry(MedleyEntry(song: songs[7]))  // Paper Lanterns
        medleyB.addEntry(MedleyEntry(song: songs[5]))  // Velvet Dusk

        // MARK: - Setlist with all entry types

        let setlist = Setlist(name: "Friday Night Gig")
        context.insert(setlist)

        // Build a realistic setlist order:
        // Song, Song, Song, Tacet, Medley, Song, Song, Song, Tacet, Medley, Song, Song
        setlist.addEntry(SetlistEntry(song: songs[0]))   // Canal Morning
        setlist.addEntry(SetlistEntry(song: songs[1]))   // Painted Sky
        setlist.addEntry(SetlistEntry(song: songs[2]))   // Run to Copperville

        let breakTacet = Tacet(label: "Break")
        context.insert(breakTacet)
        setlist.addEntry(SetlistEntry(tacet: breakTacet))

        setlist.addEntry(SetlistEntry(medley: medleyA))  // Folk Trio medley
        setlist.addEntry(SetlistEntry(song: songs[3]))   // Passengers (very long)
        setlist.addEntry(SetlistEntry(song: songs[5]))   // Velvet Dusk
        setlist.addEntry(SetlistEntry(song: songs[6]))   // Thistlewood Fair

        let encoreTacet = Tacet(label: "Encore")
        context.insert(encoreTacet)
        setlist.addEntry(SetlistEntry(tacet: encoreTacet))

        setlist.addEntry(SetlistEntry(medley: medleyB))  // Evening Set medley
        setlist.addEntry(SetlistEntry(song: songs[9]))   // Harbour Bell
        setlist.addEntry(SetlistEntry(song: songs[11]))  // Last Train Home
        setlist.addEntry(SetlistEntry(song: songs[12]))  // Chord Variety Test

        try? context.save()
    }
}
#endif
