import 'package:amplitude_repository/amplitude_repository.dart';
import 'package:logging/logging.dart';
import 'package:sentry_repository/sentry_repository.dart';

// TODO: Update 'CHANGE ME'

class MainConfigurations {
  static const appLocalhost = String.fromEnvironment('APP_LOCALHOST');

  static MainConfiguration development = MainConfiguration(
    logLevel: Level.ALL,
    useReduxDevtools: false,
    amplitudeRepositoryConfiguration: AmplitudeRepositoryConfiguration(
      apiKey: 'CHANGE_ME',
      sendEvents: false,
    ),
    sentryRepositoryConfiguration: null,
  );

  static MainConfiguration developmentWithReduxDevtools = MainConfiguration(
    logLevel: Level.ALL,
    useReduxDevtools: true,
    amplitudeRepositoryConfiguration: AmplitudeRepositoryConfiguration(
      apiKey: 'CHANGE_ME',
      sendEvents: false,
    ),
    sentryRepositoryConfiguration: null,
  );

  static MainConfiguration developmentAndSendEvents = MainConfiguration(
    logLevel: Level.ALL,
    useReduxDevtools: true,
    amplitudeRepositoryConfiguration: AmplitudeRepositoryConfiguration(
      apiKey: 'CHANGE_ME',
      sendEvents: true,
    ),
    sentryRepositoryConfiguration: SentryRepositoryConfiguration(
      sentryDSN: 'CHANGE ME',
      sentryEnvironment: 'CHANG ME',
    ),
  );

  static MainConfiguration production = MainConfiguration(
    logLevel: Level.INFO,
    useReduxDevtools: false,
    amplitudeRepositoryConfiguration: AmplitudeRepositoryConfiguration(
      apiKey: 'CHANGE_ME',
      sendEvents: true,
    ),
    sentryRepositoryConfiguration: SentryRepositoryConfiguration(
      sentryDSN: 'CHANGE ME',
      sentryEnvironment: 'CHANGE ME',
    ),
  );
}

class MainConfiguration {
  MainConfiguration({
    required this.logLevel,
    required this.useReduxDevtools,
    required this.amplitudeRepositoryConfiguration,
    required this.sentryRepositoryConfiguration,
  });

  final Level logLevel;
  final bool useReduxDevtools;
  final AmplitudeRepositoryConfiguration amplitudeRepositoryConfiguration;
  final SentryRepositoryConfiguration? sentryRepositoryConfiguration;
}
