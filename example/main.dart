// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_splunk/otel_splunk.dart';

/// Traces Splunk calls with OpenTelemetry.
///
/// `otel_splunk` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Splunk call in
/// [tracedSplunkHec]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'splunk-example');

  // Traces a Splunk call.
  final splunkHecId = await tracedSplunkHec<String>(
    index: 'products',
    source: 'example',
    sourcetype: 'standard',
    host: 'api.example.com',
    eventCount: 3,
    payloadSize: 512,
    invoke: () async {
      // Make the Splunk call here, then report what it returned.
      return 'splunk_8f3a2c';
    },
  );
  OTelLog.info('tracedSplunkHec returned $splunkHecId');

  // Wraps a Splunk Observability Cloud (Signalfx) datapoint POST in a CLIENT span.
  final splunkO11yId = await tracedSplunkO11y<String>(
    metricName: 'example',
    realm: 'example',
    datapointCount: 3,
    invoke: () async {
      // Make the Splunk call here, then report what it returned.
      return 'splunk_8f3a2c';
    },
  );
  OTelLog.info('tracedSplunkO11y returned $splunkO11yId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutSplunkInstrumentationAsync.
  await runWithoutSplunkInstrumentationAsync(
    () => tracedSplunkHec<String>(
      index: 'products',
      source: 'example',
      sourcetype: 'standard',
      host: 'api.example.com',
      eventCount: 3,
      payloadSize: 512,
      invoke: () async {
        return 'splunk_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
