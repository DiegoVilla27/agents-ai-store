---
name: meta-google-ads-scaling
description: The ultimate architectural standard for Scaling Paid Media on Meta Ads (Advantage+, CBO, Creative Testing) and Google Ads (PMax, Search Intent Clusters, tROAS Bidding).
author: Diego Villanueva
trigger: When building paid advertising campaigns, scaling Meta/Facebook Ads budgets, configuring Google Performance Max (PMax), combating ad fatigue, or optimizing ROAS.
---

# Enterprise Paid Ads Scaling Architecture (Meta & Google Ads)

Scaling paid advertising from \$1k/month to \$100k+/month is not about tweaking micro-targeting buttons. It requires structured **Campaign Budget Optimization (CBO)**, algorithmic asset feeds (**Advantage+ & Performance Max**), creative iteration pipelines, and strict ROAS profitability thresholds.

---

## 1. Meta Ads (Facebook/Instagram) Scaling Architecture

Modern Meta Ads algorithms rely on **Broad Targeting** paired with **Creative-as-Targeting**. The ad creative is what qualifies and segments the audience.

### The 3-Tier Campaign Structure:

```text
┌─────────────────────────────────────────────────────────┐
│ 1. Dynamic Creative Testing (DCT) Sandbox (ABO - 20%)   │
│    Test 3 Hooks × 2 Primary Texts × 2 Creatives (3:2:2) │
└──────────────────────────┬──────────────────────────────┘
                           │ (Winners Graduate)
┌──────────────────────────▼──────────────────────────────┐
│ 2. Advantage+ / CBO Scaling Campaign (CBO - 70%)        │
│    Broad Audience (18-65+, No Interests), Winning PostIDs│
└──────────────────────────┬──────────────────────────────┘
                           │ (Warm Re-engagement)
┌──────────────────────────▼──────────────────────────────┐
│ 3. Retargeting & Win-Back Safety Net (10%)              │
│    Website Visitors (30d), Cart Abandoners (7d), LTV Up │
└─────────────────────────────────────────────────────────┘
```

### The 3:2:2 Dynamic Creative Testing (DCT) Formula:
- **3 Hooks**: 3 different 3-second opening video angles or image styles.
- **2 Copy Variations**: 1 short punchy direct-response copy + 1 long-form storytelling copy.
- **2 Call-to-Actions (CTAs)**: e.g. "Shop Now" vs "Learn More".

---

## 2. Google Ads Scaling Architecture

### A. High-Intent Google Search Clusters
Structure Search campaigns around **Search Intent**, not isolated single keywords.

1. **Brand Protection**: Exact match brand name variations (High Quality Score, lowers competitor poaching).
2. **High-Intent Commercial**: `best [solution] software`, `buy [product] online`, `[solution] pricing`.
3. **Competitor Alternative**: `[competitor] alternative`, `[competitor] vs [brand]`.

**Rule**: Always maintain a shared **Negative Keyword List** (e.g. `free`, `torrent`, `crack`, `jobs`, `salary`, `login`) to eliminate wasted ad spend.

### B. Google Performance Max (PMax) Architecture
Performance Max spans Search, YouTube, Display, Discover, Gmail, and Maps.

- **Asset Groups by Theme**: Divide asset groups strictly by product category or persona.
- **Audience Signals**: Feed PMax with first-party data (Customer Email Lists, High LTV Purchasers, Search Intent Custom Segments).
- **Final URL Expansion**: Disable URL expansion if landing on specific promotional landing pages to avoid bounce rate spikes.

---

## 3. Combating Creative Fatigue

When ad frequency exceeds 3.0+ and CPA starts rising, creative fatigue has hit.

### The Iteration Matrix:
1. **Change the First 3 Seconds (Hook)**: Swap the video intro, text overlay hook, or opening visual while keeping the rest of the body intact.
2. **Change the Format**: Convert a high-performing video into an editorial static carousel, user testimonial quote graphic, or comparison chart.
3. **Change the Angle**: Switch from a "Fear of Missing Out / Risk" angle to an "Aspiration / Status" angle.

---

## 4. Bidding Strategies & Unit Economics

| Stage | Bidding Strategy | Requirement |
|---|---|---|
| **Early Stage (< 50 conversions/mo)** | Maximize Conversions (Target CPA) | Establishes pixel learning baseline. |
| **Growth Stage (50-200 conversions/mo)** | Target CPA (tCPA) / Target ROAS (tROAS) | Algorithmic optimization with stable margins. |
| **Scale Stage (> 200 conversions/mo)** | Value-Based Bidding (Highest Value) | Maximizes revenue from high-spending whales. |

---

**Execution Protocol**
1. **Never scale budgets by > 20% in 24 hours on active ad sets**: Triggers algorithm reset back to the learning phase.
2. **Always retain Social Proof (PostID)**: Duplicate winning ads using their existing `PostID` into scaling campaigns so likes and comments accumulate.
3. **Ensure Server-Side Conversions API (CAPI) is active**: iOS 14.5+ tracking requires Meta CAPI and Google Enhanced Conversions to recover lost attribution data.
4. **Kill underperforming ads ruthlessly**: If an ad spend exceeds $1.5\times \text{Target CPA}$ with zero conversions, pause it immediately.
