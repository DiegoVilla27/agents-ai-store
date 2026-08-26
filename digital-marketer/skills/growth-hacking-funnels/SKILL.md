---
name: growth-hacking-funnels
description: The ultimate architectural standard for Growth Hacking, AARRR Pirate Funnels (Acquisition, Activation, Retention, Referral, Revenue), Product-Led Growth (PLG), and Viral Loops.
author: Diego Villanueva
trigger: When designing growth funnels, mapping user journeys, optimizing onboarding conversion, establishing viral referral loops, or implementing Product-Led Growth (PLG).
---

# Enterprise Growth Hacking & Funnels Architecture (AARRR & PLG)

Growth hacking is not about random marketing tactics; it is a systematic, scientific discipline focused on removing friction across the entire user lifecycle. A Principal Growth Architect architects and optimizes the full **AARRR (Pirate Metrics) Funnel** and implements **Product-Led Growth (PLG)** flywheels.

---

## 1. The AARRR Growth Funnel Architecture

```text
┌──────────────────────────────────────────────────────────┐
│ 1. ACQUISITION (Top of Funnel - TOFU)                    │
│    Channels: SEO, Paid Ads, Social, Content, Outbound    │
└────────────────────────────┬─────────────────────────────┘
                             ▼
┌──────────────────────────────────────────────────────────┐
│ 2. ACTIVATION (The "Aha! Moment")                        │
│    Time-to-Value (TTV), Frictionless Signup, Onboarding  │
└────────────────────────────┬─────────────────────────────┘
                             ▼
┌──────────────────────────────────────────────────────────┐
│ 3. RETENTION (The Engine of Growth)                      │
│    Habit Loops, Push/Email Triggers, Product Sticky Power│
└────────────────────────────┬─────────────────────────────┘
                             ▼
┌──────────────────────────────────────────────────────────┐
│ 4. REVENUE (Monetization & Expansion)                    │
│    Pricing Tiers, Upgrades, Expansion MRR, LTV Boost     │
└────────────────────────────┬─────────────────────────────┘
                             ▼
┌──────────────────────────────────────────────────────────┐
│ 5. REFERRAL (Viral Loops & Word-of-Mouth)                │
│    Incentivized Sharing, Two-Sided Invites, K-Factor > 1 │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Activation & Minimizing Time-to-Value (TTV)

The #1 reason SaaS and app funnels leak is **Activation Failure**. If users don't reach their "Aha! Moment" within the first 3 minutes, 70%+ will bounce forever.

### The Activation Blueprint:
1. **Zero-Friction Signup**: Avoid asking for credit cards, phone numbers, or corporate details upfront. Let users taste value first (**Reverse Trial** or **Freemium**).
2. **Interactive Empty States**: Never leave a user with a blank dashboard. Pre-populate templates or sample data immediately.
3. **Checklist Onboarding**: Gamify progress (e.g. "3 of 4 steps completed — 75%").

```typescript
// Onboarding Progress Signal Pattern (Product Metric Definition)
export interface ActivationMilestones {
  hasCreatedFirstProject: boolean;
  hasInvitedTeammate: boolean;
  hasExportedResult: boolean;
}

export function isUserActivated(milestones: ActivationMilestones): boolean {
  // Definition of Activation: Core value delivered in < 5 mins
  return milestones.hasCreatedFirstProject && milestones.hasExportedResult;
}
```

---

## 3. Product-Led Growth (PLG) & Viral Loops (K-Factor)

In PLG, the product itself drives acquisition, retention, and expansion.

### The Viral Loop Formula (K-Factor):
$$\text{K-Factor} = i \times c$$
- $i$ = Number of invites/shares sent per customer.
- $c$ = Conversion rate of each invite/share.

If $\text{K-Factor} > 1$, the product experiences exponential viral growth.

### Viral Loop Mechanisms:
- **Two-Sided Incentives**: "Give \$20, Get \$20" (Dropbox/Airbnb model).
- **Watermark Virality**: "Powered by [Your Brand]" on free tier exports (Calendly, Loom, Typeform).
- **Collaborative Multiplication**: Features that only work when shared (e.g. document co-editing, shared whiteboards).

---

## 4. Growth Metric KPIs & Formulas

| Metric | Formula | Target Benchmark |
|---|---|---|
| **CAC (Cost of Customer Acquisition)** | $\frac{\text{Total Sales \& Marketing Spend}}{\text{New Customers Acquired}}$ | Payback period < 12 months |
| **LTV (Customer Lifetime Value)** | $\text{ARPU} \times \frac{1}{\text{Churn Rate}} \times \text{Gross Margin}$ | $\text{LTV} : \text{CAC} \ge 3:1$ |
| **Quick Ratio** | $\frac{\text{New MRR} + \text{Expansion MRR}}{\text{Churned MRR} + \text{Contraction MRR}}$ | $> 4.0$ (High Velocity Growth) |
| **Net Revenue Retention (NRR)** | $\frac{\text{Starting MRR} + \text{Expansion} - \text{Churn}}{\text{Starting MRR}} \times 100$ | $> 110\%$ (Enterprise SaaS) |

---

**Execution Protocol**
1. **Never scale acquisition before fixing retention**: Pouring ad spend into a leaky funnel burns capital.
2. **Identify the exact "Aha! Moment"**: Measure the exact action that correlates with 90-day retention (e.g. Slack: 2,000 messages sent; Facebook: 7 friends in 10 days).
3. **Enforce 3:1 LTV-to-CAC Ratio**: Maintain healthy unit economics across all paid channels.
4. **Implement self-serve expansion tiers**: Allow users to seamlessly upgrade storage/seats without requiring sales team friction.
