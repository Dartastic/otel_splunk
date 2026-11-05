// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_splunk_suppression.dart';

const _tracerName = 'dartastic_otel_libs_splunk';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps a Splunk HEC (HTTP Event Collector) POST in a PRODUCER
/// span, recording the index, source, sourcetype, and host so
/// dashboards can correlate emitted events with traces.
Future<T> tracedSplunkHec<T>({
  required Future<T> Function() invoke,
  String? index,
  String? source,
  String? sourcetype,
  String? host,
  int? eventCount,
  int? payloadSize,
}) async {
  if (splunkInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'messaging.system': 'splunk_hec',
    'messaging.operation': 'publish',
    'messaging.destination.name': index ?? 'main',
  };
  if (index != null) m['splunk.index'] = index;
  if (source != null) m['splunk.source'] = source;
  if (sourcetype != null) m['splunk.sourcetype'] = sourcetype;
  if (host != null) m['splunk.host'] = host;
  if (eventCount != null) m['messaging.batch.message_count'] = eventCount;
  if (payloadSize != null) m['messaging.message.body.size'] = payloadSize;

  final span = _tracer().startSpan(
    'splunk hec ${index ?? 'main'}',
    kind: SpanKind.producer,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps a Splunk Observability Cloud (Signalfx) datapoint POST in
/// a CLIENT span.
Future<T> tracedSplunkO11y<T>({
  required String metricName,
  required Future<T> Function() invoke,
  String? realm,
  int? datapointCount,
}) async {
  if (splunkInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'splunk.observability.metric': metricName,
  };
  if (realm != null) m['splunk.observability.realm'] = realm;
  if (datapointCount != null) {
    m['splunk.observability.datapoint_count'] = datapointCount;
  }

  final span = _tracer().startSpan(
    'splunk o11y $metricName',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
