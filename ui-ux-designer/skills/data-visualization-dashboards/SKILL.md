---
name: data-visualization-dashboards
description: The ultimate architectural standard for High-Density Dashboard UX, Chart Selection Heuristics, Interactive Tooltip Micro-interactions, and Colorblind-Safe Accessible Palettes.
author: Diego Villanueva
trigger: When designing analytics dashboards, selecting chart types (Bar, Line, Donut, Heatmap, Scatter), formatting data visualization tooltips, or building high-density data views.
---

# Enterprise Data Visualization & Dashboard UX Architecture

Dashboards fail when they overwhelm users with visual clutter, unreadable multi-series graphs, or uncalibrated color palettes. An Enterprise UI/UX Architect designs **High-Density Data Dashboards** that guide user focus from high-level summary KPIs down to granular actionable insights.

---

## 1. Chart Selection Heuristics (Choosing the Right Visualization)

| Goal | Best Chart Type | Anti-Pattern to Avoid |
|---|---|---|
| **Trend over Time** | Continuous Line Chart / Area Chart | Pie Charts or scattered Bar charts |
| **Comparing Discrete Categories** | Horizontal Bar Chart | 3D Bar Charts or Radar Charts |
| **Part-to-Whole Composition (< 5 items)** | Donut Chart (with center metric) | Multi-slice Pie chart with 10+ wedges |
| **Two-Variable Correlation** | Scatter Plot | Double-Y Axis Line Chart (Confuses scale) |
| **Multi-Dimensional Matrix Density** | Heatmap Matrix | Overcrowded grouped bar chart |
| **Multi-Stage Funnel Conversion** | Funnel / Sankey Diagram | Standard stacked bar chart |

---

## 2. The 3-Tier Dashboard Information Hierarchy

```text
┌─────────────────────────────────────────────────────────┐
│ 1. SUMMARY KPI STRIP (Above the fold)                   │
│    Metric Value + Trend Indicator (+12.4% vs last month)│
│    [MRR: $124.5k]  [Churn: 1.2%]  [Active Users: 45.2k] │
└──────────────────────────┬──────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│ 2. PRIMARY TREND & EXPLORATION VIEW                     │
│    Interactive Line/Area Chart with Date Range Picker   │
│    (1D | 7D | 30D | 1Y | All) + Zoom/Pan Brushes        │
└──────────────────────────┬──────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│ 3. GRANULAR DATA TABLE (Breakdown & Export)             │
│    Paginated, Sortable, Filterable, with Inline Sparklines│
└─────────────────────────────────────────────────────────┘
```

---

## 3. High-Conversion Tooltip Micro-interactions

Tooltips must provide immediate context without obscuring neighboring data points.

### Tooltip UX Rules:
1. **Vertical Crosshair Guide**: Show a subtle vertical guideline connecting the cursor to the exact X-axis timestamp.
2. **Formatted Values**: Always format raw numbers (`1234567` $\rightarrow$ `$1,234,567.00` or `$1.23M`).
3. **Comparative Context**: Include previous period delta inline in the tooltip:
   ```text
   Oct 24, 2026
   Revenue: $45,210 (+18% vs Sep 24)
   ```

---

## 4. Colorblind-Safe & Accessible Palettes

**❌ NEVER** rely solely on Red vs Green to indicate status (8% of men have Deuteranopia/Protanopia red-green colorblindness).
**✅ ALWAYS** pair colors with **Icons / Symbols** ($\uparrow$, $\downarrow$, $\checkmark$, $\times$) and use scientifically calibrated colorblind-safe palettes (e.g. Viridis, Okabe-Ito, or accessible HSL steps).

```css
/* Accessible Chart Series Tokens */
:root {
  --chart-series-1: #2563eb; /* Primary Royal Blue */
  --chart-series-2: #0d9488; /* Vibrant Teal */
  --chart-series-3: #d97706; /* Warm Amber */
  --chart-series-4: #7c3aed; /* Deep Purple */
  --chart-series-5: #db2777; /* Rose Pink */

  /* Status Colors with High Contrast */
  --status-positive: #059669; /* Emerald Green */
  --status-negative: #dc2626; /* Crimson Red */
  --status-warning: #d97706;  /* Amber */
}
```

---

## 5. Responsive Chart Aspect Ratios

Never lock charts to fixed pixel heights that break on mobile screens:

```tsx
// Using Recharts ResponsiveContainer
<div className="h-[320px] w-full sm:h-[400px]">
  <ResponsiveContainer width="100%" height="100%">
    <AreaChart data={analyticsData}>
      {/* ... */}
    </AreaChart>
  </ResponsiveContainer>
</div>
```

---

**Execution Protocol**
1. **Never use more than 5 distinct colors in a single chart**: Excess series creates visual cognitive overload.
2. **Always start Bar chart Y-axes at zero ($0$)**: Truncating the Y-axis misrepresents proportional differences.
3. **Always display Sparklines in table rows**: Provides instant micro-trend context without leaving the table.
4. **Include empty state illustrations with clear CTAs**: Guide users when no data exists yet.
