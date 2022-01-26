import 'dart:core' as core;

abstract class Logger {
  static void print(core.Object object) async {
    core.int defaultPrintLength = 1020;
    if (object == null || object.toString().length <= defaultPrintLength) {
      core.print(object);
    } else {
      core.String log = object.toString();
      core.int start = 0;
      core.int endIndex = defaultPrintLength;
      core.int logLength = log.length;
      core.int tmpLogLength = log.length;
      while (endIndex < logLength) {
        core.print(log.substring(start, endIndex));
        endIndex += defaultPrintLength;
        start += defaultPrintLength;
        tmpLogLength -= defaultPrintLength;
      }
      if (tmpLogLength > 0) {
        core.print(log.substring(start, logLength));
      }
    }
  }
}
