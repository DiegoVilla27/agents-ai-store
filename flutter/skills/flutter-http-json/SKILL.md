---
description: 'Standardized API Communication and JSON Parsing'
author: 'Diego Villanueva'
trigger: 'When implementing HTTP clients, API endpoints, or JSON serialization.'
---

# Flutter HTTP & JSON

Professional API integration using `Dio` and type-safe JSON serialization.

## ✅ ALWAYS
- Use `Dio` for advanced HTTP features (Interceptors, Retries, Global Config).
- Use `json_serializable` and `freezed` for type-safe data models.
- Implement global `Interceptors` for Auth tokens and logging.
- Wrap all network calls in a `try-catch` with specialized `ApiException` handling.
- Use `compute()` for parsing very large JSON payloads to avoid UI jank.

## ❌ NEVER
- Use the basic `http` package for enterprise-grade applications.
- Hardcode API endpoints; use a centralized `Environment` configuration.
- Perform manual JSON mapping (`json['key']`) in the UI layer.

## 🛠 Patterns
- **DTO Mappers**: Mapping raw API models to clean Domain Entities.
- **Client Factory**: Centralized configuration of the Dio instance.
