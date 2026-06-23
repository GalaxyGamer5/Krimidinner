# Krimi-Dinner Roadmap

## Zielbild

Die App soll nicht nur schoen aussehen, sondern einen kompletten Krimiabend wirklich tragen:

- Lobby und Rollen muessen stabil funktionieren
- Gastgeber brauchen echte Werkzeuge statt Platzhalter
- Spieler brauchen private Notizen, Marker, Hinweise und klare Phasen
- spaetere Premium-Features koennen darauf aufbauen

## Empfohlene Prioritaet

### Phase 1: Solide Kern-App

- persistenter Anzeigename und echte Einstellungen
- echte Freundeliste mit leerem Zustand, Hinzufuegen und Entfernen
- echte Achievements auf Basis realer Spielstatistiken
- komplette Sprachumschaltung fuer Deutsch, Englisch, Franzoesisch und Spanisch
- Gastgeber-Checkliste in der Lobby
- private Spieler-Notizen mit Markierungen
- stabiles Lobby-, Rollen-, Chat- und Hinweis-System

### Phase 2: Besseres Gastgeber-Erlebnis

- Host-Checklist mit Countdown, Vorbereitungsschritten und Phasenhinweisen
- Ambient-Modus fuer Musik, Soundeffekte und Szenenwechsel
- PDF-Export fuer Rollen, Einladungen und Host-Zusammenfassung
- dekorative Vorschlaege fuer Raum, Essen, Dresscode und Ablauf
- Pause-Modus und Kurzmodus fuer kuerzere Abende

### Phase 3: Tieferes Social Deduction Gameplay

- gemeinsames Ermittlungsboard fuer Beweise, Beziehungen und Theorien
- Seitenquests pro Rolle
- Soziogramm zwischen Figuren
- persoenliche Hinweis-Systeme je Rolle
- Medienbeweise wie Audio, Zeitung, Chat-Screens oder Fotos
- Familienmodus ohne harte Morddetails

### Phase 4: Erweiterte Inhalte

- Case-Editor fuer eigene Faelle
- manuelle Veroeffentlichung eigener Community-Faelle
- Zufallstaeter-Mechanik fuer wiederholbare Faelle
- Replay-Schutz, damit bekannte Aufloesungen nicht sofort sichtbar sind
- Offline-Modus mit lokalem Cache fuer laufende Abende

### Phase 5: Langfristige Premium-Ideen

- KI-gestuetzter Fallgenerator mit manueller Nachbearbeitung
- Gruppenprofile mit Fotos und Statistik-Historie
- Ersatzspieler-Modus bei Ausfall waehrend einer Runde
- flexible Monetarisierung ueber Premium-Faelle, Host-Tools oder Creator-Inhalte

## Sinnvolle neue Screens

- `Host Dashboard`
- `Investigation Board`
- `Case Editor`
- `Session Summary`
- `Group Profile`
- `Ambience Control`

## Datenmodell-Ideen

- `SessionChecklistItem`
- `PlayerMarker`
- `PlayerRelationship`
- `SideQuest`
- `SessionTimelineEvent`
- `MediaEvidence`
- `GroupProfile`
- `CustomCaseDraft`

## Technische Empfehlungen

- alles Wichtige zuerst lokal mit `SharedPreferences` oder spaeter `Hive/Isar` halten
- UI-Texte nur noch ueber zentrales Lokalisierungs-System pflegen
- Host-Logik klar von Spieler-Logik trennen
- neue Gameplay-Systeme immer auf `LobbySession` und `MysteryCase` aufbauen
- fuer eigene Faelle spaeter ein JSON-basiertes Importformat vorbereiten

## Konkrete naechste Schritte

1. Musik- und Effekt-System mit echten Audio-Dateien anschliessen
2. Investigation Board als neue Session-Ansicht bauen
3. Host-Dashboard um Countdown, Ablauf und Schnellaktionen erweitern
4. Rollenhilfe und Seitenquests im aktiven Spiel anzeigen
5. danach Case-Editor als groesseres Modul starten
