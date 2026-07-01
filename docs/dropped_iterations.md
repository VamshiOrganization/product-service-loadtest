**`dropped_iterations: 731`** — NOT Tomcat or H2. This means k6 itself couldn't _schedule_ those iterations because it hit `maxVUs: 500` limit. The VU pool was exhausted before the request even left k6. So the server never saw those 731 requests at all.

**20-25% error rate at 300 QPS** — Your guess is partially right. The chain is:

```
300 QPS arrives → Resilience4j rate limiter (150/s cap) → 
rejects ~150/s → those become 429s → 20% error rate
NOT Tomcat thread exhaustion (p99=196ms proves threads are fine)
NOT H2 (requests aren't reaching DB — rate limiter fires first)
```

```
** Understadning p50 , p95,  p99 **
Think of it like **1,000 people waiting in line at a coffee shop**:
Think of it like **waiting in line at a coffee shop**:
1000 People Waiting for Coffee
500 people (50%) get coffee in ≤ 3ms
more 450 people (95%) get coffee in ≤ 38ms
more  4 people (99%) get coffee in ≤ 197ms
moew 1  person (1%) waits > 197ms (the "slow" user)

1-500:    ≤ 3ms      ████████████████████████████████████  50%
501-950:  3-38ms     ████████████████████████████████████  45%
951-990:  38-197ms   ████                                   4%
991-1000: 197-500ms  █                                      1%

             ⬆️                 ⬆️                 ⬆️
            p50               p95               p99
            (3ms)             (38ms)            (197ms)
```
The `p(99)=196ms` is the giveaway — if Tomcat threads or H2 were exhausted you'd see p99 > 2000ms. Your bottleneck is purely the rate limiter config.

Now let me add comprehensive logging so you can see exactly what's happening inside the app:


Now I'll add a `RequestLoggingFilter` (traces every request/response), update `ProductService` with cache hit/miss logs, update `GlobalExceptionHandler` with rate-limit counters, and add a `LoadMetricsLogger` that prints a live summary every 10 seconds during load:


Now update `application.yml` with proper log levels so you see everything during load testing:

Here's the full breakdown of your observations and what you'll now see in logs.

----------

### Your 3 Questions — Answered Precisely

#### 1. `dropped_iterations: 731` — where did they go?

These **never reached your server**. k6 couldn't create enough virtual users to fire the request. The chain is:

```
k6 wants to send 300 req/s
→ needs 300 VUs each doing 1 req/s
→ but your k6 script has maxVUs: 500 (should be enough...)
→ BUT each VU was taking longer than 1s (iteration_duration avg=119ms, p95=856ms)
→ VUs pile up waiting for previous iteration to finish
→ k6 runs out of free VUs → drops 731 iterations
→ Server never sees them — these are NOT Tomcat or H2 failures
```

The fix if you want to actually send 300 req/s is increasing `maxVUs` in k6, or using `open model` (ramping-arrival-rate). But on localhost it doesn't matter much.

#### 2. 429 at 61 seconds — correct, and expected

At 61s the ramp hits 150 QPS threshold exactly. Your rate limiter config says `limit-for-period: 150` so the 151st request in that second gets a 429. This is working as designed.

#### 3. 20-25% error rate at 300 QPS — NOT Tomcat or H2

Your `p(99)=196ms` completely disproves the Tomcat/H2 theory. If either of those were the bottleneck:

```
Tomcat thread exhaustion  → p99 would be 5000ms+ (requests queuing)
H2 pool exhaustion        → p99 would be 3000ms+ (DB timeout)
Rate limiter (actual)     → p99 stays low ✅ because 429 returns in <1ms
```

At 300 QPS with a 150/s limit, exactly 150 requests/s get 429 instantly. `150/300 = 50%` rejected — but your traffic mix is 80% GETs (which are cached after first hit), so you see ~20-25% overall.

----------

### What You'll Now See in Logs During k6 Run

**Every 10 seconds — `LoadMetricsLogger`:**

```
┌─ LOAD METRICS ─────────────────────────────────────────
│  Heap:        187 MB used / 700 MB max  (26%)
│  Threads:     active=34  peakSinceLast=47  daemon=18
│  GC (G1Young): collections=8  totalPause=45ms  avgPause=5ms
│  RateLimiter: available_permits=0  ← LIMITER ACTIVE — 429s being sent
│  Throughput:  requests_last_10s=1490  (~149 req/s)  ← NEAR LIMIT
└────────────────────────────────────────────────────────
```

**Cache miss (first request for each product — only once due to caching):**

```
INFO  [CACHE MISS] products id=1  →  hitting DB
DEBUG [DB] SELECT product id=1  db_time=3ms
```

**After first request — cache hits produce NO log lines at INFO level**, proving cache is working.

**Rate limit events:**

```
WARN  [429] #1 Rate limit exceeded — request rejected by resilience4j productApi
WARN  [429] #100 Rate limit milestone — 100 requests shed so far this session.
WARN  [429] #200 Rate limit milestone — 200 requests shed so far this session.
```

**Slow responses (>500ms, only during real GC pressure):**

```
WARN  [RES] GET /api/v1/products/1  status=200  duration=612ms  ← SLOW (>500ms threshold)
```

**Every 500 requests — summary line:**

```
INFO  ━━━ REQUEST SUMMARY ━━━  total=500  succeeded=378  rate-limited(429)=122  server-errors(5xx)=0
```
