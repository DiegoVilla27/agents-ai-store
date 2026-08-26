---
name: nestjs-search-elasticsearch
description: The ultimate architectural standard for Enterprise Full-Text Search and Indexing in NestJS with Elasticsearch / OpenSearch, Document Syncing, and Aggregations.
author: Diego Villanueva
trigger: When integrating Elasticsearch or OpenSearch in NestJS, indexing database entities, building fuzzy full-text search, or running complex analytical aggregations.
---

# Enterprise NestJS Elasticsearch & Search Architecture

Relational databases with `LIKE '%term%'` choke under load and cannot provide fuzzy typo-tolerance, relevance scoring, or instant faceting. **Elasticsearch / OpenSearch** integration in NestJS provides sub-10ms search across millions of documents.

---

## 1. Elasticsearch Module Setup (`@nestjs/elasticsearch`)

```bash
npm install @nestjs/elasticsearch @elastic/elasticsearch
```

```typescript
// src/common/search/search.module.ts
import { Module, Global } from '@nestjs/common';
import { ElasticsearchModule } from '@nestjs/elasticsearch';

@Global()
@Module({
  imports: [
    ElasticsearchModule.registerAsync({
      useFactory: () => ({
        node: process.env.ELASTICSEARCH_NODE || 'http://localhost:9200',
        auth: {
          username: process.env.ELASTIC_USER || 'elastic',
          password: process.env.ELASTIC_PASSWORD || 'changeme',
        },
      }),
    }),
  ],
  exports: [ElasticsearchModule],
})
export class SearchModule {}
```

---

## 2. Document Indexing & Search Service

```typescript
// src/modules/products/services/product-search.service.ts
import { Injectable } from '@nestjs/common';
import { ElasticsearchService } from '@nestjs/elasticsearch';

export interface ProductSearchDocument {
  id: string;
  name: string;
  description: string;
  category: string;
  price: number;
  tags: string[];
}

@Injectable()
export class ProductSearchService {
  private readonly indexName = 'products_v1';

  constructor(private readonly esService: ElasticsearchService) {}

  // 1. Index or Update Document
  async indexProduct(product: ProductSearchDocument): Promise<void> {
    await this.esService.index({
      index: this.indexName,
      id: product.id,
      document: product,
    });
  }

  // 2. Multi-Match Fuzzy Search with Aggregations (Faceting)
  async search(queryText: string, category?: string) {
    const response = await this.esService.search<ProductSearchDocument>({
      index: this.indexName,
      query: {
        bool: {
          must: [
            {
              multi_match: {
                query: queryText,
                fields: ['name^3', 'tags^2', 'description'], // Boost title relevance 3x
                fuzziness: 'AUTO', // Typo tolerance (e.g. "iphne" -> "iphone")
              },
            },
          ],
          filter: category ? [{ term: { 'category.keyword': category } }] : [],
        },
      },
      aggs: {
        categories: {
          terms: { field: 'category.keyword' },
        },
      },
    });

    const hits = response.hits.hits.map((hit) => hit._source!);
    const categoryFacets = (response.aggregations?.categories as any)?.buckets || [];

    return {
      total: response.hits.total,
      results: hits,
      facets: { categories: categoryFacets },
    };
  }

  // 3. Remove from index upon DB deletion
  async remove(productId: string): Promise<void> {
    await this.esService.delete({
      index: this.indexName,
      id: productId,
    });
  }
}
```

---

## 3. Database Event Syncing (Outbox / CDC Pattern)

Never couple synchronous HTTP request threads to Elasticsearch writes. Listen to Domain Events asynchronously:

```typescript
// src/modules/products/listeners/product-events.listener.ts
import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { ProductSearchService } from '../services/product-search.service';

@Injectable()
export class ProductEventsListener {
  constructor(private readonly searchService: ProductSearchService) {}

  @OnEvent('product.created')
  @OnEvent('product.updated')
  async handleProductChange(product: any) {
    await this.searchService.indexProduct({
      id: product.id,
      name: product.name,
      description: product.description,
      category: product.category,
      price: product.price,
      tags: product.tags || [],
    });
  }

  @OnEvent('product.deleted')
  async handleProductDeleted(event: { id: string }) {
    await this.searchService.remove(event.id);
  }
}
```

---

**Execution Protocol**
1. **Never use wildcard SQL `LIKE '%term%'` for production search**: Use Elasticsearch fuzzy scoring.
2. **Apply Index Aliases (`products_active` $\rightarrow$ `products_v1`)**: Enables zero-downtime index reindexing migrations.
3. **Use field boosting (`name^3`)**: Ensures title matches rank higher than body text occurrences.
