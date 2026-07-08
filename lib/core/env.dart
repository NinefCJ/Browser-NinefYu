import 'package:flutter/material.dart';

/// 环境配置
enum Environment {
  development,
  staging,
  production,
}

class EnvConfig {
  final Environment environment;
  final String appName;
  final String apiBaseUrl;
  final bool debugMode;
  final bool enableLogging;

  const EnvConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    this.debugMode = false,
    this.enableLogging = true,
  });

  static const EnvConfig dev = EnvConfig(
    environment: Environment.development,
    appName: 'Browser Dev',
    apiBaseUrl: 'https://api-dev.example.com',
    debugMode: true,
    enableLogging: true,
  );

  static const EnvConfig staging = EnvConfig(
    environment: Environment.staging,
    appName: 'Browser Beta',
    apiBaseUrl: 'https://api-staging.example.com',
    debugMode: false,
    enableLogging: true,
  );

  static const EnvConfig prod = EnvConfig(
    environment: Environment.production,
    appName: 'Browser NinefYu',
    apiBaseUrl: 'https://api.example.com',
    debugMode: false,
    enableLogging: false,
  );
}

class Env {
  static EnvConfig _current = EnvConfig.dev;

  static EnvConfig get current => _current;

  static void setEnvironment(Environment env) {
    switch (env) {
      case Environment.development:
        _current = EnvConfig.dev;
        break;
      case Environment.staging:
        _current = EnvConfig.staging;
        break;
      case Environment.production:
        _current = EnvConfig.prod;
        break;
    }
  }

  static bool get isDev => _current.environment == Environment.development;
  static bool get isProd => _current.environment == Environment.production;
}