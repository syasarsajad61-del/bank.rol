// [BL01][BL12] Board indices and serpentine coordinates.
import 'properties_data.dart';
import '../rules/path_calculator.dart';
import '../models/board_path_point.dart';

int boardIndexOf(String id) =>
    BOARD.firstWhere((b) => b.propertyId == id).index;
List<BoardPathPoint> get boardPath => PathCalculator.points();
