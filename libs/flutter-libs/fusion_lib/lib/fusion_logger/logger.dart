import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mutex/mutex.dart';

/// A utility class for logging messages to both the console and a log file.
///
/// The `FusionLogger` class provides a structured way to log messages with different
/// severity levels. Logs include timestamps, tags, and emojis for readability.
///
/// ### Features:
/// - Logs messages to the console.
/// - Writes logs to a file for persistent storage.
/// - Supports different log levels with corresponding emojis for clarity.
/// - Can be used to track application behavior, errors, and debugging information.
///
/// ### Example Usage:
/// ```dart
/// FusionLogger.log(
///   tag: "Auth",
///   message: "User login successful",
///   logLevel: LogLevel.info
/// );
///
/// FusionLogger.log(
///   tag: "Network",
///   message: "Failed to fetch user data - timeout",
///   logLevel: LogLevel.error
/// );
/// ```
///
/// ### Supported Log Levels:
/// | Level    | Emoji | Description                         |
/// |----------|------|-------------------------------------|
/// | `trace`  | ⏳   | Detailed tracing information       |
/// | `debug`  | 🐛   | Debugging information              |
/// | `info`   | 💡   | General application information   |
/// | `warning`| ⚠️   | Warnings that may require attention |
/// | `error`  | ❌   | Errors that impact functionality   |
/// | `fatal`  | 💥   | Critical errors that may cause crashes |
class FusionLogger {
  /// Create a Singleton class instance
  static final FusionLogger _instance = FusionLogger._internal();

  /// internal constructor to prevent external instantiation of the class
  FusionLogger._internal();

  /// Factory constructor to return the singleton instance
  factory FusionLogger() {
    return _instance;
  }

  /// Mutex to ensure only one writer is active at a time
  /// _mutex is similar to Lock in android, here we want a single writer at any given point of time
  static final Mutex _mutex = Mutex();

  static File? _logFile;

  /// max file size for the log file
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB

  /// Logs directory name
  static const String logsDirectory = "Logs";

  /// Initialize the logger
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      excludeBox: <Level, bool>{Level.trace: true, Level.info: true, Level.debug: true},
      dateTimeFormat: DateTimeFormat.none,
    ),
    output: ConsoleOutput(),
  );

  /// Log function that prints to console and logs to file
  static void log({required String tag, required String message, LogLevel logLevel = LogLevel.info}) async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String date = formatter.format(DateTime.now().toLocal());

    final String logMessage = "$date : $tag : $message";
    String logEmoji = "💡";
    switch (logLevel) {
      case LogLevel.trace:
        logEmoji = "⏳";
        _logger.t(logMessage);
        break;
      case LogLevel.debug:
        logEmoji = "🐛";
        _logger.d(logMessage);
        break;
      case LogLevel.info:
        _logger.i(logMessage);
        break;
      case LogLevel.warning:
        logEmoji = "⚠️";
        _logger.w(logMessage);
        break;
      case LogLevel.error:
        logEmoji = "❌";
        _logger.e(logMessage);
        break;
      case LogLevel.fatal:
        logEmoji = "💥";
        _logger.f(logMessage);
        break;
    }

    final String logString = "$logEmoji : $logMessage";

    writeLogToFile(logString);
  }

  /// Write Logs to the text file for debugging purposes
  static Future<void> writeLogToFile(String logString) async {
    await _mutex.protect(() async {
      /// setup the log file if it doesn't set already
      ///
      if (_logFile == null) {
        await _setupLogFile();
      }

      try {
        final String data = "$logString\n";
        final RandomAccessFile file = await _logFile!.open(mode: FileMode.append);
        await file.writeString(data);
        await file.close();

        /// check if file size is exceeding the limit, if yes, rotate the file
        await _checkAndRotateLogFile();
      } catch (error) {
        debugPrint('Error saving the logs $error');
      }
    });
  }

  /// Setup the log file
  static Future<void> _setupLogFile() async {
    final Directory directory = await FusionUtils.getOrCreateDirectory(logsDirectory);
    _logFile = File('${directory.path}/app_log.txt');

    // If file does not exist, create it
    if (!(await _logFile!.exists())) {
      await _logFile!.create();
    }
  }

  /// Check if log file exceeds size limit, if yes, rotate it
  static Future<void> _checkAndRotateLogFile() async {
    if (_logFile != null && await _logFile!.exists()) {
      final int fileSize = await _logFile!.length();
      if (fileSize >= maxFileSize) {
        await _rotateLogFile();
      }
    }
  }

  /// Rotates the log file by renaming it with a timestamp
  static Future<void> _rotateLogFile() async {
    final Directory directory = await FusionUtils.getOrCreateDirectory(logsDirectory);
    final String timestamp = DateFormat('yyyy-MM-dd_HH:mm:ss').format(DateTime.now());
    final File rotatedFile = File('${directory.path}/app_log_$timestamp.txt');

    await _logFile!.rename(rotatedFile.path); // Rename old file
    await _setupLogFile(); // Create new log file
  }

  static Future<List<File>> getPendingLogsList() async {
    List<File> files = [];
    final directory = Directory.systemTemp.createTempSync();
    final logsDir = await FusionUtils.getOrCreateDirectory(logsDirectory);
    final logsFiles = await FusionUtils.contentsOfDirectory(logsDir);

    List<File> logs = [];
    if (logsFiles.isNotEmpty) {
      for (final file in logsFiles) {
        if (file.path.contains("app_log")) {
          logs.add(file);
        }
      }
    }

    if (logs.isNotEmpty) {
      var logZip = await FusionUtils.zipMultipleFile(logs, "FusionLogs", directory.path);
      if (logZip != null) {
        files.add(logZip);
      }
    }
    return files;
  }
}

/// Enum for log levels to decide the log type
enum LogLevel { trace, debug, info, warning, error, fatal }

/// LogTag for logs to determine the type of log for debug purposes
class LogTag {
  static const String debug = 'DEBUG';
  static const String settings = 'SETTINGS';
  static const String exceptions = 'EXCEPTIONS';
  static const String fusion = 'FUSION';
  static const String project = 'PROJECT';
  static const String dro = 'DRO';
  static const String dspConfig = 'DSP_CONFIG';
  static const String userConfig = 'USER_CONFIG';
  static const String network = 'NETWORK';
  static const String zmq = 'ZMQ';
  static const String panel = 'PANEL';
  static const String ble = 'BLE';
  static const String permission = 'PERMISSIONS';
}
