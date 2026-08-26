---
name: ab-testing-experimentation
description: The ultimate architectural standard for A/B Testing, Multi-Variant Testing (MVT), Statistical Significance (p-value & sample size), MECLABS Conversion Heuristics, and ICE Prioritization.
author: Diego Villanueva
trigger: When designing A/B split tests, evaluating statistical significance, calculating sample size, prioritizing growth experiments with ICE/PIE, or auditing landing page conversion rates.
---

# Enterprise A/B Testing & Scientific Experimentation Architecture

Guesswork kills conversion rates. A Principal Growth Architect formulates mathematically sound hypotheses, ensures statistical rigor, and uses proven conversion heuristics to run experiments that compound revenue growth.

---

## 1. The MECLABS Conversion Heuristic

$$C = 4m + 3v + 2(i - f) - 2a$$

| Variable | Weight | Description | Strategy to Optimize |
|---|---|---|---|
| **$C$** | - | **Probability of Conversion** | The target outcome. |
| **$m$** | $\times 4$ | **Motivation of the User** | Tap into existing desire, match search intent, and timing. |
| **$v$** | $\times 3$ | **Clarity of Value Proposition** | *"Why should I buy from you rather than any competitor?"* |
| **$i$** | $\times 2$ | **Incentive to Act Now** | Discounts, bonuses, limited spots, free shipping. |
| **$f$** | $- 2$ | **Friction in the Process** | Form fields, slow loading, confusing navigation, bugs. |
| **$a$** | $- 2$ | **Anxiety of the Buyer** | Security badges, testimonials, clear refund policies. |

---

## 2. Formulating Scientific Hypotheses

**❌ NEVER** write vague test ideas like *"Let's test a red button to see if it's better."*
**✅ ALWAYS** follow the 3-part structured hypothesis format:

$$\text{Because we observed } [Data/Feedback], \text{ we believe that changing } [Variable] \text{ will result in } [Specific Metric Lift] \text{ because } [Psychological/Behavioral Rationale].$$

### Example:
> *"Because 68% of mobile visitors drop off at the credit card step on our pricing page, we believe that introducing Apple Pay / Google Pay one-tap checkout will increase mobile checkout completion by 18% because it eliminates manual 16-digit card typing friction."*

---

## 3. Statistical Rigor (Sample Size & Significance)

Running an A/B test for 2 days, seeing 12 conversions on Variant B vs 8 on Variant A, and declaring a winner is the **False Positive Trap**.

### Golden Rules of Statistical Rigor:
1. **Statistical Significance**: Require **$\ge 95\%$ Confidence Level** ($p\text{-value} < 0.05$).
2. **Minimum Sample Size**: Calculate required sample size *before* starting the test based on baseline conversion rate and Minimum Detectable Effect (MDE).
3. **Full Business Cycles**: Always run tests for at least **2 full business cycles (14 days)** to account for day-of-week seasonality (e.g. weekend vs weekday purchasing behavior).
4. **Sample Ratio Mismatch (SRM)**: If traffic allocation is set to 50/50, but actual split is 46/54, the test is invalid due to an SRM tracking bug.

---

## 4. Prioritization Frameworks: ICE & PIE

When managing a backlog of 30+ experiment ideas, prioritize objectively using the **ICE Score**:

$$\text{ICE Score} = \frac{\text{Impact} (1-10) + \text{Confidence} (1-10) + \text{Ease of Implementation} (1-10)}{3}$$

| Factor | Score Range | Evaluation Question |
|---|---|---|
| **Impact** | 1 - 10 | If successful, how dramatically will this move bottom-line revenue? |
| **Confidence** | 1 - 10 | How much quantitative data / user feedback supports this hypothesis? |
| **Ease** | 1 - 10 | How quickly can engineering/design deploy this test (< 2 days = 10, > 2 weeks = 2)? |

---

## 5. What to Test (High-Leverage vs Low-Leverage Elements)

| Low Leverage (Waste of Time) | High Leverage (10x Impact) |
|---|---|
| Button background color (Blue vs Green) | The Primary Value Proposition (H1 Headline) |
| Minor footer link re-ordering | Pricing Model (Freemium vs Reverse Trial vs Annual Discount) |
| Stock photography swap | Removing Credit Card requirement on Signup |
| Font family change | Radical Redesign of Hero Section & Offer Stacking |

---

**Execution Protocol**
1. **Never stop a test early based on premature significance**: Wait for required sample size and 14 days minimum.
2. **Focus on Primary Metric Lift without degrading Secondary Metrics**: E.g. If Variant B increases signups by 20% but drops 30-day retention by 40%, it is a net-negative test.
3. **Document all learnings in an Experiment Repository**: A failed test that teaches deep user behavior insight is as valuable as a winning test.
4. **Test one variable at a time (A/B)**: Unless traffic volume exceeds 500k+ visits/month to support Multi-Variant Testing (MVT).
