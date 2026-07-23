POST: http://localhost:8082/api/v1/products
Request:
```
{
    "name": "Test product",
    "description": "Created during load test",
    "price": "100",
    "sku": "100",
    "category": "Electronics",
    "stockQuantity": 100
}
```
Response:
```
{
    "success": true,
    "message": "Product created successfully",
    "data": {
        "id": 11,
        "name": "Test product",
        "description": "Created during load test",
        "price": 100,
        "sku": "100",
        "category": "Electronics",
        "stockQuantity": 100,
        "createdAt": "2026-07-23T11:06:06.301575411",
        "updatedAt": "2026-07-23T11:06:06.301602814"
    },
    "timestamp": "2026-07-23T11:06:06.371637176"
}
```
GET:http://localhost:8082/api/v1/products/2
Response:
```
{
    "success": true,
    "message": "Product fetched",
    "data": {
        "id": 2,
        "name": "Wireless Mouse",
        "description": "Ergonomic wireless mouse",
        "price": 29.99,
        "sku": "WM-002",
        "category": "Electronics",
        "stockQuantity": 200,
        "createdAt": "2026-07-23T05:39:47.449386",
        "updatedAt": "2026-07-23T05:39:47.449419"
    },
    "timestamp": "2026-07-23T11:11:05.168415882"
}
```
GET: http://localhost:8082/api/v1/products/sku/SD-007
```
{
    "success": true,
    "message": "Product fetched",
    "data": {
        "id": 7,
        "name": "Standing Desk",
        "description": "Height-adjustable desk",
        "price": 599.99,
        "sku": "SD-007",
        "category": "Furniture",
        "stockQuantity": 20,
        "createdAt": "2026-07-23T05:39:47.478463",
        "updatedAt": "2026-07-23T05:39:47.478499"
    },
    "timestamp": "2026-07-23T11:12:36.982842907"
}
```
GET:http://localhost:8082/api/v1/products?category=Electronics&minPrice=&maxPrice=&search=&page=0&size=20&sortBy=name&sortDir=asc
```
{
    "success": true,
    "message": "Products listed",
    "data": {
        "content": [
            {
                "id": 1,
                "name": "Laptop Pro 15",
                "description": "High-performance laptop",
                "price": 1299.99,
                "sku": "LP-001",
                "category": "Electronics",
                "stockQuantity": 50,
                "createdAt": "2026-07-23T05:39:47.247972",
                "updatedAt": "2026-07-23T05:39:47.248024"
            },
            {
                "id": 3,
                "name": "Mechanical Keyboard",
                "description": "RGB mechanical keyboard",
                "price": 89.99,
                "sku": "MK-003",
                "category": "Electronics",
                "stockQuantity": 150,
                "createdAt": "2026-07-23T05:39:47.452183",
                "updatedAt": "2026-07-23T05:39:47.452208"
            },
            ...
        ],
        "page": 0,
        "size": 20,
        "totalElements": 6,
        "totalPages": 1,
        "last": true
    },
    "timestamp": "2026-07-23T11:13:30.686664917"
}
```
