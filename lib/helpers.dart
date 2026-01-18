import 'dart:developer';

String get currentMethod {
   final stacktrace = StackTrace.current;
  final stackLines = stacktrace.toString().split('\n');
  final callerInfo = stackLines.length > 1 ? stackLines[1] : 'Unknown';
  final mtag = callerInfo.split('(').first.trim();
  return mtag;
}

void printLog(dynamic d, {StackTrace? s, String? tag}) {
  final stacktrace = StackTrace.current;
  final stackLines = stacktrace.toString().split('\n');
  final callerInfo = stackLines.length > 1 ? stackLines[1] : 'Unknown';
  final mtag = callerInfo.split('(').first.trim();
  log(
    '${'$mtag ${tag ?? ''}'} : $d, \n ${s != null ? 'stackTrace $s' : ''} '
        .toString(),
  );
}
