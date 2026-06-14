import 'package:flutter/material.dart';

import '../models/mystery_models.dart';
import '../theme/app_theme.dart';

List<GamePhase> buildDefaultPhases() {
  return const [
    GamePhase(
      id: 'intro',
      title: 'Vorstellung',
      description:
          'Die Gruppe findet zusammen, erste Fassaden werden aufgebaut und jedes Detail kann spaeter wichtig werden.',
      durationMinutes: 8,
      musicCue: 'Gedimmte Streicher und Regen am Fenster',
      soundEffects: ['Donner in der Ferne', 'Leises Knistern des Kamins'],
      autoHintIds: [],
    ),
    GamePhase(
      id: 'conversation',
      title: 'Freie Gespraeche',
      description:
          'Freie Begegnungen, subtile Allianzen und erste Widersprueche. Jetzt entstehen die spannendsten Vermutungen.',
      durationMinutes: 12,
      musicCue: 'Sanftes Jazz-Piano mit tiefer Basslinie',
      soundEffects: ['Glasklirren', 'Schritte im Flur'],
      autoHintIds: ['hint_a'],
    ),
    GamePhase(
      id: 'clues',
      title: 'Hinweise',
      description:
          'Die ersten belastbaren Spuren werden sichtbar. Wer clever kombiniert, gewinnt das Vertrauen des Tisches.',
      durationMinutes: 10,
      musicCue: 'Streicher mit tickender Uhr',
      soundEffects: ['Umschlag wird geoeffnet', 'Papier raschelt'],
      autoHintIds: ['hint_b'],
    ),
    GamePhase(
      id: 'intel',
      title: 'Neue Informationen',
      description:
          'Die Geschichte kippt. Geheimnisse werden aufgedeckt und alte Aussagen sehen ploetzlich ganz anders aus.',
      durationMinutes: 8,
      musicCue: 'Dunkle Celli mit fernem Chor',
      soundEffects: ['Mechanisches Schloss', 'Flackernde Lampe'],
      autoHintIds: ['hint_c'],
    ),
    GamePhase(
      id: 'accusation',
      title: 'Verdaechtigungen',
      description:
          'Jetzt wird offen konfrontiert. Jede Behauptung muss sitzen, denn die Fronten sind verhaertet.',
      durationMinutes: 10,
      musicCue: 'Pulsierende Tieftonflaechen',
      soundEffects: ['Gedrosselte Trommelschlaege', 'Hektisches Fluester'],
      autoHintIds: ['hint_d'],
    ),
    GamePhase(
      id: 'vote',
      title: 'Abstimmung',
      description:
          'Die finale Entscheidung faellt. Ein letzter Blick in die Gesichter verrraet oft mehr als Worte.',
      durationMinutes: 5,
      musicCue: 'Stille, nur Uhrticken bleibt',
      soundEffects: ['Feder auf Papier', 'Stuhl rueckt'],
      autoHintIds: ['hint_e'],
    ),
    GamePhase(
      id: 'reveal',
      title: 'Aufloesung',
      description:
          'Der Fall wird enthuellt, Rollen treffen auf Wahrheit und jede Szene bekommt ihre eigentliche Bedeutung.',
      durationMinutes: 6,
      musicCue: 'Triumphaler Spannungsbogen mit Goldklang',
      soundEffects: ['Briefsiegel bricht', 'Erleichtertes Aufatmen'],
      autoHintIds: ['hint_f'],
    ),
  ];
}

OutfitSuggestion _outfit({
  required String masculine,
  required String feminine,
  required String neutral,
  required List<String> accessories,
  required String makeup,
  required String hairstyle,
  required BudgetTier budget,
  required List<String> palette,
}) {
  return OutfitSuggestion(
    masculine: masculine,
    feminine: feminine,
    neutral: neutral,
    accessories: accessories,
    makeup: makeup,
    hairstyle: hairstyle,
    budget: budget,
    palette: palette,
  );
}

final List<MysteryCase> demoMysteryCases = [
  MysteryCase(
    id: 'villa_no_7',
    title: 'Villa No. 7',
    tagline: 'Ein Testament verschwindet, bevor der Nachtisch serviert ist.',
    description:
        'In einer abgelegenen Luxusvilla endet die Feier des Industriellen Adrian Voss in einem Mord. Zwischen Seidenvorhaengen, einem versiegelten Wintergarten und alten Familiengeheimnissen ringt die Runde um Wahrheit und Fassade.',
    category: MysteryCategory.luxuryVilla,
    playerMin: 4,
    playerMax: 6,
    durationMinutes: 110,
    difficulty: CaseDifficulty.sharp,
    recommendedAge: '16+',
    atmosphere:
        'Glamour, Knistern und kalter Verrat in einer regennassen Villa.',
    materials: const [
      'Kerzenlicht',
      'Weinglaeser',
      'Alte Briefe',
      'Notizkarten'
    ],
    coverColors: const [AppPalette.noir, AppPalette.wine, AppPalette.gold],
    highlights: const [
      'Statische Villa mit geheimer Bibliothek',
      'Verdichtete Familienintrige',
      'Elegante Gold- und Weinrot-Akzente',
    ],
    roles: [
      MysteryRole(
        id: 'isabel',
        name: 'Isabel Voss',
        avatar: 'IV',
        persona:
            'Charismatische Tochter des Hauses mit messerscharfer Selbstkontrolle.',
        secret:
            'Sie hat gestern Nacht eine neue Version des Testaments aus dem Safe genommen.',
        motive:
            'Sie will verhindern, dass das Familienvermoegen an einen Fremden faellt.',
        relationships:
            'Misstraut Nora, deckt Lucien halbherzig und verachtet Matthias.',
        goal:
            'Den Fokus auf die angeblich verschwundenen Geschaeftsakten lenken.',
        alibi:
            'War waehrend des Stromausfalls in der Orangerie und suchte nach ihrem Vater.',
        suspicion: 'Sie bemerkte Goldstaub am Handschuh des Captains.',
        hiddenClues: const [
          'Kennt die genaue Reihenfolge der Serviergaenge.',
          'Weiss, dass jemand die Bibliothekstuer von innen verriegelte.',
        ],
        outfit: _outfit(
          masculine: 'Schwarzer Samtblazer mit goldener Brosche',
          feminine: 'Dunkelblaue Abendrobe mit strukturierten Schultern',
          neutral: 'Strenges Satinensemble mit antikem Taschenuhr-Detail',
          accessories: [
            'Siegellack-Ring',
            'Seidenhandschuhe',
            'Notizbuch aus Leder'
          ],
          makeup: 'Mattes Augen-Make-up mit dunklem Lippenakzent.',
          hairstyle: 'Glatte Ruecknahme oder tiefer Sleek-Bun.',
          budget: BudgetTier.premium,
          palette: const ['Schwarz', 'Gold', 'Mitternachtsblau'],
        ),
      ),
      MysteryRole(
        id: 'lucien',
        name: 'Lucien Marot',
        avatar: 'LM',
        persona:
            'Hauspianist mit eleganter Fassade und gefaehrlich gutem Gehoer.',
        secret:
            'Er belauschte ein Gespraech ueber eine illegale Zahlung im Weinkeller.',
        motive:
            'Adrian versprach ihm Freiheit von alten Schulden und brach das Wort.',
        relationships:
            'Fuehlt sich Isabel verbunden, fuerchtet Nora und provoziert Elias.',
        goal: 'Den Verdacht auf die verschwundene Weinkiste lenken.',
        alibi:
            'Spielte waehrend des Toasts allein im Salon, bis das Licht ausfiel.',
        suspicion: 'Der Priester roch unerwartet nach Maschinenoel.',
        hiddenClues: const [
          'Hat einen abgerissenen Manschettenknopf gefunden.',
          'Kennt die Melodie, die kurz vor dem Schrei abrupt stoppte.',
        ],
        outfit: _outfit(
          masculine: 'Bordeauxroter Dinnerjacket-Look mit schwarzem Rollkragen',
          feminine: 'Androgyner Smoking mit seidigem Rueckenpanel',
          neutral: 'Schmal geschnittenes Monochrom-Outfit mit Taschenuhr',
          accessories: ['Lackschuhe', 'Notenblaetter', 'Goldene Nadel'],
          makeup: 'Leichter Schatten unter den Augen fuer dramatische Tiefe.',
          hairstyle: 'Scharf zurueckgekammtes Haar oder lockerer Wave-Look.',
          budget: BudgetTier.midrange,
          palette: const ['Weinrot', 'Schwarz', 'Champagner'],
        ),
      ),
      MysteryRole(
        id: 'nora',
        name: 'Nora Vale',
        avatar: 'NV',
        persona:
            'Investigative Journalistin, die sich als Kunstberaterin ausgibt.',
        secret:
            'Sie kam mit Beweisen gegen Adrians Schwarzgeldnetzwerk zur Feier.',
        motive:
            'Sie wollte ein Geständnis und ihre verschwundene Schwester raechen.',
        relationships:
            'Traut niemandem, aber Elias kennt einen Teil ihrer wahren Identitaet.',
        goal: 'Eine Person dazu bringen, ueber die Lieferlisten zu sprechen.',
        alibi: 'War im Foyer, als die Villa kurzzeitig verriegelt wurde.',
        suspicion: 'Jemand hat ihre Kamera kurz vor dem Mord deaktiviert.',
        hiddenClues: const [
          'Sie kennt den geheimen Nebeneingang zur Bibliothek.',
          'Sie sah einen blutigen Abdruck an der Servierglocke.',
        ],
        outfit: _outfit(
          masculine:
              'Steingrauer Mantel mit schwarzem Kragen und Satcheltasche',
          feminine: 'Schmale Samtbluse mit hochgeschlossenem Halsschmuck',
          neutral: 'Tailored Coat mit feinem Kettenprint',
          accessories: ['Vintage-Kamera', 'Presseausweis', 'Geheime Mappe'],
          makeup: 'Definierte Augen mit soften Lippen fuer Undercover-Eleganz.',
          hairstyle: 'Praktischer Bob oder strukturierter Low Pony.',
          budget: BudgetTier.midrange,
          palette: const ['Anthrazit', 'Gold', 'Staubiges Weiss'],
        ),
      ),
      MysteryRole(
        id: 'matthias',
        name: 'Pater Matthias',
        avatar: 'PM',
        persona:
            'Wortgewandter Geistlicher, der mehr ueber Beichten weiss als ihm lieb ist.',
        secret:
            'Er verwahrt einen Schluessel, den Adrian nie haette uebergeben duerfen.',
        motive: 'Er wollte ein altes Verbrechen vor dem Auffliegen schuetzen.',
        relationships: 'Wurde von Adrian erpresst und von Lucien beobachtet.',
        goal: 'Alle vom Wintergarten fernhalten.',
        alibi: 'Befand sich nach eigener Aussage in der Kapelle der Villa.',
        suspicion: 'Auf dem Teppich vor der Kapelle liegt kein Regenwasser.',
        hiddenClues: const [
          'Kennt das Passwort fuer das Archiv unter der Bibliothek.',
          'Hat Handschuhe verbrannt, bevor die Polizei kommen konnte.',
        ],
        outfit: _outfit(
          masculine: 'Dunkler Mantel mit Priesterkragen und Lederhandschuhen',
          feminine: 'Scharf geschnittene Klerus-Silhouette mit Cape',
          neutral: 'Monastischer Look mit strukturierter Schulterpartie',
          accessories: ['Rosenkranz', 'Messing-Schluessel', 'Siegelbuch'],
          makeup: 'Blasse Haut und klare Schatten fuer asketische Strenge.',
          hairstyle: 'Sauberer Mittelscheitel oder glatter Nackenstil.',
          budget: BudgetTier.budget,
          palette: const ['Schwarz', 'Silber', 'Elfenbein'],
        ),
      ),
      MysteryRole(
        id: 'elias',
        name: 'Captain Elias Grimm',
        avatar: 'EG',
        persona:
            'Ehemaliger Sicherheitschef, ruhig, praezise und schwer zu lesen.',
        secret: 'Er deaktivierte absichtlich eine Kamera im Wintergarten.',
        motive:
            'Er deckt jemanden, weil Adrian dessen Karriere zerstort haette.',
        relationships:
            'Hat eine alte Loyalitaet zu Isabel und einen Streit mit Nora.',
        goal: 'Die Diskussion auf technische Sabotage lenken.',
        alibi:
            'Sicherte angeblich die Ostseite der Villa waehrend des Ausfalls.',
        suspicion: 'Er traegt einen frischen Kratzer an der rechten Hand.',
        hiddenClues: const [
          'Kann die Route des Taeters innerhalb der Villa fast exakt rekonstruieren.',
          'Weiss, warum die Laternen im Garten einmal flackerten.',
        ],
        outfit: _outfit(
          masculine: 'Militaerisch inspirierter Mantel ueber schwarzem Anzug',
          feminine: 'Schmale Uniformjacke mit goldenen Kettenknopfen',
          neutral: 'Strukturierter Sicherheits-Look mit Harness-Details',
          accessories: ['Ohrhoerer', 'Lederstiefel', 'Metallarmband'],
          makeup: 'Scharfe Konturen, fast film noir.',
          hairstyle: 'Kurz und kontrolliert oder strenger Wet-Look.',
          budget: BudgetTier.premium,
          palette: const ['Mitternachtsblau', 'Schwarz', 'Altgold'],
        ),
      ),
      MysteryRole(
        id: 'amara',
        name: 'Amara Sterling',
        avatar: 'AS',
        persona:
            'Neue Verlobte des Opfers mit glaenzendem Charme und undurchsichtiger Vergangenheit.',
        secret:
            'Sie ist nicht zum ersten Mal unter falschem Namen in einer Erbschaftsfeier.',
        motive: 'Ohne Adrian verliert sie den Zugang zu ihrem grossen Plan.',
        relationships:
            'Provokant zu Isabel, verfuehrerisch zu Lucien, seltsam mild zu Matthias.',
        goal:
            'Verhindern, dass die handschriftliche Notiz im Dessertsaal auftaucht.',
        alibi: 'War beim Anruf aus London im Musikzimmer eingeschlossen.',
        suspicion: 'Jemand kennt ihren echten Familiennamen.',
        hiddenClues: const [
          'Hat am Nachmittag die Sitzordnung veraendert.',
          'Erkannte den Geruch eines seltenen Parfuems am Tatort.',
        ],
        outfit: _outfit(
          masculine: 'Seidenhemd mit juwelenschimmerndem Smoking',
          feminine: 'Goldschimmernde Bias-Cut-Robe mit langer Linie',
          neutral: 'Fluessiges Abendensemble mit Art-deco-Schmuck',
          accessories: ['Lange Handschuhe', 'Statement-Ring', 'Parfuem-Flakon'],
          makeup: 'Luxurioeser Glow mit dunklem Lidstrich.',
          hairstyle: 'Sanfte Old-Hollywood-Wellen oder tiefer Seitenscheitel.',
          budget: BudgetTier.premium,
          palette: const ['Gold', 'Champagner', 'Schwarz'],
        ),
      ),
    ],
    hints: const [
      HintCard(
        id: 'hint_a',
        title: 'Versiegelter Umschlag',
        detail:
            'Jemand hat das Testament vor dem Mord geoeffnet und wieder versiegelt.',
        unlockPhase: 1,
      ),
      HintCard(
        id: 'hint_b',
        title: 'Manschettenknopf',
        detail:
            'Ein einzelner Manschettenknopf wurde am Wintergartenfenster gefunden.',
        unlockPhase: 2,
      ),
      HintCard(
        id: 'hint_c',
        title: 'Unscharfes Kamerabild',
        detail:
            'Die Sicherheitskamera wurde exakt 46 Sekunden vor dem Schrei unterbrochen.',
        unlockPhase: 3,
      ),
      HintCard(
        id: 'hint_d',
        title: 'Blutspur am Tablett',
        detail:
            'Auf der Servierglocke liegt eine zweite, deutlich kleinere Blutspur.',
        unlockPhase: 4,
      ),
      HintCard(
        id: 'hint_e',
        title: 'Versteckter Schluessel',
        detail:
            'Unter dem Gebetsbuch der Kapelle lag ein Messingschluessel aus dem Archiv.',
        unlockPhase: 5,
      ),
      HintCard(
        id: 'hint_f',
        title: 'Die wahre Uhrzeit',
        detail: 'Der Tod trat frueher ein als die meisten Aussagen behaupten.',
        unlockPhase: 6,
      ),
    ],
    phases: buildDefaultPhases(),
  ),
  MysteryCase(
    id: 'aurelia_express',
    title: 'Midnight on the Aurelia Express',
    tagline:
        'Ein Luxuszug rast durch die Nacht, waehrend die Wahrheit im Speisewagen friert.',
    description:
        'Zwischen Samtvorhaengen, Silberbesteck und frostigen Fenstern wird eine Diplomatin im Orientzug tot aufgefunden. Jede Kabine schuetzt ihr eigenes Narrativ, doch die Gleise fuehren nur in eine Richtung.',
    category: MysteryCategory.orientExpress,
    playerMin: 4,
    playerMax: 6,
    durationMinutes: 100,
    difficulty: CaseDifficulty.medium,
    recommendedAge: '14+',
    atmosphere:
        'Luxurioese Klaustrophobie mit polierter Etikette und verdeckten Missionen.',
    materials: const ['Fahrkarten', 'Briefumschlaege', 'Teelichter', 'Zugplan'],
    coverColors: const [
      AppPalette.midnight,
      Color(0xFF2A3A53),
      AppPalette.gold
    ],
    highlights: const [
      'Elegant inszenierter Zugkorridor',
      'Starkes Alibi-Puzzle',
      'Dichte Ensemble-Szenen im Speisewagen',
    ],
    roles: [
      MysteryRole(
        id: 'sofia',
        name: 'Sofia Delacroix',
        avatar: 'SD',
        persona:
            'Weltgewandte Kunsthaendlerin mit einem Gedachtnis wie ein Archiv.',
        secret: 'Sie schmuggelt Mikrofilme in restaurierten Schmuckschatullen.',
        motive: 'Das Opfer wollte Sofia an die Presse verkaufen.',
        relationships:
            'Kennt den Schaffner zu gut und benutzt den Bodyguard als Schutzschild.',
        goal: 'Den Fokus auf die verschlossene Privatkabine lenken.',
        alibi: 'War zur Tatzeit im Wagon Bleu und telefonierte ueber Satellit.',
        suspicion: 'Der Koch verschwand untypisch lang in den Versorgungsgang.',
        hiddenClues: const [
          'Kennt die echte Passnummer der Toten.',
          'Hat den Fahrplan manipuliert.'
        ],
        outfit: _outfit(
          masculine: 'Kamelhaar-Mantel ueber cremefarbenem Dreiteiler',
          feminine: 'Smaragdgruenes Reise-Ensemble mit Handschuhen',
          neutral: 'Glatter Luxus-Look mit strukturierter Reisejacke',
          accessories: [
            'Fahrkartenetui',
            'Brillenkette',
            'Silbernes Feuerzeug'
          ],
          makeup: 'Gepflegte, glanzarme Eleganz.',
          hairstyle: 'Perfekte Wellen oder glatter Chignon.',
          budget: BudgetTier.premium,
          palette: const ['Smaragd', 'Creme', 'Gold'],
        ),
      ),
      MysteryRole(
        id: 'gabriel',
        name: 'Gabriel Varenne',
        avatar: 'GV',
        persona: 'Zugschaffner mit tadelloser Haltung und Nerven aus Stahl.',
        secret: 'Er wechselte zwei Gepaeckscheine noch vor der Grenzkontrolle.',
        motive:
            'Wenn das Opfer spricht, verliert er seine Karriere und Freiheit.',
        relationships:
            'Fuehlt sich dem Zug verpflichtet, misstraut Sofia, fuerchtet die Baronin.',
        goal: 'Niemanden den Technikgang betreten lassen.',
        alibi: 'Pruefte Fahrkarten in Wagen drei und vier.',
        suspicion:
            'Jemand benutzte seinen Dienstschluessel ohne Spuren zu hinterlassen.',
        hiddenClues: const [
          'Kennt eine versteckte Plattform an Wagenende.',
          'Weiss vom gesperrten Postfach.'
        ],
        outfit: _outfit(
          masculine: 'Marineblauer Uniformmantel mit Goldborte',
          feminine: 'Massgeschneiderte Uniform mit hohem Kragen',
          neutral: 'Formeller Zuglook mit strengem Schnitt',
          accessories: ['Taschenuhr', 'Fahrkartenzange', 'Messing-Pins'],
          makeup: 'Nur klare Konturen, fast unsichtbar.',
          hairstyle: 'Diszipliniert zurueckgelegt oder strenger Bob.',
          budget: BudgetTier.midrange,
          palette: const ['Marine', 'Gold', 'Creme'],
        ),
      ),
      MysteryRole(
        id: 'nadia',
        name: 'Baronin Nadia Kessel',
        avatar: 'NK',
        persona:
            'Aristokratin mit knapper Geduld und einem Hang zu gefaehrlichen Wetten.',
        secret:
            'Sie verlor in Istanbul ein Juwel, das jetzt an Bord sein koennte.',
        motive: 'Das Opfer wollte Nadia mit einer peinlichen Schuld ruinieren.',
        relationships:
            'Kaempft offen mit Gabriel und setzt den Illusionisten unter Druck.',
        goal: 'Sofia zum Ausraster bringen.',
        alibi: 'Nahm waehrend des Schneestopps Tee im Salonwagen.',
        suspicion: 'Der Bodyguard traegt fremde Schneekristalle am Mantel.',
        hiddenClues: const [
          'Kennt das Symbol auf dem Mikrofilm.',
          'Besitzt eine zweite Reiseroute.'
        ],
        outfit: _outfit(
          masculine: 'Dunkler Wintermantel mit Pelzkragen und Siegelring',
          feminine: 'Burgunderfarbenes Reisekleid mit dramatischem Cape',
          neutral: 'Opulentes Travel Couture Ensemble',
          accessories: ['Statement-Ohrringe', 'Faecher', 'Samthandschuhe'],
          makeup: 'Tiefe Lippenfarbe und sehr praezise Brauen.',
          hairstyle: 'Groesse Wellen oder kunstvoller Twist.',
          budget: BudgetTier.premium,
          palette: const ['Burgunder', 'Schwarz', 'Altgold'],
        ),
      ),
      MysteryRole(
        id: 'leon',
        name: 'Leon Ardent',
        avatar: 'LA',
        persona: 'Buehnenmagier auf Abschiedstour mit auffallend gutem Timing.',
        secret:
            'Sein Requisitenkoffer verbirgt nicht nur Karten und Seidentuecher.',
        motive: 'Das Opfer kannte Leons fruehere Identitaet.',
        relationships:
            'Flirtet mit Nadia, lenkt Gabriel ab und liest den Koch wie ein Buch.',
        goal: 'Den Fehler im Sitzplan unter den Tisch fallen lassen.',
        alibi: 'Stand beim Schrei vor Publikum im Rauch der Salonshow.',
        suspicion:
            'Eine Person trug den Wagenplan auf der Handflaeche mit Kohle notiert.',
        hiddenClues: const [
          'Hat Spiegelstaub am Tatort bemerkt.',
          'Kennt den Trick mit der verriegelten Kabine.'
        ],
        outfit: _outfit(
          masculine: 'Samtjacke mit seidigen Revers und dunklem Schal',
          feminine: 'Art-deco-Anzug mit glitzerndem Schulterdetail',
          neutral: 'Dramatische Variete-Silhouette in Schwarz und Gold',
          accessories: ['Spielkarten', 'Seidentuch', 'Zauberstock'],
          makeup: 'Leicht schimmernde Lider fuer Buehnenpraesenz.',
          hairstyle: 'Wellen oder texturierter Wet-Look.',
          budget: BudgetTier.midrange,
          palette: const ['Schwarz', 'Gold', 'Tintenblau'],
        ),
      ),
      MysteryRole(
        id: 'mila',
        name: 'Mila Hart',
        avatar: 'MH',
        persona:
            'Persoenliche Beschuetzerin des Opfers, die nie beide Augen schliesst.',
        secret:
            'Sie wurde kurz vor Abfahrt abberufen, blieb aber aus eigenem Willen an Bord.',
        motive: 'Sie wollte einen Verrat verhindern und kam zu spaet.',
        relationships:
            'Schuetzt Sofia nicht freiwillig und respektiert Gabriel nur halb.',
        goal: 'Die Spur zum Postwagen sichern.',
        alibi: 'Patrouillierte zwischen den Waggons und pruefte das Gepaeck.',
        suspicion:
            'Jemand ersetzte eine Signallampe durch ein identisches Modell.',
        hiddenClues: const [
          'Kennt eine ungenannte Passagierliste.',
          'Trug als Einzige einen echten Notschluessel.'
        ],
        outfit: _outfit(
          masculine: 'Schwarzer Rollkragen mit strukturiertem Reiseblazer',
          feminine: 'Schmale Hose mit langem Mantel und Utility-Details',
          neutral: 'Minimalistischer Schutzlook mit Gurt-Elementen',
          accessories: ['Lederhandschuhe', 'Ear cuff', 'Taschenlampe'],
          makeup: 'Zurueckhaltend, nur definierte Augen.',
          hairstyle: 'Praktischer Zopf oder kurzer Slick-Back-Stil.',
          budget: BudgetTier.midrange,
          palette: const ['Schwarz', 'Graphit', 'Silber'],
        ),
      ),
      MysteryRole(
        id: 'enzo',
        name: 'Enzo Bellini',
        avatar: 'EB',
        persona: 'Chefkoch des Speisewagens, charmant bis zur letzten Geste.',
        secret:
            'Er vertauschte einen Gang, nachdem er eine geheime Nachricht las.',
        motive: 'Das Opfer bedrohte sein Restaurantprojekt in Venedig.',
        relationships:
            'Koaliert mal mit Nadia, mal mit Leon und traut Mila ueberhaupt nicht.',
        goal: 'Die Diskussion auf das vergiftete Dessert fokussieren.',
        alibi: 'Stand in der Kueche mit zwei Assistenten, als das Licht sank.',
        suspicion: 'Jemand wusste vorab von der geaenderten Speisenfolge.',
        hiddenClues: const [
          'Hat ein Glas mit Lippenstiftrest versteckt.',
          'Weiss vom geheimen Halt in Belgrad.'
        ],
        outfit: _outfit(
          masculine: 'Dunkles Kochjackett mit schwarzen Lederschuerze-Akzenten',
          feminine: 'Schmaler Culinary-Look mit weisser Satinbluse',
          neutral: 'Kuechen-Couture in Schwarz, Creme und Messing',
          accessories: ['Silberner Loeffel', 'Monogramm-Tuch', 'Gewuerzdose'],
          makeup: 'Frisch, aber definiert fuer eventtaugliche Kuechenpraesenz.',
          hairstyle: 'Saubere Ruecknahme oder Half-up-Stil.',
          budget: BudgetTier.budget,
          palette: const ['Creme', 'Schwarz', 'Messing'],
        ),
      ),
    ],
    hints: const [
      HintCard(
          id: 'hint_a',
          title: 'Kabine 12',
          detail:
              'Die Kabine des Opfers wurde von innen, nicht von aussen, verriegelt.',
          unlockPhase: 1),
      HintCard(
          id: 'hint_b',
          title: 'Falscher Gepaeckschein',
          detail: 'Zwei Koffer wurden absichtlich vor der Grenze vertauscht.',
          unlockPhase: 2),
      HintCard(
          id: 'hint_c',
          title: 'Schneespur',
          detail:
              'Nur ein Mantel traegt echte Schneereste aus dem Technikgang.',
          unlockPhase: 3),
      HintCard(
          id: 'hint_d',
          title: 'Desserttausch',
          detail:
              'Ein Gang wurde wenige Minuten vor dem Servieren neu angerichtet.',
          unlockPhase: 4),
      HintCard(
          id: 'hint_e',
          title: 'Mikrofilm',
          detail:
              'In einer Schmuckschatulle liegt ein halb verbrannter Mikrofilm.',
          unlockPhase: 5),
      HintCard(
          id: 'hint_f',
          title: 'Signalstopp',
          detail: 'Der Mord haengt direkt mit dem ungeplanten Halt zusammen.',
          unlockPhase: 6),
    ],
    phases: buildDefaultPhases(),
  ),
  MysteryCase(
    id: 'crimson_masquerade',
    title: 'Crimson Masquerade',
    tagline: 'Masken fallen schneller als Jetons.',
    description:
        'In einem exklusiven Casino-Ball der 1920er kollidieren Ehrgeiz, Glamour und Unterwelt. Als eine Maezenin mitten in der finalen Auktion zusammenbricht, wird jede Tanzflaeche zum Tatort.',
    category: MysteryCategory.casino,
    playerMin: 5,
    playerMax: 6,
    durationMinutes: 95,
    difficulty: CaseDifficulty.medium,
    recommendedAge: '14+',
    atmosphere: 'Art-deco-Luxus, verrauchte Bar und rhythmische Gefahr.',
    materials: const [
      'Spielkarten',
      'Masken',
      'Goldene Chips',
      'Cocktailkarte'
    ],
    coverColors: const [Color(0xFF22080E), AppPalette.wine, AppPalette.gold],
    highlights: const [
      'Rasante Social-Deduction-Energie',
      'Grosses Maskenmotiv fuer Fotos und Rollenplay',
      'Perfekt fuer stilvolle Partyrunden',
    ],
    roles: [
      MysteryRole(
        id: 'celeste',
        name: 'Celeste Noir',
        avatar: 'CN',
        persona:
            'Sengeraehnliche Gastgeberin des Abends mit dramatischer Kontrolle.',
        secret:
            'Sie organisierte die Auktion, um eine belastende Akte verschwinden zu lassen.',
        motive: 'Das Opfer wollte Celestes neues Etablissement schliessen.',
        relationships:
            'Brenzlig mit dem Banker, neckisch mit dem Taschenspieler.',
        goal: 'Die Runde auf den verschwundenen Rubin fixieren.',
        alibi:
            'Stand waehrend des Stromblitzes auf der Buehne im Scheinwerferlicht.',
        suspicion: 'Jemand kannte die Reihenfolge ihrer Songs auswendig.',
        hiddenClues: const [
          'Besitzt den echten Saalschluessel.',
          'Hatte das Auktionsheft vorab ausgetauscht.'
        ],
        outfit: _outfit(
          masculine: 'Art-deco-Smoking mit satinierter Schleife',
          feminine: 'Dunkelrote Fransenrobe mit Goldstickerei',
          neutral: 'Buehnencouture mit langen Linien und starkem Glamour',
          accessories: ['Federstirnband', 'Lange Kette', 'Mikrofon-Replik'],
          makeup: 'Glanzvolle Lippen und definierter Wing.',
          hairstyle: 'Fingerwaves oder glatter Sculpted-Look.',
          budget: BudgetTier.premium,
          palette: const ['Karminrot', 'Gold', 'Schwarz'],
        ),
      ),
      MysteryRole(
        id: 'gideon',
        name: 'Gideon Pike',
        avatar: 'GP',
        persona: 'Banker mit makellosem Anzug und keinem Gramm Geduld.',
        secret: 'Er finanzierte heimlich die Maezenin, die nun tot ist.',
        motive: 'Ein Finanzskandal haette ihn mit in den Abgrund gezogen.',
        relationships:
            'Verabscheut Celestes Improvisation und fuehrt Mila absichtlich in die Irre.',
        goal: 'Das Protokollbuch aus dem Backoffice verschwinden lassen.',
        alibi: 'War bei der Pokerbar und stritt ueber Jetons.',
        suspicion:
            'Jemand hat mit seinem Fuellederhalter eine Notiz in Rot markiert.',
        hiddenClues: const [
          'Trug am Abend den falschen Manschettenstil.',
          'Kennt den Sicherheitswechsel im Casino.'
        ],
        outfit: _outfit(
          masculine: 'Elfenbeinfarbener Dinneranzug mit schwarzen Revers',
          feminine: 'Scharfer Tailoring-Look mit fedrigen Details',
          neutral: 'Luxurioeser Suit mit langen Art-deco-Linien',
          accessories: ['Fuellfederhalter', 'Taschenuhr', 'Seidenstecktuch'],
          makeup: 'Präzise, kuehl und konturiert.',
          hairstyle: 'Strenger Seitenscheitel oder sleeker Bob.',
          budget: BudgetTier.midrange,
          palette: const ['Elfenbein', 'Schwarz', 'Gold'],
        ),
      ),
      MysteryRole(
        id: 'opal',
        name: 'Opal Reed',
        avatar: 'OR',
        persona: 'Taschenspielerin mit Charme und zu vielen Namen.',
        secret: 'Sie hatte Zugang zu jedem Tisch im Casino, weil sie bestaach.',
        motive: 'Die Tote erkannte Opal aus einem alten Prozess.',
        relationships:
            'Liest Gideon, bewundert Celeste und tauscht Zeichen mit dem Pianisten.',
        goal: 'Niemanden in den Spiegelkorridor lassen.',
        alibi: 'Fuehrte im kleinen Salon eine Kartenroutine vor.',
        suspicion: 'Eine Maske wurde kurz nach dem Schrei verbrannt.',
        hiddenClues: const [
          'Weiss, wer den Rubin zuerst beruehrte.',
          'Hat eine zweite Maske in Reserve.'
        ],
        outfit: _outfit(
          masculine: 'Gestreifter Rueckenshirt-Look mit Westenlayer',
          feminine: 'Schwarzes Slip-Dress mit langen Handschuhen',
          neutral: 'Schlanke Silhouette mit geheimnisvollem Cape',
          accessories: ['Spielkarten', 'Samtmaske', 'Glitzerhandschuhe'],
          makeup: 'Smokey Eyes mit leichtem Goldschimmer.',
          hairstyle: 'Kurzer Fingerwave-Cut oder tiefer Seitenscheitel.',
          budget: BudgetTier.budget,
          palette: const ['Schwarz', 'Silber', 'Rot'],
        ),
      ),
      MysteryRole(
        id: 'julian',
        name: 'Julian Hart',
        avatar: 'JH',
        persona:
            'Jazzpianist mit perfektem Gehoer und unperfekter Vergangenheit.',
        secret:
            'Er spielte absichtlich die falsche Schlussmelodie, um ein Signal zu geben.',
        motive: 'Das Opfer ruinierte einst seine Schwester.',
        relationships:
            'Versteht Opal, fuerchtet Gideon und kennt Celestes wahre Sorgen.',
        goal: 'Das Publikum ueber den Stromausfall reden lassen.',
        alibi: 'Stand am Fluegel und spielte bis zum Knall.',
        suspicion: 'Jemand zaehlte den Takt hinter dem Vorhang mit.',
        hiddenClues: const [
          'Hat einen Lackschuh im Hintergang gesehen.',
          'Kennt den geheimen Buehneneingang.'
        ],
        outfit: _outfit(
          masculine: 'Mitternachtsblauer Smoking mit lockerem Schal',
          feminine: 'Satinanzug mit klavierlackschwarzen Details',
          neutral: 'Jazz-Couture mit fliessender Form',
          accessories: ['Notenblaetter', 'Schmale Krawatte', 'Lackschuhe'],
          makeup: 'Dunkle Augen, sanfter Glow.',
          hairstyle: 'Gelockte Struktur oder sleek zurück.',
          budget: BudgetTier.midrange,
          palette: const ['Mitternachtsblau', 'Schwarz', 'Silber'],
        ),
      ),
      MysteryRole(
        id: 'marlowe',
        name: 'Inspector Marlowe',
        avatar: 'IM',
        persona: 'Undercover-Ermittler, der zu frueh auffaellt.',
        secret:
            'Ist ohne Erlaubnis im Casino, um einen anderen Fall zu verfolgen.',
        motive: 'Braucht das verschwundene Dossier um jeden Preis.',
        relationships: 'Benutzt Gideon, schuetzt Celeste halb und testet Opal.',
        goal: 'Die Gruppe auf das Notizbuch unter der Buehne bringen.',
        alibi: 'Stand beim Auktionspult, als die Lichter zitterten.',
        suspicion: 'Jemand kennt seinen echten Rang trotz Tarnung.',
        hiddenClues: const [
          'Hat den echten Rubin nie aus den Augen verloren.',
          'Traegt eine zweite Dienstmarke im Schuh.'
        ],
        outfit: _outfit(
          masculine: 'Trenchcoat ueber scharfem Abendanzug',
          feminine: 'Schmaler Mantellook mit Satinschal',
          neutral: 'Film-noir-Silhouette mit klaren Linien',
          accessories: ['Notizbuch', 'Bleistift', 'Doppelte Uhrkette'],
          makeup: 'Nuechtern, leicht schattiert fuer Undercover-Look.',
          hairstyle: 'Sauberer Scheitel oder knapper Low Bun.',
          budget: BudgetTier.budget,
          palette: const ['Kohle', 'Creme', 'Gold'],
        ),
      ),
    ],
    hints: const [
      HintCard(
          id: 'hint_a',
          title: 'Roter Marker',
          detail: 'Eine Auktionsnummer wurde mit roter Tinte eingekreist.',
          unlockPhase: 1),
      HintCard(
          id: 'hint_b',
          title: 'Maske im Ofen',
          detail: 'Hinter der Bar wurde eine verbrannte Maske gefunden.',
          unlockPhase: 2),
      HintCard(
          id: 'hint_c',
          title: 'Falscher Song',
          detail: 'Die Schlussmelodie war nicht Teil des Programms.',
          unlockPhase: 3),
      HintCard(
          id: 'hint_d',
          title: 'Spiegelgang',
          detail:
              'Nur eine Person kennt den schnellsten Weg durch den Spiegelkorridor.',
          unlockPhase: 4),
      HintCard(
          id: 'hint_e',
          title: 'Rubin',
          detail: 'Der Rubin war zur Tatzeit bereits eine Faehlung.',
          unlockPhase: 5),
      HintCard(
          id: 'hint_f',
          title: 'Dossier',
          detail: 'Der eigentliche Mordgrund war eine Akte, nicht das Juwel.',
          unlockPhase: 6),
    ],
    phases: buildDefaultPhases(),
  ),
  MysteryCase(
    id: 'lantern_society',
    title: 'The Lantern Society',
    tagline:
        'In den Archiven der Detektivschule ist Wissen toedlicher als jede Klinge.',
    description:
        'Die streng geheime Lantern Society oeffnet nur einer Handvoll Talente ihre Archive. Als die leitende Mentorin tot zwischen chiffrierten Fallakten gefunden wird, wird aus einer Aufnahmepruefung ein Wettlauf gegen ein verborgenes Netzwerk.',
    category: MysteryCategory.detectiveSchool,
    playerMin: 4,
    playerMax: 6,
    durationMinutes: 105,
    difficulty: CaseDifficulty.mastermind,
    recommendedAge: '15+',
    atmosphere: 'Geheimbund, alte Karteikaesten und intelligente Duelle.',
    materials: const [
      'Chiffrekarten',
      'Notizbuch',
      'Laternenlicht',
      'Wachssiegel'
    ],
    coverColors: const [
      Color(0xFF09121F),
      AppPalette.midnight,
      AppPalette.gold
    ],
    highlights: const [
      'Starke Detektivschul-Fantasy ohne Uebernatuerliches',
      'Viel Raum fuer QR-Codes und Hinweisumschlaege',
      'Perfekt fuer kompetitive Gruft-Teams',
    ],
    roles: [
      MysteryRole(
        id: 'iris',
        name: 'Iris Vale',
        avatar: 'IV',
        persona: 'Brillante Kodiererin mit wenig Geduld fuer Hierarchien.',
        secret:
            'Sie knackte nachts das Archiv, um ihre verschwundene Akte zu suchen.',
        motive: 'Die Mentorin unterdrueckte Hinweise zum Fall ihrer Familie.',
        relationships:
            'Schlaegt sich mit Rowan, respektiert Sera und provoziert Theo.',
        goal: 'Die versiegelte Fallmappe in Gespraeche bringen.',
        alibi: 'War im Kartenraum, als die Glocke zum Stromausfall schlug.',
        suspicion: 'Jemand hatte den Archivplan auf Pergament abgepaust.',
        hiddenClues: const [
          'Kann die Chiffre an der Wand sofort lesen.',
          'Kennt das zweite Siegelzeichen.'
        ],
        outfit: _outfit(
          masculine: 'Dunkler College-Mantel mit Goldstickerei',
          feminine: 'Scharfer Uniformrock mit strukturierter Weste',
          neutral: 'Akademischer Mystery-Look mit klaren Kanten',
          accessories: [
            'Cipher Wheel',
            'Brillenband',
            'Tintenfleck-Handschuhe'
          ],
          makeup: 'Klar, intelligent, leichte Schatten.',
          hairstyle: 'Halb hochgesteckt oder kurzer strukturierter Cut.',
          budget: BudgetTier.budget,
          palette: const ['Mitternachtsblau', 'Gold', 'Pergament'],
        ),
      ),
      MysteryRole(
        id: 'rowan',
        name: 'Rowan Black',
        avatar: 'RB',
        persona:
            'Nachfahre beruehmter Ermittler, gewohnt zu fuehren und schwer zu bremsen.',
        secret: 'Rowan sollte die Mentorin eigentlich beschuetzen.',
        motive: 'Ein Scheitern wuerde die Familienlegende zerstören.',
        relationships:
            'Rivale von Iris, Vorbild fuer Theo, skeptisch gegenueber Sera.',
        goal: 'Niemanden den Schluesselbund untersuchen lassen.',
        alibi: 'Trainierte im Observatorium, bis der Alarm losging.',
        suspicion: 'Die Mentorin vertraute jemandem aus ihrer engsten Gruppe.',
        hiddenClues: const [
          'Trug eine Notfalllaterne mit frischer Asche.',
          'Weiss vom verbotenen Untergeschoss.'
        ],
        outfit: _outfit(
          masculine: 'Langer Mantel mit Messingverschluessen und Rollkragen',
          feminine: 'Strukturiertes Uniformensemble mit hohen Stiefeln',
          neutral: 'Heldenhafte Prep-Silhouette mit militaerischer Linie',
          accessories: ['Kompass', 'Lederhandschuhe', 'Laterne'],
          makeup: 'Klar konturiert, fast heldenhaft.',
          hairstyle: 'Rueckgelegtes Haar oder markanter kurzer Schnitt.',
          budget: BudgetTier.midrange,
          palette: const ['Dunkelblau', 'Messing', 'Schwarz'],
        ),
      ),
      MysteryRole(
        id: 'sera',
        name: 'Sera Quill',
        avatar: 'SQ',
        persona: 'Stille Archivarin mit fotografischem Gedachtnis.',
        secret: 'Sie weiss, welche Akte aus dem Untergeschoss fehlt.',
        motive: 'Die Mentorin bedrohte ihre Schwester mit Schulverweis.',
        relationships:
            'Vertraut Iris, fuerchtet Rowan und spielt Theo gegeneinander aus.',
        goal: 'Das gesperrte Regal meiden lassen.',
        alibi: 'Sortierte Karten im grossen Lesesaal.',
        suspicion: 'Eine Person hat Pergamentstaub an den Aermeln.',
        hiddenClues: const [
          'Kennt das Passwort zur Kartenkammer.',
          'Sah den Schatten im Oberlicht.'
        ],
        outfit: _outfit(
          masculine: 'Feiner Wollmantel ueber hoher Weste',
          feminine: 'Tintenfarbene Bluse mit Plisseerock',
          neutral: 'Elegante Archiv-Silhouette mit weichen Layern',
          accessories: ['Federhalter', 'Schluesselband', 'Leselampe'],
          makeup: 'Sanft, blass, geheimnisvoll.',
          hairstyle: 'Niedriger Knoten oder gerader Bob.',
          budget: BudgetTier.budget,
          palette: const ['Tinte', 'Pergament', 'Gold'],
        ),
      ),
      MysteryRole(
        id: 'theo',
        name: 'Theo Mercer',
        avatar: 'TM',
        persona: 'Junger Analytiker, der immer eine Theorie mehr hat als Zeit.',
        secret: 'Theo fand bereits vor Tagen eine Warnung im Kartenkasten.',
        motive: 'Er wollte endlich ernst genommen werden und ging zu weit.',
        relationships:
            'Schwaermt fuer Rowan, bewundert Sera und misstraut Iris.',
        goal: 'Die Uhrzeit des Alarms anzweifeln.',
        alibi: 'Zaehlte Instrumente im Observatorium.',
        suspicion: 'Jemand setzte den Alarm absichtlich zu spaet ab.',
        hiddenClues: const [
          'Hat einen Fehler im offiziellen Protokoll entdeckt.',
          'Trug die falsche Schluesselnummer.'
        ],
        outfit: _outfit(
          masculine: 'Akademische Weste mit Streifenhemd und Krawatte',
          feminine: 'Scharfer Schulanzug mit Messingknopfen',
          neutral: 'Tidy-Detective-Look mit Layern und Notizgurt',
          accessories: ['Taschennotizbuch', 'Messschieber', 'Tintenroller'],
          makeup: 'Frisch und konzentriert.',
          hairstyle: 'Unangestrengter Scheitel oder kurzer Crop.',
          budget: BudgetTier.budget,
          palette: const ['Navy', 'Braun', 'Messing'],
        ),
      ),
      MysteryRole(
        id: 'vesper',
        name: 'Vesper Hart',
        avatar: 'VH',
        persona:
            'Externe Prueferin mit Agentenhaltung und makelloser Etikette.',
        secret: 'Sie untersucht die Lantern Society seit Monaten verdeckt.',
        motive: 'Die Mentorin wollte Vespers Einsatz auffliegen lassen.',
        relationships: 'Beobachtet alle, lenkt Rowan und durchschaut Sera.',
        goal: 'Die Diskussion auf die gefaelschten Siegel lenken.',
        alibi: 'Fuehrte im Marmorsaal Gespräche mit dem Foerderkreis.',
        suspicion: 'Es gibt eine zweite Version des Protokolls.',
        hiddenClues: const [
          'Hat die verschluesselte Funkmeldung empfangen.',
          'Kennt die Namen der stillen Foerderer.'
        ],
        outfit: _outfit(
          masculine: 'Doppelt geknoepfter Mantel mit Handschuhen',
          feminine: 'Langer Mantel mit strenger Satinbluse',
          neutral: 'Agentische Eleganz mit dunklem Cape-Effekt',
          accessories: [
            'Geheimer Ohrstecker',
            'Siegelset',
            'Duenner Handschuh'
          ],
          makeup: 'Kuehl, praezise, fast unnahbar.',
          hairstyle: 'Perfekter Sleek-Look oder tiefer Zopf.',
          budget: BudgetTier.premium,
          palette: const ['Schwarz', 'Mitternachtsblau', 'Gold'],
        ),
      ),
    ],
    hints: const [
      HintCard(
          id: 'hint_a',
          title: 'Versiegelte Mappe',
          detail: 'Die Akte im Tresor traegt zwei unterschiedliche Siegel.',
          unlockPhase: 1),
      HintCard(
          id: 'hint_b',
          title: 'Pergamentstaub',
          detail: 'Pergamentstaub fuehrt direkt zum verbotenen Untergeschoss.',
          unlockPhase: 2),
      HintCard(
          id: 'hint_c',
          title: 'Falscher Alarm',
          detail:
              'Der offizielle Alarm wurde fast zwei Minuten spaeter eingetragen.',
          unlockPhase: 3),
      HintCard(
          id: 'hint_d',
          title: 'Kartenkammer',
          detail:
              'Nur eine Person kannte das zweite Passwort zur Kartenkammer.',
          unlockPhase: 4),
      HintCard(
          id: 'hint_e',
          title: 'Foerderkreis',
          detail:
              'Der Foerderkreis finanzierte ein geheimes Nebenprojekt der Mentorin.',
          unlockPhase: 5),
      HintCard(
          id: 'hint_f',
          title: 'Verlorene Akte',
          detail:
              'Die fehlende Akte enthaelt den eigentlichen Grund fuer den Mord.',
          unlockPhase: 6),
    ],
    phases: buildDefaultPhases(),
  ),
];

MysteryCase? findMysteryCaseById(String id) {
  for (final mysteryCase in demoMysteryCases) {
    if (mysteryCase.id == id) {
      return mysteryCase;
    }
  }
  return null;
}
