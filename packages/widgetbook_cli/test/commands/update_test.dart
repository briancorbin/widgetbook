import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../../bin/helpers/version.dart';
import '../../bin/app/widgetbook_command_runner.dart';
import '../mocks/mocks.dart';

void main() {
  const latestVersion = '0.0.0';

  group('widgetbook upgrade', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late WidgetbookCommandRunner widgetbookCommandRunner;

    setUp(() {
      logger = MockLogger();
      pubUpdater = MockPubUpdater();

      when(() => logger.progress(any())).thenReturn(MockProgress());
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => currentVersion);
      when(
        () => pubUpdater.update(packageName: packageName),
      ).thenAnswer((_) => Future.value(FakeProcessResult()));

      widgetbookCommandRunner = WidgetbookCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
    });

    test('handles pub latest version query errors', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenThrow(Exception('oops'));
      final result = await widgetbookCommandRunner.run(['upgrade']);
      expect(result, equals(ExitCode.software.code));
      verify(() => logger.progress('Checking for updates')).called(1);
      verify(() => logger.err('Exception: oops'));
      verifyNever(
        () => pubUpdater.update(packageName: any(named: 'packageName')),
      );
    });

    test('handles pub update errors', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => latestVersion);
      when(
        () => pubUpdater.update(packageName: any(named: 'packageName')),
      ).thenThrow(Exception('oops'));
      final result = await widgetbookCommandRunner.run(['upgrade']);
      expect(result, equals(ExitCode.software.code));
      verify(() => logger.progress('Checking for updates')).called(1);
      verify(() => logger.err('Exception: oops'));
      verify(
        () => pubUpdater.update(packageName: any(named: 'packageName')),
      ).called(1);
    });

    test('updates when newer version exists', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => latestVersion);
      when(() => logger.progress(any())).thenReturn(MockProgress());
      final result = await widgetbookCommandRunner.run(['upgrade']);
      expect(result, equals(ExitCode.success.code));
      verify(() => logger.progress('Checking for updates')).called(1);
      verify(() => logger.progress('Upgrading to $latestVersion')).called(1);
      verify(() => pubUpdater.update(packageName: packageName)).called(1);
    });

    test('does not update when already on latest version', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => currentVersion);
      when(() => logger.progress(any())).thenReturn(MockProgress());
      final result = await widgetbookCommandRunner.run(['upgrade']);
      expect(result, equals(ExitCode.success.code));
      verify(
        () => logger.info('widgetbook cli is already at the latest version.'),
      ).called(1);
      verifyNever(() => logger.progress('Upgrading to $latestVersion'));
      verifyNever(() => pubUpdater.update(packageName: packageName));
    });
  });
}