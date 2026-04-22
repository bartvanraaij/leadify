#if DEBUG
import SwiftData
import LeadifyCore

/// Seeds deterministic test data when the app is launched with --uitesting.
/// All song names are fictional. Content uses chord-chart format (sections + chords, no lyrics).
enum UITestSeeder {
    @MainActor
    static func seed(in context: ModelContext) {
        // MARK: - Songs (57 sheets, fictional titles, real chord content)

        let songs = [
            // 0: All the small things
            Song(title: "Tiny Satellites", content: """
            ## Intro
            C Csus4 G Am F (x2)

            ## Couplet
            C G F G (x4)

            ## Pre-refrein
            C G F C

            ## Refrein
            C G F (x2)
            """),

            // 1: Atemlos
            Song(title: "Breathless Night", content: """
            ## Intro
            B G#m

            ## Couplet
            B G#m F# B (x2)

            ## Refrein
            E B F# G#m F#
            """, reminder: "Solo G#m"),

            // 2: Baby One More Time
            Song(title: "One Last Chance", content: "Cm G Eb Fm G"),

            // 3: Baila
            Song(title: "Danza del Sol", content: """
            ## Intro
            D Dsus4

            ## Couplet
            D A G
            D A G D

            # Refrein
            A G D
            """),

            // 4: Belgie
            Song(title: "Flatland Blues", content: """
            ## Intro
            Cm Eb F# Fm Bb7 Eb

            ## Couplet (waar kan)
            Cm Eb

            ## Kwil niet
            Bb7 Ab Bb7 → Ab G7

            ## Refrein (is er leven)
            Ab Bb Gm7 Eb Fm → Bb

            ```
            e|8-11-8-11-8-11-8-11-13-11|
            B|9-9--9-9--9-9--9-9--9--9-|
            ```

            ```
            e|-11-8-6-8-11-8-6-8-|
            B|-9--9-9-9-9--9-9-9-|
            ```

            ## België
            B B/C# F#
            D#m G# C# B C# A#m D#m7

            ## Sectie
            B C# D#m

            ## Sectie
            B G#m7 Emaj7 C#m7 D#m E F#
            """, reminder: "Solo Cm / Gm pent"),

            // 5: Bestel mar
            Song(title: "Another Round", content: "F C"),

            // 6: Blauw
            Song(title: "Indigo Haze", content: "G C2"),

            // 7: Blikkendag
            Song(title: "Tin Can Parade", content: "Bb Eb F"),

            // 8: Born This Way
            Song(title: "Born to Shine", content: """
            F# E B

            ## Interlude
            C#m
            """),

            // 9: Cosy in my mind
            Song(title: "Warm Inside", content: "A B C#"),

            // 10: Crazy Little Thing Called Love
            Song(title: "Silly Little Crush", content: """
            ## Couplet
            D G C G (2x)
            D Bb C D

            ## Refrein
            G C G
            Bb E A
            F E A
            """, reminder: "tot git solo - meteen door"),

            // 11: Dansen op de vulkaan
            Song(title: "Volcano Stomp", content: """
            ## Intro
            B G D F#

            B D E G
            B D E D E D B F#

            ## Couplet
            B B A G#m → E F#

            ## Refrein
            B G D F#

            ## Pianosolo
            B E
            """),

            // 12: De Troubadour
            Song(title: "The Wandering Minstrel", content: """
            # Refrein (La La La La)
            E B7 A G# C#m
            E B7 A G# C#m C#m A G#

            ## Couplet
            C#m G#m F# B G# C#m (2x)

            ## Pre-refrein
            E B7 G#7 C#m
            E B7 A G#
            C#m
            """),

            // 13: Does Your Mother Know
            Song(title: "Parental Advisory", content: """
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
            """),

            // 14: Du
            Song(title: "Für Dich", content: """
            ## Intro
            B F# F#6 F# B Bsus4 B B6 B
            B6 B Bsus4 B Badd9 F#

            ```
            e|-4-2-4---4-2-4---4-2-4---|
            B|-4---4---4---4---4---4---|
            G|-4---4---4---4---4---4---|
            D|-------------------------|
            ```

            ```
            e|-2-0-2---2-0-2---2-0-2---|
            B|-4---4---4---4---4---4---|
            G|-4---4---4---4---4---4---|
            D|-------------------------|
            ```

            ## Couplet
            B F#7 B B7
            E B F#7
            B F#7 B
            B F#7 B D E

            ## Refrein
            A E
            A B7
            E A E
            E A F#
            """),

            // 15: Echte Liefde is te koop
            Song(title: "Love for Sale", content: """
            ## Intro
            tacet (Db Ab Bm Gb)

            ## Pre-refrein
            Db Db-Ab
            Ab-Bbm
            Bm Gb (2x)

            ## Refrein
            Db Ab Bm Gb (4x)

            ## Bridge
            Bm Ab Db → Eb Db Ab Ab
            """),

            // 16: Engelbewaarder
            Song(title: "Guardian Angel", content: """
            ## Intro
            G# D# G#

            ## Refrein
            G# C# G# G#
            G# D# G# G#

            ## Couplet
            G# C# G# C#
            """, reminder: "tsw +½"),

            // 17: Everybody Get Up
            Song(title: "Get On Your Feet", content: ""),

            // 18: Final countdown
            Song(title: "Last Countdown", content: """
            ## Intro
            F#m D Bm E
            F#m A D C#sus4 C#

            ## Refrein
            F#m D Bm E (2x)

            ## Couplet
            F#m Bm
            F#m E A
            D E
            A E F#m E D
            C#m E
            """),

            // 19: Gimme Gimme Gimme
            Song(title: "Give It All", content: """
            ## Intro / Refrein
            ```
            e|--10-10-12-10----|
            B|-10-10-10-10-13--|
            ```
            ```
            e|--10-10-12-10-12-10-8-|
            B|-10-10-10-10---------|
            ```
            Dm Edim F Am → Dm

            ## Couplet
            ```
            e|-5-3-1-0------|
            B|---------3-1--|
            ```

            ## Pre-Chorus
            Bb Gm6 Dm/A A
            """),

            // 20: Girl
            Song(title: "She Vanished", content: """
            ## Couplet
            C#m A E B/D#

            ## Pre-refrein
            F#m A

            ## Refrein
            E Bsus4 Asus2
            F#7sus4 Asus2
            """, reminder: "tot aan gitsolo"),

            // 21: Hey Wir Wollen Eisbaren Sehn
            Song(title: "Polar Bear Chant", content: """
            ## Refrein
            Fm Db Ab Eb Ab Eb (2x)
            Db Eb Ab Db
            Ab Eb Ab Db Ab Eb Ab

            ## Intro (soli-ish)
            Fm

            ## Couplet
            Fm Db Ab Eb Ab Eb (2x)
            Fm Db Ab Eb Ab Eb Fm Db Eb
            """, reminder: "meteen door vanaf vorige"),

            // 22: Highway To Hell
            Song(title: "Road to Ruin", content: ""),

            // 23: Iedereen is van de wereld
            Song(title: "World Belongs to All", content: """
            ## Couplet / Refrein
            B D E B

            ## Pre-refrein
            B A E B

            ## Saxsolo
            E

            ## Gitaarsolo
            ```
            e|-12-14-16-14-12-14-16-19-|
            B|-------------------------|
            ```
            """),

            // 24: I Gotta Feeling
            Song(title: "Electric Tonight", content: ""),

            // 25: Ik moet zuipen
            Song(title: "Pour Me Another", content: """
            ## Refrein
            C G Am F G

            ## Couplet
            C Am F Am G
            """),

            // 26: Ik Wil Je
            Song(title: "I Need You Now", content: """
            ## Intro
            Gm7

            ## Couplet
            Gm7 Eb F

            ## Refrein
            Bb Gm7 EbM7 F
            """),

            // 27: Its My Life
            Song(title: "This Is Mine", content: """
            ## Couplet
            Cm Cm Cm → Cm Ab F

            ## Refrein
            Cm Ab Eb Bb
            Cm Ab Bb Bdim (7-8-9-xxx)
            """, reminder: "direct op Cm"),

            // 28: I Was Made For Lovin You
            Song(title: "Made for You", content: """
            ## Refrein
            ```
            e|-----5-8-5--------5-8-5--------|
            B|-5-8-------8-5--5-------8-5----|
            G|----------------------------7--|
            ```

            ## Couplet
            Em G B (A)
            """, reminder: "kort intro, refrein, couplet, 2x refrein"),

            // 29: Je loog tegen mij
            Song(title: "You Lied to Me", content: """
            ## Couplet
            A E D A
            F#m E D
            F#m E
            D A A

            ## Refrein
            A E D
            A Bm E
            D A
            """),

            // 30: Jij krijgt die lach
            Song(title: "That Smile of Yours", content: """
            ## Couplet
            Bbm Ebm Bbm
            Ebm F Bbm
            Ebm Bbm
            F Bbm

            ## Refrein
            Eb Bb F Bb

            ## Interlude
            Bbm Ebm F Bbm
            """, reminder: "tsw +½"),

            // 31: Kleine vogel
            Song(title: "Little Sparrow", content: """
            ## Intro
            D C G Em7

            ## Couplet
            D Em A7 D
            D D7 G
            D Em A D

            ## Refrein
            D Em A7 D
            D G D Bm Em A D
            """),

            // 32: Kom van dat dak af
            Song(title: "Off the Roof", content: """
            ## Refrein
            F Bb7 F C7 Bb7 F C7

            ## Couplet
            F Bb7 C7
            """),

            // 33: Laat maar waaien
            Song(title: "Let It Blow", content: """
            ## Intro
            D G Bm
            D G A

            ## Refrein
            D G D
            D A
            """),

            // 34: Let Me Entertain You
            Song(title: "Here for the Show", content: "F G# A# F"),

            // 35: Livin on a Prayer
            Song(title: "Halfway There", content: ""),

            // 36: Malle babbe
            Song(title: "Crazy Barbara", content: """
            ## Couplet
            Ebm Db B Bb

            ## En bij nacht
            Gb Db Bb Ebm Bb

            ## Refrein
            Eb Bb Ab Eb

            ## Zondags
            Bb F Eb F Db Ab
            """, reminder: "tsw +1½"),

            // 37: Mamma Mia
            Song(title: "Here We Go Again", content: """
            ## Intro
            ```
            e|-5--4-5--4-5-4-5-9-7-5-4-|
            B|--------------------------|
            ```

            ## Couplet
            ```
            e|-9---9---9---9---|
            B|-10--10--10--10--|
            G|-9---9---9---9---|
            ```

            ## Just one look
            ```
            e|-----9-12-9--------9-12-9-------|
            B|-10---------12-10---------12-10-|
            ```

            ## Yes I've been broken hearted
            ```
            e|--12b14-12-10-12b14-12-10-|
            B|--12b14-12-10-------------|
            ```

            ```
            e|-10-9-10-12-10-9-10-12-13-|
            B|--------------------------|
            ```
            """),

            // 38: Narcotic
            Song(title: "Chemical Bliss", content: """
            C# D#m F# C#

            ## Cosy in my mind
            A B C#
            """),

            // 39: Oerend hard
            Song(title: "Thunder Road", content: """
            ## Couplet
            A E7 E
            E A D A
            E F E A

            ## Refrein
            D A E A (2x)
            """),

            // 40: Oya lele
            Song(title: "Island Breeze", content: """
            ## Intro
            A

            ## Refrein
            Dm C Bb F BbM7/E A

            ## Couplet
            Dm F Gm A Dm
            F Gm A Dm

            ## Pre-refrein
            G F A Bb
            Gm F G6
            """),

            // 41: Radar Love
            Song(title: "Signal Lock", content: """
            ## Intro
            ```
            e|-7-7-7-7-7-7-7-7-|
            B|-8-8-8-8-8-8-8-8-|
            G|-7-7-7-7-7-7-7-7-|
            ```

            ## Pre-refrein
            E B F# → C#

            ## Refrein
            D A E F# → D A E

            ## Riff 2
            ```
            e|-0-0-0-0-3-0-0-0-|
            B|-0-0-0-0-0-0-0-0-|
            G|-1-1-1-1-1-1-1-1-|
            ```

            ## Instrumentaal
            ```
            e|-12-12-14-12-----|
            B|-------------15--|
            G|-----------------|
            ```
            ```
            G|-2-2-4-2-0-2---|
            D|-0-0-0-0-0-0---|
            ```
            """),

            // 42: Schijn een lichtje op mij
            Song(title: "Shine a Light", content: "Gb Db Ab Db", reminder: "Direct inzetten"),

            // 43: Sex On Fire
            Song(title: "Burning Desire", content: """
            ## Refrein (direct)
            E C#m A (2x)

            ## Couplet
            E C#m
            E C#m A

            ```
            e|-12-12-14-12-11-12-|
            B|-------------------|
            ```

            ```
            e|-4-4-2-4-0--------|
            B|-----------4-2-0--|
            ```
            """),

            // 44: Smells Like Teen Spirit
            Song(title: "Teenage Riot", content: "Fm Bbm Ab Db", reminder: "in F"),

            // 45: Stiekem gedanst
            Song(title: "Secret Dance", content: """
            ## Couplet
            G Bm G Bm (2x)
            Em D C D G

            ## Refrein
            Am G G Bm
            Am G C G

            ## Bridge
            Am E Am AM
            Am E D D

            ## Solo
            Em pent
            """),

            // 46: Stil in mij
            Song(title: "Quiet Within", content: """
            ## Couplet
            Em C D Dsus4 D7
            C G C G

            ## Refrein
            C G

            ## Bridge
            F C Am Em D

            ## Einde
            C G → Em
            """, reminder: "Capo 4"),

            // 47: Summer of 69
            Song(title: "Summer of '89", content: """
            ## Couplet
            D A

            ## Refrein
            Bm A D G

            ## Bridge
            F Bb C Bb
            """),

            // 48: Sweet Child O Mine
            Song(title: "Golden Child", content: "", reminder: "tot aan \"where do we go\""),

            // 49: Terug in de tijd
            Song(title: "Rewind the Clock", content: """
            ## Intro
            Ab

            ## Verse
            Ab Cm7 Db
            Ab Bbm7 Db Eb7
            Ab Cm7 Db Ab
            Bbm7 Db Eb7

            ## Chorus
            Ab Eb7 Db
            Ab Bbm7 Db Eb7sus4
            Eb7 Cm7 Fm7
            Db Eb7 Ab

            ## Bridge
            Fm7 Bbm7 Eb7 Cm7
            Db Eb7 F7
            """, reminder: "tsw +1"),

            // 50: Vanavond uit mn bol
            Song(title: "Tonight We Fly", content: """
            ## Couplet
            C G Am F G

            ## Pre-refrein
            C G Dm F G

            ## Refrein
            C G Am F G
            Dm G C Am
            Dm G C
            """, reminder: "beginnen met slagje"),

            // 51: Verdammt ich lieb dich
            Song(title: "Damn I Love You", content: """
            ## Couplet
            C G Am G
            C G F G Am F G

            ## Refrein
            C G Dm Am G
            C G F Am G Am
            """),

            // 52: Wannabe
            Song(title: "Tell Me What You Want", content: "B D E A B"),

            // 53: What's up
            Song(title: "What Goes On", content: "A Bm D A"),

            // 54: Wie kan mij vertellen
            Song(title: "Who Can Tell Me", content: """
            ## Couplet
            F#m Dmaj7 Bm E (2x)
            Bm Bm Bm C# F#m E

            ## Refrein
            A F#m Bm E
            """),

            // 55: You Give Love A Bad Name
            Song(title: "Love Gone Wrong", content: "", reminder: "na acappela direct door"),

            // 56: Zombie
            Song(title: "Undead March", content: "E C G D/F#", reminder: "direct intro hard"),
        ]

        for song in songs { context.insert(song) }

        // MARK: - Medleys

        let feest1 = Medley(name: "Feest 1")
        context.insert(feest1)
        feest1.addEntry(MedleyEntry(song: songs[25]))  // Pour Me Another
        feest1.addEntry(MedleyEntry(song: songs[32]))  // Off the Roof
        feest1.addEntry(MedleyEntry(song: songs[7]))   // Tin Can Parade
        feest1.addEntry(MedleyEntry(song: songs[50]))  // Tonight We Fly

        let feest2 = Medley(name: "Feest 2")
        context.insert(feest2)
        feest2.addEntry(MedleyEntry(song: songs[5]))   // Another Round
        feest2.addEntry(MedleyEntry(song: songs[34]))  // Here for the Show
        feest2.addEntry(MedleyEntry(song: songs[52]))  // Tell Me What You Want
        feest2.addEntry(MedleyEntry(song: songs[1]))   // Breathless Night

        let rock1 = Medley(name: "Rock 1")
        context.insert(rock1)
        rock1.addEntry(MedleyEntry(song: songs[22]))   // Road to Ruin
        rock1.addEntry(MedleyEntry(song: songs[47]))   // Summer of '89
        rock1.addEntry(MedleyEntry(song: songs[48]))   // Golden Child
        rock1.addEntry(MedleyEntry(song: songs[55]))   // Love Gone Wrong

        let rock2 = Medley(name: "Rock 2")
        rock2.displayMode = .combined
        context.insert(rock2)
        rock2.addEntry(MedleyEntry(song: songs[27]))   // This Is Mine
        rock2.addEntry(MedleyEntry(song: songs[35]))   // Halfway There
        rock2.addEntry(MedleyEntry(song: songs[56]))   // Undead March

        let nederpop1 = Medley(name: "Nederpop 1")
        context.insert(nederpop1)
        nederpop1.addEntry(MedleyEntry(song: songs[6]))   // Indigo Haze
        nederpop1.addEntry(MedleyEntry(song: songs[33]))  // Let It Blow
        nederpop1.addEntry(MedleyEntry(song: songs[46]))  // Quiet Within
        nederpop1.addEntry(MedleyEntry(song: songs[45]))  // Secret Dance

        // MARK: - Setlist

        let setlist = Setlist(name: "Friday Night Gig")
        context.insert(setlist)

        // Set 1
        setlist.addEntry(SetlistEntry(song: songs[0]))    // Tiny Satellites
        setlist.addEntry(SetlistEntry(song: songs[43]))   // Burning Desire
        setlist.addEntry(SetlistEntry(song: songs[10]))   // Silly Little Crush
        setlist.addEntry(SetlistEntry(medley: feest1))    // Feest 1
        setlist.addEntry(SetlistEntry(song: songs[12]))   // The Wandering Minstrel
        setlist.addEntry(SetlistEntry(song: songs[41]))   // Signal Lock
        setlist.addEntry(SetlistEntry(medley: rock1))     // Rock 1
        setlist.addEntry(SetlistEntry(song: songs[4]))    // Flatland Blues
        setlist.addEntry(SetlistEntry(song: songs[19]))   // Give It All

        let breakTacet = Tacet(label: "Pauze")
        context.insert(breakTacet)
        setlist.addEntry(SetlistEntry(tacet: breakTacet))

        // Set 2
        setlist.addEntry(SetlistEntry(song: songs[39]))   // Thunder Road
        setlist.addEntry(SetlistEntry(medley: nederpop1))  // Nederpop 1
        setlist.addEntry(SetlistEntry(song: songs[49]))   // Rewind the Clock
        setlist.addEntry(SetlistEntry(song: songs[13]))   // Parental Advisory
        setlist.addEntry(SetlistEntry(medley: feest2))    // Feest 2
        setlist.addEntry(SetlistEntry(song: songs[29]))   // You Lied to Me
        setlist.addEntry(SetlistEntry(song: songs[40]))   // Island Breeze
        setlist.addEntry(SetlistEntry(medley: rock2))     // Rock 2
        setlist.addEntry(SetlistEntry(song: songs[14]))   // Für Dich

        let encoreTacet = Tacet(label: "Encore")
        context.insert(encoreTacet)
        setlist.addEntry(SetlistEntry(tacet: encoreTacet))

        setlist.addEntry(SetlistEntry(song: songs[37]))   // Here We Go Again
        setlist.addEntry(SetlistEntry(song: songs[51]))   // Damn I Love You
        setlist.addEntry(SetlistEntry(song: songs[24]))   // Electric Tonight

        try? context.save()
    }
}
#endif
