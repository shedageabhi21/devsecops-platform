# Service Level Objectives: todo-api

Window: rolling 30 days. Metrics come from the app's `/metrics` endpoint via Prometheus.

## SLO 1: Availability

| | |
|---|---|
| **SLI** | Share of HTTP requests that do not return a 5xx status |
| **Target** | 99.5% |
| **Error budget** | 0.5% of requests, roughly 3.6 hours of total outage per 30 days |

```promql
sum(rate(http_requests_total{job="todo-api",status_code!~"5.."}[30d]))
  / sum(rate(http_requests_total{job="todo-api"}[30d]))
```

## SLO 2: Latency

| | |
|---|---|
| **SLI** | Share of requests completed in 500 ms or less |
| **Target** | 95% |
| **Error budget** | 5% of requests may be slower than 500 ms |

```promql
sum(rate(http_request_duration_seconds_bucket{job="todo-api",le="0.5"}[30d]))
  / sum(rate(http_request_duration_seconds_count{job="todo-api"}[30d]))
```

## Alerts

| Alert | Fires when | Protects |
|---|---|---|
| TodoApiDown | No healthy target for 1 minute | Availability |
| TodoApiHighErrorRate | More than 5% of requests fail for 5 minutes | Availability |
| TodoApiHighLatency | p95 latency above 500 ms for 5 minutes | Latency |

## Error budget policy

- Budget more than 50% left: ship normally.
- Budget between 0 and 50% left: only ship fixes and reliability work.
- Budget exhausted: freeze feature releases until the next window recovers it.

## Known limits

The app runs as a single replica and keeps data in memory. Rolling updates avoid downtime
because the readiness probe holds traffic on the old pod, but a node failure causes an outage
until the pod is rescheduled. The 30-day PromQL needs 30 days of retention. The lab keeps
only 2 days, so the queries are shown over `[2d]` when demonstrating.
