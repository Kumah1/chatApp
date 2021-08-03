const IS_TOKEN_GENERATED = 'isTokenGenerated';
const NOTIFICATION_TOKENS = 'notificationTokens';
const PHOTO_URL = 'photoUrl';
const USERS = 'Users';
const MESSAGES = 'messages';
const ANSWER_TRIES = 'answerTries';
const PASSCODE_TRIES = 'passcodeTries';
const ABOUT_ME = 'aboutMe';
const NICKNAME = 'nickname';
const TYPE = 'type';
const FROM = 'from';
const TO = 'to';
const CONTENT = 'content';
const CHATS_WITH = 'chatsWith';
const CHAT_STATUS = 'chatStatus';
const LAST_SEEN = 'lastSeen';
const PHONE = 'phone';
const ID = 'id';
const ANSWER = 'answer';
const QUESTION = 'question';
const PASSCODE = 'passcode';
const HIDDEN = 'hidden';
const LOCKED = 'locked';
const DELETE_UPTO = 'deleteUpto';
const TIMESTAMP = 'timestamp';
const LAST_ANSWERED = 'lastAnswered';
const LAST_ATTEMPT = 'lastAttempt';
const AUTHENTICATION_TYPE = 'authenticationType';
const CACHED_CONTACTS = 'cachedContacts';
const SAVED = 'saved';
const ALIAS_NAME = 'aliasName';
const ALIAS_AVATAR = 'aliasAvatar';
const PUBLIC_KEY = 'publicKey';
const PRIVATE_KEY = 'privateKey';
const PRIVACY_POLICY_URL = 'https://amitjoki.github.io/Enigma/Privacy_Policy';
const COUNTRY_CODE = 'countryCode';
const WALLPAPER = 'wallpaper';
const CRC_SEPARATOR = '&';
const TRIES_THRESHOLD = 3;
const TIME_BASE = 2;

enum ChatStatus { blocked, waiting, requested, accepted }
enum MessageType { text, image, video, audio, files, contact }
enum AuthenticationType { passcode, biometric }
void unawaited(Future<void> future) {}
const CountryCode_TrunkCode = [
  ["93", "0"],
  ["355", "0"],
  ["213", "0"],
  ["1", "1"],
  ["376", "-"],
  ["244", "-"],
  ["1", "1"],
  ["1", "1"],
  ["54", "0"],
  ["374", "0"],
  ["297", "-"],
  ["247", "-"],
  ["61", "0"],
  ["43", "0"],
  ["994", "0"],
  ["1", "1"],
  ["973", "-"],
  ["880", "0"],
  ["1", "1"],
  ["375", "80"],
  ["32", "0"],
  ["501", "-"],
  ["229", "-"],
  ["1", "1"],
  ["975", "-"],
  ["591", "0"],
  ["387", "0"],
  ["267", "-"],
  ["55", "0"],
  ["1", "1"],
  ["673", "-"],
  ["359", "0"],
  ["226", "-"],
  ["257", "-"],
  ["855", "0"],
  ["237", "-"],
  ["1", "1"],
  ["238", "-"],
  ["1", "1"],
  ["236", "-"],
  ["235", "-"],
  ["56", "-"],
  ["86", "0"],
  ["57", "0"],
  ["269", "-"],
  ["242", "-"],
  ["682", "-"],
  ["506", "-"],
  ["385", "0"],
  ["53", "0"],
  ["599", "0"],
  ["357", "-"],
  ["420", "-"],
  ["243", "0"],
  ["45", "-"],
  ["246", "-"],
  ["253", "-"],
  ["1", "1"],
  ["1", "1"],
  ["670", "-"],
  ["593", "0"],
  ["20", "0"],
  ["503", "-"],
  ["240", "-"],
  ["291", "0"],
  ["372", "-"],
  ["251", "0"],
  ["500", "-"],
  ["298", "-"],
  ["679", "-"],
  ["358", "0"],
  ["33", "0"],
  ["594", "0"],
  ["689", "-"],
  ["241", "-"],
  ["220", "-"],
  ["995", "0"],
  ["49", "0"],
  ["233", "0"],
  ["350", "-"],
  ["30", "-"],
  ["299", "-"],
  ["1", "1"],
  ["590", "0"],
  ["1", "1"],
  ["502", "-"],
  ["224", "-"],
  ["245", "-"],
  ["592", "-"],
  ["509", "-"],
  ["504", "-"],
  ["852", "-"],
  ["36", "06"],
  ["354", "-"],
  ["91", "0"],
  ["62", "0"],
  ["870", "-"],
  ["98", "0"],
  ["964", "-"],
  ["353", "0"],
  ["8816", "-"],
  ["8817", "-"],
  ["972", "0"],
  ["39", "-"],
  ["225", "-"],
  ["1", "1"],
  ["81", "0"],
  ["962", "0"],
  ["7", "8"],
  ["254", "0"],
  ["686", "-"],
  ["965", "-"],
  ["996", "0"],
  ["856", "0"],
  ["371", "-"],
  ["961", "0"],
  ["266", "-"],
  ["231", "-"],
  ["218", "0"],
  ["423", "-"],
  ["370", "8"],
  ["352", "-"],
  ["853", "-"],
  ["389", "0"],
  ["261", "0"],
  ["265", "-"],
  ["60", "0"],
  ["960", "-"],
  ["223", "-"],
  ["356", "-"],
  ["692", "1"],
  ["596", "0"],
  ["222", "-"],
  ["230", "-"],
  ["262", "0"],
  ["52", "01|044|045"],
  ["691", "1"],
  ["373", "0"],
  ["377", "-"],
  ["976", "0"],
  ["382", "0"],
  ["1", "1"],
  ["212", "0"],
  ["258", "-"],
  ["95", "0"],
  ["264", "0"],
  ["674", "-"],
  ["977", "0"],
  ["31", "0"],
  ["599", "0"],
  ["687", "-"],
  ["64", "0"],
  ["505", "-"],
  ["227", "-"],
  ["234", "0"],
  ["683", "-"],
  ["6723", "-"],
  ["850", "-"],
  ["1", "1"],
  ["47", "-"],
  ["968", "-"],
  ["92", "0"],
  ["680", "-"],
  ["970", "0"],
  ["507", "-"],
  ["675", "-"],
  ["595", "0"],
  ["51", "0"],
  ["63", "0"],
  ["48", "-"],
  ["351", "-"],
  ["1", "1"],
  ["974", "-"],
  ["262", "0"],
  ["40", "0"],
  ["7", "8"],
  ["250", "-"],
  ["290", "-"],
  ["1", "1"],
  ["1", "1"],
  ["590", "0"],
  ["590", "0"],
  ["508", "-"],
  ["1", "1"],
  ["685", "-"],
  ["378", "-"],
  ["239", "-"],
  ["966", "0"],
  ["221", "-"],
  ["381", "0"],
  ["248", "-"],
  ["232", "0"],
  ["65", "-"],
  ["1", "1"],
  ["421", "0"],
  ["386", "0"],
  ["677", "-"],
  ["252", "-"],
  ["27", "0"],
  ["82", "0"],
  ["211", "-"],
  ["34", "-"],
  ["94", "0"],
  ["249", "0"],
  ["597", "0"],
  ["268", "-"],
  ["46", "0"],
  ["41", "0"],
  ["963", "0"],
  ["886", "0"],
  ["992", "8"],
  ["255", "0"],
  ["66", "0"],
  ["882 16", "-"],
  ["228", "-"],
  ["690", "-"],
  ["676", "-"],
  ["1", "1"],
  ["216", "-"],
  ["90", "0"],
  ["993", "8"],
  ["1", "1"],
  ["688", "-"],
  ["256", "0"],
  ["380", "0"],
  ["971", "0"],
  ["44", "0"],
  ["1", "1"],
  ["1", "1"],
  ["598", "0"],
  ["998", "0"],
  ["678", "-"],
  ["379", "-"],
  ["39", "-"],
  ["58", "0"],
  ["84", "0"],
  ["681", "-"],
  ["967", "0"],
  ["260", "0"],
  ["263", "0"]
];
