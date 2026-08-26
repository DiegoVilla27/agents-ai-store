---
name: web-docker-containerization
description: The ultimate architectural standard for Production Multi-Stage Dockerfiles, Layer Caching, Non-Root Security, Distroless/Alpine Minimal Images, and Docker Compose for Web & Node.js apps.
author: Diego Villanueva
trigger: When writing Dockerfiles for Node.js/Next.js/Vite/Angular/Spring apps, optimizing Docker layer caching, creating multi-stage builds, or hardening container security.
---

# Enterprise Web & Node.js Docker Containerization Architecture

Bloated container images (1GB+) introduce security vulnerabilities and slow down CI/CD deployment pipelines. Enterprise containerization mandates **Multi-Stage Builds**, **Layer Caching Optimization**, **Non-Root Execution (`USER node`)**, and **Minimal Runtimes (Distroless / Alpine)** to produce lean images under 80MB.

---

## 1. Multi-Stage Production Dockerfile for Next.js / Node.js

```dockerfile
# syntax=docker/dockerfile:1

# ─────────────────────────────────────────────────────────────
# Stage 1: Base Dependencies
# ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS deps
WORKDIR /app
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat

COPY package.json package-lock.json ./
RUN npm ci

# ─────────────────────────────────────────────────────────────
# Stage 2: Builder
# ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
RUN npm run build

# ─────────────────────────────────────────────────────────────
# Stage 3: Runner (Minimal & Hardened Security)
# ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Create non-root system user and group for container security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy only standalone build artifacts and static assets
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Switch to unprivileged non-root user
USER nextjs

EXPOSE 3000

# Health check probe
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]
```

---

## 2. Multi-Stage Dockerfile for SPA (Vite / React / Angular) with Nginx Alpine

```dockerfile
# ─────────────────────────────────────────────────────────────
# Stage 1: Build Static Assets
# ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# ─────────────────────────────────────────────────────────────
# Stage 2: Serve with Hardened Nginx Alpine (< 25MB Image!)
# ─────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine-slim AS runner
WORKDIR /usr/share/nginx/html

# Clean default assets and copy production build
RUN rm -rf ./*
COPY --from=builder /app/dist ./
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Run as unprivileged nginx user
USER nginx

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

### Custom Hardened `nginx.conf`:

```nginx
server {
    listen 8080;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip Compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript;

    # Security Headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # SPA Routing Fallback
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Static Assets Long-term Caching (1 Year)
    location ~* \.(js|css|png|jpg|jpeg|gif|svg|ico|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

## 3. `.dockerignore` Essentials

```text
node_modules
.git
.gitignore
.env*.local
dist
.next
coverage
*.log
```

---

**Execution Protocol**
1. **Never run containers as root user**: Always create and switch to a dedicated non-root user (`USER nextjs` or `USER node`).
2. **Order instructions for layer caching**: Copy `package.json` and run `npm ci` before copying source code to avoid re-installing dependencies on every file change.
3. **Always include a `HEALTHCHECK`**: Allows container orchestrators (Kubernetes/Docker Swarm) to detect deadlocked processes.
