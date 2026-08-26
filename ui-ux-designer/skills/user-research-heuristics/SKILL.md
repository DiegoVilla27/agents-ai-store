---
name: user-research-heuristics
description: The ultimate architectural standard for UX Heuristic Evaluation (Nielsen Norman Group 10 Heuristics), Cognitive Walkthroughs, User Journey Maps, and UX Audit Scorecards.
author: Diego Villanueva
trigger: When conducting UX audits, evaluating usability with Nielsen Norman 10 heuristics, building user journey maps, or designing user research interview protocols.
---

# Enterprise User Research & Usability Heuristics Architecture

A beautiful UI that frustrates users is a failed product. An Enterprise UX Architect evaluates interfaces using the **Nielsen Norman Group (NN/g) 10 Usability Heuristics**, structured **Cognitive Walkthroughs**, and **User Journey Maps**.

---

## 1. The 10 Nielsen Norman Usability Heuristics

```text
┌─────────────────────────────────────────────────────────┐
│ 1. VISIBILITY OF SYSTEM STATUS                          │
│    Always keep users informed (progress bars, spinners) │
├─────────────────────────────────────────────────────────┤
│ 2. MATCH BETWEEN SYSTEM & REAL WORLD                   │
│    Speak the user's language, use natural metaphors     │
├─────────────────────────────────────────────────────────┤
│ 3. USER CONTROL & FREEDOM                               │
│    Clear "Emergency Exits" (Undo, Cancel, Back, Redo)   │
├─────────────────────────────────────────────────────────┤
│ 4. CONSISTENCY & STANDARDS                              │
│    Follow platform conventions (don't reinvent a button)│
├─────────────────────────────────────────────────────────┤
│ 5. ERROR PREVENTION                                     │
│    Prevent slips before they occur (confirmation dialogs│
│    for destructive actions, smart input formatting)     │
├─────────────────────────────────────────────────────────┤
│ 6. RECOGNITION RATHER THAN RECALL                       │
│    Minimize cognitive memory load (show recent searches)│
├─────────────────────────────────────────────────────────┤
│ 7. FLEXIBILITY & EFFICIENCY OF USE                      │
│    Accelerators for power users (Keyboard shortcuts ⌘K) │
├─────────────────────────────────────────────────────────┤
│ 8. AESTHETIC & MINIMALIST DESIGN                        │
│    Eliminate irrelevant clutter and visual noise        │
├─────────────────────────────────────────────────────────┤
│ 9. HELP USERS RECOGNIZE & RECOVER FROM ERRORS           │
│    Plain language error messages + constructive fix     │
├─────────────────────────────────────────────────────────┤
│ 10. HELP & DOCUMENTATION                                │
│     Contextual tooltips, onboarding guides, search docs │
└─────────────────────────────────────────────────────────┘
```

---

## 2. UX Audit Severity Scoring Framework

When auditing a product interface, score each usability violation on a scale from 0 to 4:

| Severity Level | Definition | Engineering Action |
|---|---|---|
| **0 - No Problem** | Does not violate any heuristic | No action required |
| **1 - Cosmetic** | Superficial visual polish issue | Fix if extra time allows |
| **2 - Minor** | Minor annoyance, user can easily recover | Low priority fix |
| **3 - Major** | Important friction, users struggle to complete task | High priority fix before next release |
| **4 - Catastrophic** | Blocks user from completing core purchase or workflow | Immediate hotfix required |

---

## 3. The 5-Phase User Journey Mapping Architecture

```text
1. AWARENESS ────► 2. CONSIDERATION ────► 3. ACQUISITION ────► 4. SERVICE/USE ────► 5. LOYALTY/EXPANSION
 (Searches for      (Compares Pricing      (Signs up, sets      (Completes daily     (Refers teammates,
  solution)          & Case Studies)        up workspace)        core workflows)      upgrades tier)

User Actions:       Reads feature grid    Fills 3 form fields   Exports report       Invites 5 colleagues
Pain Points:        Confusing tiers       Email verify delay    Slow query time      Missing team admin
Opportunities:      Add ROI calculator    One-click Google Auth Add instant preview  Add Enterprise SSO
```

---

## 4. User Interview Protocol (The "Mom Test" Principles)

When gathering qualitative user feedback:
1. **Talk about their life and past behavior, not your idea**: Ask *"How do you currently solve this problem?"* instead of *"Would you buy this feature?"*
2. **Look for emotional friction & workarounds**: When a user sighs or explains a complex spreadsheet workaround, you have found a massive product opportunity.
3. **Listen 80%, talk 20%**: Let the user explore the prototype without defending your design choices.

---

**Execution Protocol**
1. **Always provide Undo over Confirmation when possible**: An "Undo" toast feels faster and less annoying than a modal asking *"Are you sure?"* for non-destructive actions.
2. **Implement Command Palettes (`⌘K` / `Ctrl+K`) for power user efficiency**: Allows instant navigation across complex enterprise SaaS tools.
3. **Write human error messages**: Replace *"Error 500: Database lock timeout"* with *"We couldn't save your changes. We've preserved your draft and are retrying now."*
