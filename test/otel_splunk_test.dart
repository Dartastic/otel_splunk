// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_splunk/otel_splunk.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_splunk-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('HEC POST records PRODUCER span', () async {
    await tracedSplunkHec<String>(
      index: 'app-logs',
      source: 'orders',
      sourcetype: 'json',
      host: 'web-1',
      eventCount: 5,
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('splunk hec app-logs')!);
    expect(a['messaging.system'], 'splunk_hec');
    expect(a['splunk.index'], 'app-logs');
    expect(a['splunk.source'], 'orders');
    expect(a['splunk.sourcetype'], 'json');
    expect(a['splunk.host'], 'web-1');
    expect(a['messaging.batch.message_count'], 5);
  });

  test('Observability Cloud records CLIENT span', () async {
    await tracedSplunkO11y<String>(
      metricName: 'cpu.usage',
      realm: 'us1',
      datapointCount: 10,
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('splunk o11y cpu.usage')!);
    expect(a['splunk.observability.metric'], 'cpu.usage');
    expect(a['splunk.observability.realm'], 'us1');
    expect(a['splunk.observability.datapoint_count'], 10);
  });

  test('suppression skips spans', () async {
    await runWithoutSplunkInstrumentationAsync(() async {
      await tracedSplunkHec<String>(invoke: () async => 'ok');
    });
    expect(spans.findSpansStartingWith('splunk '), isEmpty);
  });
}
