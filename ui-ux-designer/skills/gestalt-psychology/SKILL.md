---
name: gestalt-psychology
description: Applying human cognitive psychology to UI design for intuitive interfaces.
author: Diego Villanueva
trigger: When arranging complex forms, grouping information, or defining visual hierarchy.
---

# UI/UX Master Class: Gestalt Psychology

The best designers do not just know CSS; they understand how the human brain processes visual information.

## ✅ ALWAYS Apply Gestalt Principles

1.  **Law of Proximity**:
    -   Elements that are close together are perceived as related. 
    -   *Implementation*: The space between a title and its paragraph MUST be smaller than the space between that paragraph and the next section's title.

2.  **Law of Similarity**:
    -   Elements that look similar are perceived to have the same function.
    -   *Implementation*: If all primary actions are blue, a blue text link implies a primary action. Do not use blue for non-interactive text.

3.  **Law of Common Region**:
    -   Elements grouped within a boundary are perceived as a group.
    -   *Implementation*: Use subtle background colors (`bg-gray-50`) or soft borders to group related settings in a complex dashboard, reducing cognitive load.

4.  **Figure/Ground**:
    -   The brain separates objects (figure) from their background (ground).
    -   *Implementation*: Use overlays and drop shadows on Modals so the brain instantly recognizes that the modal is the active layer and the background is inactive.

## ❌ NEVER

-   **Violate Proximity**: Never place an input field equidistant between two different labels. The user's brain will not know which label belongs to which input without cognitive effort.
