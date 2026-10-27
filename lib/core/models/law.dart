// [R25] Immutable enacted law model.
import '../data/laws_data.dart';

class Law {
  final LawData data;
  final int enactedRound;
  const Law(this.data, this.enactedRound);
  Map<String, dynamic> toJson() => {
    'id': data.id,
    'enactedRound': enactedRound,
  };
}
