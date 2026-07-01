### The Fix — Redis as Distributed Cache

Replace Caffeine with **Redis** (ElastiCache on AWS). All instances share one cache, eviction propagates everywhere instantly.

```
Instance A updates product-1 → evicts from Redis
Instance B reads product-1   → Redis miss → hits DB → repopulates Redis
Instance C reads product-1   → Redis hit ✅ (fresh data)
```

Let me replace the cache implementation now:

Viewed 3 files

Viewed 3 files

Now I'll update all 3 files — `pom.xml`, `CacheConfig.java`, and `application.yml` — to replace Caffeine with Redis, keeping Caffeine only as a local dev fallback:

Ran 3 commands, edited a file

Ran 3 commands, edited a file

Now update `ProductService` to also cache the product list endpoint with a shorter TTL:

Edited 5 files, viewed a file

Edited 5 files, viewed a file

Now package and deliver the zip:

Ran a command, read a file

Ran a command, read a file

Here's a clear summary of what changed and why.

----------

### What Was Wrong with Caffeine + Autoscaling

```
❌ CAFFEINE (broken with autoscaling)

ALB → Instance A  [Caffeine: product-1 = ₹999]
ALB → Instance B  [Caffeine: product-1 = ₹999]
ALB → Instance C  [Caffeine: EMPTY]

PUT /products/1 (price → ₹799) hits Instance A
→ @CacheEvict runs on Instance A ONLY
→ Instance B still serves ₹999 for up to 60 seconds ❌
→ Instance C goes to DB and gets ₹799 ✅ (lucky)
```

```
✅ REDIS (correct with autoscaling)

ALB → Instance A  ──┐
ALB → Instance B  ──┼──► Redis (ElastiCache) ◄──► RDS
ALB → Instance C  ──┘

PUT /products/1 hits Instance A
→ @CacheEvict deletes key from Redis
→ Next read on Instance B, C → Redis miss → DB → ₹799 ✅
→ ALL instances consistent immediately
```

----------

### What Changed in the Code

**`pom.xml`** — Added `spring-boot-starter-data-redis` + kept `caffeine` for local dev only.

**`CacheConfig.java`** — Split into two `@Profile` beans:

-   `@Profile("prod")` → `RedisCacheManager` with `products` (60s TTL) and `product-lists` (30s TTL)
-   `@Profile("local/default/test")` → `CaffeineCacheManager` — no Redis needed on your laptop

**`application-prod.yml`** _(new file)_ — Redis connection config via env vars (`REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`).

**`ProductService.java`** — Upgraded eviction:

-   `createProduct` now also evicts `product-lists`
-   `updateProduct` and `deleteProduct` use `@Caching` to evict both `products` (by id) and all `product-lists` entries

----------

### Running Locally (no change needed)

bash

```bash
mvn clean package -DskipTests
java -jar target/product-service-1.0.0.jar
# uses Caffeine automatically — no Redis needed
```

### Running on EC2 with Redis

bash

```bash
# Set env vars before starting
export REDIS_HOST=your-elasticache-endpoint.cache.amazonaws.com
export DB_URL=jdbc:mysql://your-rds-endpoint:3306/productdb
export DB_USERNAME=admin
export DB_PASSWORD=yourpassword

java -jar target/product-service-1.0.0.jar --spring.profiles.active=prod
```

