/**
 * Simple metrics collector for Prometheus-compatible metrics
 */
export class MetricsCollector {
  private requestCount = 0;
  private errorCount = 0;
  private totalLatency = 0;
  private requestCounts: Record<string, number> = {};
  private startTime = Date.now();

  recordRequest(
    method: string,
    path: string,
    statusCode: number,
    duration: number
  ) {
    this.requestCount++;
    this.totalLatency += duration;

    const key = `${method} ${path}`;
    this.requestCounts[key] = (this.requestCounts[key] || 0) + 1;

    if (statusCode >= 400) {
      this.errorCount++;
    }
  }

  getMetrics() {
    const uptimeSeconds = Math.floor((Date.now() - this.startTime) / 1000);

    return {
      uptime: uptimeSeconds,
      memory: process.memoryUsage(),
      totalRequests: this.requestCount,
      totalErrors: this.errorCount,
      avgLatency:
        this.requestCount > 0 ? this.totalLatency / this.requestCount : 0,
      requestsByEndpoint: this.requestCounts,
    };
  }

  toPrometheusFormat() {
    const metrics = this.getMetrics();
    const lines: string[] = [];

    // Total requests
    lines.push('# HELP singr_requests_total Total number of requests');
    lines.push('# TYPE singr_requests_total counter');
    lines.push(`singr_requests_total ${metrics.totalRequests}`);

    // Total errors
    lines.push('# HELP singr_errors_total Total number of errors');
    lines.push('# TYPE singr_errors_total counter');
    lines.push(`singr_errors_total ${metrics.totalErrors}`);

    // Average latency
    lines.push('# HELP singr_latency_avg Average request latency in ms');
    lines.push('# TYPE singr_latency_avg gauge');
    lines.push(`singr_latency_avg ${metrics.avgLatency.toFixed(2)}`);

    // Uptime
    lines.push('# HELP singr_uptime_seconds Uptime in seconds');
    lines.push('# TYPE singr_uptime_seconds counter');
    lines.push(`singr_uptime_seconds ${metrics.uptime}`);

    // Memory usage
    lines.push('# HELP singr_memory_usage_bytes Memory usage in bytes');
    lines.push('# TYPE singr_memory_usage_bytes gauge');
    lines.push(`singr_memory_usage_bytes{type="rss"} ${metrics.memory.rss}`);
    lines.push(
      `singr_memory_usage_bytes{type="heapTotal"} ${metrics.memory.heapTotal}`
    );
    lines.push(
      `singr_memory_usage_bytes{type="heapUsed"} ${metrics.memory.heapUsed}`
    );
    lines.push(
      `singr_memory_usage_bytes{type="external"} ${metrics.memory.external}`
    );

    return lines.join('\n');
  }

  reset() {
    this.requestCount = 0;
    this.errorCount = 0;
    this.totalLatency = 0;
    this.requestCounts = {};
    this.startTime = Date.now();
  }
}

// Global metrics collector instance
export const metricsCollector = new MetricsCollector();
