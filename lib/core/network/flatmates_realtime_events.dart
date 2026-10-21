/// Broadcast events of the flatmates realtime bus, used only when the bootstrap
/// response has no `realtime.events` list. The bootstrap list wins whenever it
/// is present, so the backend can add an event without an app release.
///
/// This is the one fallback list of the client. The file has no imports so the
/// code generators can load the bootstrap models that read it.
const List<String> kFlatmatesRealtimeEvents = [
  'new_match',
  'new_message',
  'conversation_updated',
  'visit_updated',
  'listing_status_changed',
  'new_notification',
];
