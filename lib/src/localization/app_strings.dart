import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mystery_models.dart';
import '../state/app_providers.dart';

final appStringsProvider = Provider<AppStrings>((ref) {
  final language = ref.watch(appSettingsProvider).language;
  return AppStrings(language);
});

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  String tr({
    required String de,
    required String en,
    required String fr,
    required String es,
  }) {
    return _pick(de: de, en: en, fr: fr, es: es);
  }

  String _pick({
    required String de,
    required String en,
    required String fr,
    required String es,
  }) {
    switch (language) {
      case AppLanguage.de:
        return de;
      case AppLanguage.en:
        return en;
      case AppLanguage.fr:
        return fr;
      case AppLanguage.es:
        return es;
    }
  }

  String get appName => 'MYSTERY NIGHT';
  String get navHome => _pick(
        de: 'Salon',
        en: 'Lounge',
        fr: 'Salon',
        es: 'Salon',
      );
  String get navCases => _pick(
        de: 'Faelle',
        en: 'Cases',
        fr: 'Affaires',
        es: 'Casos',
      );
  String get navLobbies => _pick(
        de: 'Lobbys',
        en: 'Lobbies',
        fr: 'Lobbies',
        es: 'Salas',
      );
  String get navRoles => _pick(
        de: 'Rollen',
        en: 'Roles',
        fr: 'Roles',
        es: 'Roles',
      );
  String get navAccount => _pick(
        de: 'Konto',
        en: 'Account',
        fr: 'Compte',
        es: 'Cuenta',
      );

  String pageTitle(String location) {
    if (location.startsWith('/cases/')) {
      return _pick(
        de: 'Krimiakte',
        en: 'Case File',
        fr: 'Dossier',
        es: 'Expediente',
      );
    }
    if (location.startsWith('/cases')) {
      return _pick(
        de: 'Krimi-Auswahl',
        en: 'Case Library',
        fr: 'Selection de cas',
        es: 'Biblioteca de casos',
      );
    }
    if (location.startsWith('/lobbies/room/')) {
      return _pick(
        de: 'Live-Lobby',
        en: 'Live Lobby',
        fr: 'Lobby en direct',
        es: 'Lobby en vivo',
      );
    }
    if (location.startsWith('/invite/')) {
      return _pick(
        de: 'Einladung',
        en: 'Invitation',
        fr: 'Invitation',
        es: 'Invitacion',
      );
    }
    if (location.startsWith('/lobbies')) {
      return _pick(
        de: 'Lobby-System',
        en: 'Lobby Hub',
        fr: 'Centre des lobbies',
        es: 'Centro de lobbies',
      );
    }
    if (location.startsWith('/roles')) {
      return _pick(
        de: 'Meine Rollen',
        en: 'My Roles',
        fr: 'Mes roles',
        es: 'Mis roles',
      );
    }
    if (location.startsWith('/account')) {
      return _pick(
        de: 'Freunde, Erfolge und Einstellungen',
        en: 'Friends, achievements and settings',
        fr: 'Amis, succes et parametres',
        es: 'Amigos, logros y ajustes',
      );
    }
    return appName;
  }

  String get introBadge => _pick(
        de: 'Premium Multiplayer Mystery',
        en: 'Premium Multiplayer Mystery',
        fr: 'Mystere multijoueur premium',
        es: 'Misterio multijugador premium',
      );
  String get introHeadline => _pick(
        de: 'Das Geheimnis wartet.',
        en: 'The secret is waiting.',
        fr: 'Le secret attend.',
        es: 'El secreto espera.',
      );
  String get introDescription => _pick(
        de: 'Erstelle elegante Lobbys, teile QR-Codes, verteile geheime Rollen und fuehre deine Runde durch cineastische Krimi-Dinner-Abende auf Web, Android und iOS.',
        en: 'Create elegant lobbies, share QR codes, assign secret roles and guide your group through cinematic mystery dinner nights on web, Android and iOS.',
        fr: 'Cree des lobbies elegants, partage des QR codes, distribue des roles secrets et guide ton groupe dans des soirees de meurtre mystere cinematographiques sur web, Android et iOS.',
        es: 'Crea lobbies elegantes, comparte codigos QR, asigna roles secretos y guia a tu grupo por noches cinematograficas de cena misterio en web, Android e iOS.',
      );
  String get startGame => _pick(
        de: 'Spiel starten',
        en: 'Start game',
        fr: 'Commencer',
        es: 'Empezar',
      );

  String homeGreeting(String alias) => _pick(
        de: 'Guten Abend, $alias',
        en: 'Good evening, $alias',
        fr: 'Bonsoir, $alias',
        es: 'Buenas noches, $alias',
      );
  String get homeSubtitle => _pick(
        de: 'Starte ruhig und ohne Umwege in den Abend. Alles Weitere erscheint erst, sobald du in einer Lobby bist.',
        en: 'Ease into the evening without detours. Everything else appears as soon as you are inside a lobby.',
        fr: 'Commence tranquillement ta soiree. Le reste apparait des que tu es dans une lobby.',
        es: 'Empieza la noche sin rodeos. Todo lo demas aparece en cuanto entras en un lobby.',
      );
  String homeHeroText(bool hasLobby) => _pick(
        de: hasLobby
            ? 'Deine letzte Runde ist noch griffbereit.'
            : 'Hier beginnt dein naechster Krimi-Abend.',
        en: hasLobby
            ? 'Your latest round is still within reach.'
            : 'Your next mystery night begins here.',
        fr: hasLobby
            ? 'Ta derniere partie est encore a portee de main.'
            : 'Ta prochaine soiree mystere commence ici.',
        es: hasLobby
            ? 'Tu ultima partida sigue al alcance.'
            : 'Tu proxima noche de misterio empieza aqui.',
      );
  String homeHeroBody(bool hasLobby, String code) => _pick(
        de: hasLobby
            ? 'Die Lobby $code wartet noch auf dich. Wenn du magst, kannst du direkt dort weitermachen.'
            : 'Erstelle ein neues Spiel oder tritt direkt ueber einen Code oder Link einer Lobby bei.',
        en: hasLobby
            ? 'Lobby $code is still waiting for you. If you want, you can continue right there.'
            : 'Create a new game or join a lobby right away with a code or invitation link.',
        fr: hasLobby
            ? 'La lobby $code t attend encore. Si tu veux, tu peux reprendre directement ici.'
            : 'Cree une nouvelle partie ou rejoins une lobby avec un code ou un lien.',
        es: hasLobby
            ? 'El lobby $code sigue esperandote. Si quieres, puedes continuar directamente alli.'
            : 'Crea una partida nueva o entra a un lobby con un codigo o un enlace.',
      );
  String openLobbyLabel(String code) => _pick(
        de: 'Offene Lobby $code',
        en: 'Open lobby $code',
        fr: 'Lobby ouverte $code',
        es: 'Lobby abierto $code',
      );
  String get createGame => _pick(
        de: 'Neues Spiel erstellen',
        en: 'Create new game',
        fr: 'Creer une partie',
        es: 'Crear partida',
      );
  String get createGameSubtitle => _pick(
        de: 'Fall auswaehlen und direkt eine neue Lobby starten.',
        en: 'Choose a case and start a new lobby right away.',
        fr: 'Choisis une affaire et ouvre une nouvelle lobby.',
        es: 'Elige un caso y abre un nuevo lobby al instante.',
      );
  String get joinLobby => _pick(
        de: 'Lobby beitreten',
        en: 'Join lobby',
        fr: 'Rejoindre la lobby',
        es: 'Unirse al lobby',
      );
  String get joinLobbySubtitle => _pick(
        de: 'Per Code oder Einladungslink sofort in eine Runde gehen.',
        en: 'Jump into a round with a code or invitation link.',
        fr: 'Entre dans une partie avec un code ou un lien dinvitation.',
        es: 'Entra en una partida con un codigo o un enlace de invitacion.',
      );
  String get resumeLobby => _pick(
        de: 'Letzte Lobby fortsetzen',
        en: 'Resume last lobby',
        fr: 'Reprendre la derniere lobby',
        es: 'Reanudar ultimo lobby',
      );
  String resumeLobbySubtitle(String code) => _pick(
        de: 'Zur offenen Runde mit dem Code $code.',
        en: 'Back to the open round with code $code.',
        fr: 'Retour a la partie ouverte avec le code $code.',
        es: 'Vuelve a la partida abierta con el codigo $code.',
      );

  String get curatedArchive => _pick(
        de: 'Kuratiertes Krimi-Archiv',
        en: 'Curated mystery archive',
        fr: 'Archive mystere selectionnee',
        es: 'Archivo curado de misterio',
      );
  String get filterAll => _pick(
        de: 'Alle',
        en: 'All',
        fr: 'Tous',
        es: 'Todos',
      );
  String availableCases(int count) => _pick(
        de: 'Aktuell verfuegbar: $count spielbereite Faelle',
        en: 'Currently available: $count ready-to-play cases',
        fr: 'Disponibles actuellement : $count affaires pretes a jouer',
        es: 'Disponibles ahora: $count casos listos para jugar',
      );
  String playersLabel(int min, int max) => _pick(
        de: '$min-$max Spieler',
        en: '$min-$max players',
        fr: '$min-$max joueurs',
        es: '$min-$max jugadores',
      );
  String get openDetails => _pick(
        de: 'Details oeffnen',
        en: 'Open details',
        fr: 'Ouvrir les details',
        es: 'Abrir detalles',
      );
  String minutesShort(int minutes) => _pick(
        de: '$minutes Min',
        en: '$minutes min',
        fr: '$minutes min',
        es: '$minutes min',
      );
  String minutesLong(int minutes) => _pick(
        de: '$minutes Minuten',
        en: '$minutes minutes',
        fr: '$minutes minutes',
        es: '$minutes minutos',
      );
  String get caseNotFound => _pick(
        de: 'Dieser Fall wurde nicht gefunden.',
        en: 'This case could not be found.',
        fr: 'Cette affaire est introuvable.',
        es: 'No se encontro este caso.',
      );
  String get backToArchive => _pick(
        de: 'Zurueck zum Archiv',
        en: 'Back to archive',
        fr: 'Retour aux archives',
        es: 'Volver al archivo',
      );
  String get createLobbyLabel => _pick(
        de: 'Lobby erstellen',
        en: 'Create lobby',
        fr: 'Creer une lobby',
        es: 'Crear lobby',
      );
  String get caseOverviewTitle => _pick(
        de: 'Worum geht es?',
        en: 'What is it about?',
        fr: 'De quoi sagit-il ?',
        es: 'De que va?',
      );
  String get caseCharactersTitle => _pick(
        de: 'Figuren in dieser Runde',
        en: 'Characters in this round',
        fr: 'Personnages de cette partie',
        es: 'Personajes de esta ronda',
      );

  String get rolesArchiveTitle => _pick(
        de: 'Persoenliches Rollenarchiv',
        en: 'Personal role archive',
        fr: 'Archive personnelle des roles',
        es: 'Archivo personal de roles',
      );
  String get rolesArchiveSubtitle => _pick(
        de: 'Jede Rolle, die du im Verlauf einer Lobby zugewiesen bekommst, wird hier lokal festgehalten.',
        en: 'Every role assigned to you during a lobby is stored here locally.',
        fr: 'Chaque role qui t est attribue dans une lobby est conserve ici localement.',
        es: 'Cada rol que recibes durante un lobby se guarda aqui de forma local.',
      );
  String get noRolesTitle => _pick(
        de: 'Noch keine Rolle gespeichert.',
        en: 'No role saved yet.',
        fr: 'Aucun role enregistre pour le moment.',
        es: 'Todavia no hay ningun rol guardado.',
      );
  String get noRolesBody => _pick(
        de: 'Erstelle eine Lobby oder tritt einem Raum bei, um sofort dein erstes Dossier zu archivieren.',
        en: 'Create a lobby or join a room to archive your first dossier right away.',
        fr: 'Cree une lobby ou rejoins une salle pour archiver tout de suite ton premier dossier.',
        es: 'Crea un lobby o unete a una sala para archivar tu primer dossier al instante.',
      );
  String lobbyLabel(String code) => _pick(
        de: 'Lobby $code',
        en: 'Lobby $code',
        fr: 'Lobby $code',
        es: 'Lobby $code',
      );
  String goalLabel(String goal) => _pick(
        de: 'Ziel: $goal',
        en: 'Goal: $goal',
        fr: 'Objectif : $goal',
        es: 'Objetivo: $goal',
      );
  String unlockedFor(String playerName, String date) => _pick(
        de: 'Freigeschaltet fuer $playerName am $date',
        en: 'Unlocked for $playerName on $date',
        fr: 'Debloque pour $playerName le $date',
        es: 'Desbloqueado para $playerName el $date',
      );

  String get accountProfileTitle => _pick(
        de: 'Profil und Ermittlungshistorie',
        en: 'Profile and investigation history',
        fr: 'Profil et historique denquete',
        es: 'Perfil e historial de investigacion',
      );
  String get accountProfileSubtitle => _pick(
        de: 'Dein Anzeigename, echte Fortschritte und Kontakte bleiben lokal auf diesem Geraet gespeichert.',
        en: 'Your display name, real progress and contacts stay stored locally on this device.',
        fr: 'Ton nom daffichage, tes vrais progres et tes contacts restent enregistres localement sur cet appareil.',
        es: 'Tu nombre visible, tus progresos reales y tus contactos se guardan localmente en este dispositivo.',
      );
  String get accountFriendsTitle => _pick(
        de: 'Freunde',
        en: 'Friends',
        fr: 'Amis',
        es: 'Amigos',
      );
  String get accountFriendsSubtitle => _pick(
        de: 'Lokale Kontaktliste fuer Personen, mit denen du haeufig spielst. Ohne Backend bleiben die Daten nur auf diesem Geraet.',
        en: 'A local contact list for people you play with often. Without a backend, the data stays on this device only.',
        fr: 'Une liste de contacts locale pour les personnes avec qui tu joues souvent. Sans backend, les donnees restent uniquement sur cet appareil.',
        es: 'Una lista local de contactos para la gente con la que juegas a menudo. Sin backend, los datos se quedan solo en este dispositivo.',
      );
  String get addFriend => _pick(
        de: 'Freund hinzufuegen',
        en: 'Add friend',
        fr: 'Ajouter un ami',
        es: 'Anadir amigo',
      );
  String get emptyFriendsTitle => _pick(
        de: 'Noch keine Freunde vorhanden.',
        en: 'No friends added yet.',
        fr: 'Aucun ami ajoute pour le moment.',
        es: 'Todavia no hay amigos.',
      );
  String get emptyFriendsBody => _pick(
        de: 'Fuege Kontakte manuell hinzu oder uebernimm spaeter Spieler aus deinem Rollenarchiv.',
        en: 'Add contacts manually or later import players from your role archive.',
        fr: 'Ajoute des contacts manuellement ou importe plus tard des joueurs depuis ton archive de roles.',
        es: 'Anade contactos manualmente o importa mas tarde jugadores desde tu archivo de roles.',
      );
  String get friendSuggestionsTitle => _pick(
        de: 'Vorschlaege aus frueheren Rollen',
        en: 'Suggestions from earlier roles',
        fr: 'Suggestions issues des anciens roles',
        es: 'Sugerencias de roles anteriores',
      );
  String savedOn(String date) => _pick(
        de: 'Gespeichert am $date',
        en: 'Saved on $date',
        fr: 'Enregistre le $date',
        es: 'Guardado el $date',
      );
  String get editFriend => _pick(
        de: 'Bearbeiten',
        en: 'Edit',
        fr: 'Modifier',
        es: 'Editar',
      );
  String get removeFriend => _pick(
        de: 'Entfernen',
        en: 'Remove',
        fr: 'Supprimer',
        es: 'Eliminar',
      );
  String get removeFriendTitle => _pick(
        de: 'Freund entfernen?',
        en: 'Remove friend?',
        fr: 'Supprimer cet ami ?',
        es: 'Quitar amigo?',
      );
  String removeFriendBody(String name) => _pick(
        de: '$name wird aus deiner lokalen Freundesliste entfernt.',
        en: '$name will be removed from your local friends list.',
        fr: '$name sera retire de ta liste damis locale.',
        es: '$name se quitara de tu lista local de amigos.',
      );
  String get cancel => _pick(
        de: 'Abbrechen',
        en: 'Cancel',
        fr: 'Annuler',
        es: 'Cancelar',
      );
  String get save => _pick(
        de: 'Speichern',
        en: 'Save',
        fr: 'Enregistrer',
        es: 'Guardar',
      );
  String get profileSaved => _pick(
        de: 'Dein Anzeigename wurde aktualisiert.',
        en: 'Your display name was updated.',
        fr: 'Ton nom daffichage a ete mis a jour.',
        es: 'Tu nombre visible se ha actualizado.',
      );
  String get displayNameEmpty => _pick(
        de: 'Bitte gib einen Anzeigenamen ein.',
        en: 'Please enter a display name.',
        fr: 'Merci de saisir un nom daffichage.',
        es: 'Introduce un nombre visible.',
      );
  String get friendSaved => _pick(
        de: 'Freund wurde gespeichert.',
        en: 'Friend saved.',
        fr: 'Ami enregistre.',
        es: 'Amigo guardado.',
      );
  String get friendUpdated => _pick(
        de: 'Freund wurde aktualisiert.',
        en: 'Friend updated.',
        fr: 'Ami mis a jour.',
        es: 'Amigo actualizado.',
      );
  String get friendRemoved => _pick(
        de: 'Freund wurde entfernt.',
        en: 'Friend removed.',
        fr: 'Ami supprime.',
        es: 'Amigo eliminado.',
      );
  String get accountSettingsTitle => _pick(
        de: 'Einstellungen',
        en: 'Settings',
        fr: 'Parametres',
        es: 'Ajustes',
      );
  String get accountSettingsSubtitle => _pick(
        de: 'Theme, Sprache, Audio-Regler und Toggles werden bereits gespeichert. Benachrichtigungen steuern die In-App-Rueckmeldungen.',
        en: 'Theme, language, audio sliders and toggles are already saved. Notifications control in-app feedback.',
        fr: 'Le theme, la langue, les curseurs audio et les interrupteurs sont deja sauvegardes. Les notifications controlent les retours dans lapp.',
        es: 'El tema, el idioma, los deslizadores de audio y los interruptores ya se guardan. Las notificaciones controlan la respuesta dentro de la app.',
      );
  String get achievementsTitle => _pick(
        de: 'Achievements',
        en: 'Achievements',
        fr: 'Succes',
        es: 'Logros',
      );
  String get achievementsSubtitle => _pick(
        de: 'Fortschritt auf Basis deiner echten Lobbys, Rollen und Kontakte.',
        en: 'Progress based on your real lobbies, roles and contacts.',
        fr: 'Progression basee sur tes vraies lobbies, roles et contacts.',
        es: 'Progreso basado en tus lobbies, roles y contactos reales.',
      );
  String get accountHintTitle => _pick(
        de: 'Hinweis',
        en: 'Note',
        fr: 'Note',
        es: 'Nota',
      );
  String get accountHintBody => _pick(
        de: 'Musik- und Effektlautstaerke sind jetzt echte, gespeicherte Felder. Fuer hoerbare Ausgabe brauchen wir als naechsten Schritt nur noch die finalen Audio-Dateien und die Playback-Anbindung.',
        en: 'Music and effects volume are now real saved fields. For audible output, the next step is to wire in the final audio assets and playback.',
        fr: 'Le volume de la musique et des effets est maintenant enregistre pour de vrai. Pour un rendu audible, il nous reste a brancher les fichiers audio finaux et la lecture.',
        es: 'El volumen de la musica y de los efectos ahora es un campo real guardado. Para una salida audible solo falta conectar los audios finales y la reproduccion.',
      );
  String get profileCardTitle => _pick(
        de: 'Dein Profil',
        en: 'Your profile',
        fr: 'Ton profil',
        es: 'Tu perfil',
      );
  String get displayNameLabel => _pick(
        de: 'Anzeigename',
        en: 'Display name',
        fr: 'Nom affiche',
        es: 'Nombre visible',
      );
  String get nameLabel => _pick(
        de: 'Name',
        en: 'Name',
        fr: 'Nom',
        es: 'Nombre',
      );
  String get displayNameHelper => _pick(
        de: 'Wird lokal gespeichert und fuer neue Lobbys uebernommen.',
        en: 'Stored locally and reused for new lobbies.',
        fr: 'Enregistre localement et reutilise pour les nouvelles lobbies.',
        es: 'Se guarda localmente y se reutiliza para nuevos lobbies.',
      );
  String get saveProfile => _pick(
        de: 'Profil speichern',
        en: 'Save profile',
        fr: 'Enregistrer le profil',
        es: 'Guardar perfil',
      );
  String get optionalFavoriteCaseLabel => _pick(
        de: 'Lieblingsfall (optional)',
        en: 'Favorite case (optional)',
        fr: 'Affaire preferee (optionnel)',
        es: 'Caso favorito (opcional)',
      );
  String get optionalFavoriteRoleLabel => _pick(
        de: 'Lieblingsrolle (optional)',
        en: 'Favorite role (optional)',
        fr: 'Role prefere (optionnel)',
        es: 'Rol favorito (opcional)',
      );
  String get optionalNoteLabel => _pick(
        de: 'Notiz (optional)',
        en: 'Note (optional)',
        fr: 'Note (optionnel)',
        es: 'Nota (opcional)',
      );
  String get statsTitle => _pick(
        de: 'Statistiken',
        en: 'Stats',
        fr: 'Statistiques',
        es: 'Estadisticas',
      );
  String get startedLabel => _pick(
        de: 'Gestartet',
        en: 'Started',
        fr: 'Lancees',
        es: 'Iniciadas',
      );
  String get completedLabel => _pick(
        de: 'Abgeschlossen',
        en: 'Completed',
        fr: 'Terminees',
        es: 'Completadas',
      );
  String get cluesLabel => _pick(
        de: 'Hinweise',
        en: 'Clues',
        fr: 'Indices',
        es: 'Pistas',
      );
  String get friendsLabel => _pick(
        de: 'Freunde',
        en: 'Friends',
        fr: 'Amis',
        es: 'Amigos',
      );
  String favoriteRoleLabel(String value) => _pick(
        de: 'Lieblingsrolle: $value',
        en: 'Favorite role: $value',
        fr: 'Role prefere : $value',
        es: 'Rol favorito: $value',
      );
  String favoriteCaseLabel(String value) => _pick(
        de: 'Lieblingsfall: $value',
        en: 'Favorite case: $value',
        fr: 'Affaire preferee : $value',
        es: 'Caso favorito: $value',
      );
  String statsFooter({
    required int roles,
    required int activeLobbies,
    required String hours,
  }) {
    return _pick(
      de: 'Archivierte Rollen: $roles · Aktive Lobbys: $activeLobbies · Spielzeit: $hours h',
      en: 'Archived roles: $roles · Active lobbies: $activeLobbies · Play time: $hours h',
      fr: 'Roles archives : $roles · Lobbies actives : $activeLobbies · Temps de jeu : $hours h',
      es: 'Roles archivados: $roles · Lobbies activos: $activeLobbies · Tiempo de juego: $hours h',
    );
  }
  String get achievementUnlocked => _pick(
        de: 'Freigeschaltet',
        en: 'Unlocked',
        fr: 'Debloque',
        es: 'Desbloqueado',
      );
  String get achievementInProgress => _pick(
        de: 'In Arbeit',
        en: 'In progress',
        fr: 'En cours',
        es: 'En progreso',
      );
  String get themeLabel => _pick(
        de: 'Theme',
        en: 'Theme',
        fr: 'Theme',
        es: 'Tema',
      );
  String themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return _pick(de: 'Dunkel', en: 'Dark', fr: 'Sombre', es: 'Oscuro');
      case ThemeMode.light:
        return _pick(de: 'Hell', en: 'Light', fr: 'Clair', es: 'Claro');
      case ThemeMode.system:
        return _pick(de: 'System', en: 'System', fr: 'Systeme', es: 'Sistema');
    }
  }
  String get languageLabel => _pick(
        de: 'Sprache',
        en: 'Language',
        fr: 'Langue',
        es: 'Idioma',
      );
  String languageOptionLabel(AppLanguage option) {
    switch (option) {
      case AppLanguage.de:
        return 'Deutsch';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.fr:
        return 'Francais';
      case AppLanguage.es:
        return 'Espanol';
    }
  }
  String musicVolumeLabel(int value) => _pick(
        de: 'Musiklautstaerke ($value%)',
        en: 'Music volume ($value%)',
        fr: 'Volume de la musique ($value%)',
        es: 'Volumen de la musica ($value%)',
      );
  String sfxVolumeLabel(int value) => _pick(
        de: 'Effektlautstaerke ($value%)',
        en: 'Effects volume ($value%)',
        fr: 'Volume des effets ($value%)',
        es: 'Volumen de efectos ($value%)',
      );
  String get animationsTitle => _pick(
        de: 'Animationen aktivieren',
        en: 'Enable animations',
        fr: 'Activer les animations',
        es: 'Activar animaciones',
      );
  String get animationsSubtitle => _pick(
        de: 'Schaltet weiche Uebergaenge und kleine UI-Bewegungen an oder aus.',
        en: 'Turns smooth transitions and small UI motions on or off.',
        fr: 'Active ou desactive les transitions fluides et les petits mouvements de linterface.',
        es: 'Activa o desactiva transiciones suaves y pequenos movimientos de la interfaz.',
      );
  String get notificationsTitle => _pick(
        de: 'Benachrichtigungen',
        en: 'Notifications',
        fr: 'Notifications',
        es: 'Notificaciones',
      );
  String get notificationsSubtitle => _pick(
        de: 'Steuert Rueckmeldungen wie Snackbars innerhalb der App.',
        en: 'Controls in-app feedback such as snackbars.',
        fr: 'Controle les retours dans lapp comme les snackbars.',
        es: 'Controla avisos dentro de la app como las snackbars.',
      );

  String categoryLabel(MysteryCategory category) {
    switch (category) {
      case MysteryCategory.halloween:
        return _pick(de: 'Halloween', en: 'Halloween', fr: 'Halloween', es: 'Halloween');
      case MysteryCategory.christmas:
        return _pick(de: 'Weihnachten', en: 'Christmas', fr: 'Noel', es: 'Navidad');
      case MysteryCategory.newYearsEve:
        return _pick(de: 'Silvester', en: 'New Year', fr: 'Nouvel An', es: 'Ano nuevo');
      case MysteryCategory.mafia:
        return _pick(de: 'Mafia', en: 'Mafia', fr: 'Mafia', es: 'Mafia');
      case MysteryCategory.luxuryVilla:
        return _pick(de: 'Luxusvilla', en: 'Luxury villa', fr: 'Villa de luxe', es: 'Villa de lujo');
      case MysteryCategory.orientExpress:
        return _pick(de: 'Orient Express', en: 'Orient Express', fr: 'Orient Express', es: 'Orient Express');
      case MysteryCategory.medieval:
        return _pick(de: 'Mittelalter', en: 'Medieval', fr: 'Medieval', es: 'Medieval');
      case MysteryCategory.pirates:
        return _pick(de: 'Piraten', en: 'Pirates', fr: 'Pirates', es: 'Piratas');
      case MysteryCategory.casino:
        return _pick(de: 'Casino', en: 'Casino', fr: 'Casino', es: 'Casino');
      case MysteryCategory.twenties:
        return _pick(de: '1920er Jahre', en: 'Roaring Twenties', fr: 'Annees 1920', es: 'Anos veinte');
      case MysteryCategory.vampires:
        return _pick(de: 'Vampire', en: 'Vampires', fr: 'Vampires', es: 'Vampiros');
      case MysteryCategory.wizards:
        return _pick(de: 'Zauberer', en: 'Wizards', fr: 'Sorciers', es: 'Magos');
      case MysteryCategory.detectiveSchool:
        return _pick(de: 'Detektivschule', en: 'Detective school', fr: 'Ecole de detective', es: 'Escuela de detectives');
      case MysteryCategory.agents:
        return _pick(de: 'Agenten', en: 'Agents', fr: 'Agents', es: 'Agentes');
      case MysteryCategory.zombie:
        return _pick(de: 'Zombie-Apokalypse', en: 'Zombie apocalypse', fr: 'Apocalypse zombie', es: 'Apocalipsis zombi');
      case MysteryCategory.custom:
        return _pick(de: 'Eigenes Krimi-Dinner', en: 'Custom mystery dinner', fr: 'Mystere personnalise', es: 'Misterio personalizado');
    }
  }

  String difficultyLabel(CaseDifficulty difficulty) {
    switch (difficulty) {
      case CaseDifficulty.relaxed:
        return _pick(de: 'Entspannt', en: 'Relaxed', fr: 'Detendu', es: 'Relajado');
      case CaseDifficulty.medium:
        return _pick(de: 'Knifflig', en: 'Tricky', fr: 'Subtil', es: 'Desafiante');
      case CaseDifficulty.sharp:
        return _pick(de: 'Anspruchsvoll', en: 'Demanding', fr: 'Exigeant', es: 'Exigente');
      case CaseDifficulty.mastermind:
        return _pick(de: 'Meisterhaft', en: 'Mastermind', fr: 'Expert', es: 'Maestro');
    }
  }
}
