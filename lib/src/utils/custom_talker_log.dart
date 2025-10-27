import 'package:talker/talker.dart';

class ShowResponseLog extends TalkerLog {
  ShowResponseLog(String super.message);

  /// Your custom log title
  @override
  String get title => 'API Response';

  /// Your custom log color
  @override
  AnsiPen get pen => AnsiPen()..xterm(199);
}
