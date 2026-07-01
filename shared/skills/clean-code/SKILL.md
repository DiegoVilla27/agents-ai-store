---
name: clean-code
description: A comprehensive guide and strict standard for writing professional, readable, maintainable, and evolvable code.
author: Diego Villanueva
trigger: When writing or refactoring any code to ensure it meets enterprise-grade quality standards.
---

# Clean Code Mastery

You are the guardian of technical excellence. Your primary objective is to produce code that is not just functional, but readable, maintainable, and resilient. Remember: code is read far more often than it is written.

## 1. Universal Design Principles

- **SOLID Principles**: Strongly adhere to Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion.
- **DRY (Don't Repeat Yourself)**: Eliminate duplication. Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.
- **KISS (Keep It Simple, Stupid)**: Simplicity is the ultimate sophistication. Avoid over-engineering.
- **YAGNI (You Aren't Gonna Need It)**: Do not add functionality until deemed necessary.
- **Boy Scout Rule**: Always leave the code a little better than you found it.

## 2. Meaningful Naming

Names must reveal intent. They should tell you why it exists, what it does, and how it is used.

- **Use Intention-Revealing Names**: `let elapsedTimeInDays: number` instead of `let d: number`.
- **Avoid Disinformation**: Do not refer to a grouping of accounts as an `accountList` unless it's actually a List. Use `accountGroup` or `accounts`.
- **Make Meaningful Distinctions**: Avoid noise words like `ProductData` or `ProductInfo`. If names must be different, they should mean something different.
- **Use Pronounceable Names**: Programming is a social activity. `genymdhms` is unacceptable; use `generationTimestamp`.
- **Searchable Names**: Single-letter names and numeric constants have a particular problem in that they are not easy to locate across a body of text.
- **Class Names**: Classes and objects should have noun or noun phrase names like `Customer`, `WikiPage`, `Account`, and `AddressParser`. Avoid words like `Manager`, `Processor`, `Data`, or `Info` in the name of a class.
- **Method Names**: Methods should have verb or verb phrase names like `postPayment`, `deletePage`, or `save`.

## 3. Functions (The Building Blocks)

Functions should be small, and then they should be smaller than that.

- **Do One Thing**: Functions should do one thing. They should do it well. They should do it only.
- **One Level of Abstraction per Function**: Ensure that the statements within our function are all at the same level of abstraction.
- **Reading Code from Top to Bottom (The Stepdown Rule)**: We want code to read like a top-down narrative. Every function should be followed by those at the next level of abstraction.
- **Switch Statements**: Bury `switch` statements in a low-level factory and never repeat them. Use polymorphism instead.
- **Function Arguments**: The ideal number of arguments for a function is zero (niladic). Next comes one (monadic), followed closely by two (dyadic). Three arguments (triadic) should be avoided where possible. More than three (polyadic) requires very special justification—and then shouldn't be used anyway.
- **No Side Effects**: Your function promises to do one thing, but it also does other hidden things. This is a lie and leads to temporal couplings.
- **Command Query Separation**: Functions should either do something or answer something, but not both.

## 4. Comments (The Necessary Evil)

Don't comment bad code—rewrite it.

- **Explain Yourself in Code**: The only truly good comment is the comment you found a way not to write.
- **Good Comments**: Legal comments, informative comments (matching regex patterns), explanation of intent, clarification of obscure code you cannot alter, warning of consequences, TODO comments.
- **Bad Comments**: Mumbling, redundant comments, misleading comments, mandated comments (e.g., Javadoc on every method), journal comments, noise comments, scary noise, commented-out code.
- **Commented-Out Code**: Delete it immediately. Version control systems remember it for you.

## 5. Formatting & Structure

Code formatting is about communication, and communication is the professional developer's first order of business.

- **Vertical Formatting**: Concepts that are closely related should be kept vertically close to each other.
- **Vertical Distance**: 
  - Variables should be declared as close to their usage as possible.
  - Instance variables should be declared at the top of the class.
  - Dependent functions should be vertically close (caller above callee).
- **Horizontal Formatting**: Keep lines short. Strive for less than 120 characters.
- **Indentation**: Rely strictly on standard indentation tools (Prettier, ESLint).

## 6. Error Handling

Error handling is important, but if it obscures logic, it's wrong.

- **Use Exceptions Rather Than Return Codes**: The caller code is cleaner when you throw an exception instead of returning a status code.
- **Write Your Try-Catch-Finally Statement First**: This helps you define what the user of that code should expect, no matter what goes wrong with the code that is executed in the `try`.
- **Provide Context with Exceptions**: Create informative error messages and pass them along with your exceptions. Mention the operation that failed and the type of failure.
- **Don't Return Null**: Returning `null` forces the caller to check for it. If you are tempted to return a `null`, consider throwing an exception or returning a Special Case object.
- **Don't Pass Null**: Passing `null` into methods is worse than returning it. Unless an API expects it, strictly forbid passing `null`.

## 7. Objects and Data Structures

- **Data Abstraction**: Hiding implementation is not just a matter of putting a layer of functions between the variables. It is about abstractions.
- **Data/Object Anti-Symmetry**: Objects hide their data behind abstractions and expose functions that operate on that data. Data structure expose their data and have no meaningful functions.
- **The Law of Demeter**: A module should not know about the innards of the objects it manipulates. Objects shouldn't chain method calls (`a.getB().getC().doSomething()`).

## 8. Classes

- **Single Responsibility Principle (SRP)**: A class or module should have one, and only one, reason to change.
- **Cohesion**: Classes should have a small number of instance variables. Each of the methods of a class should manipulate one or more of those variables. The more variables a method manipulates, the more cohesive that method is to its class.
- **Organizing for Change**: In an ideal system, we incorporate new features by extending the system, not by making modifications to existing code (Open/Closed Principle).

## 9. Tests & TDD

Test code is just as important as production code. It must be kept clean.

- **The Three Laws of TDD**:
  1. You may not write production code until you have written a failing unit test.
  2. You may not write more of a unit test than is sufficient to fail, and not compiling is failing.
  3. You may not write more production code than is sufficient to pass the currently failing test.
- **F.I.R.S.T. Rules**:
  - **Fast**: Tests should run quickly.
  - **Independent**: Tests should not depend on each other.
  - **Repeatable**: Tests should be repeatable in any environment.
  - **Self-Validating**: Tests should have a boolean output (pass/fail).
  - **Timely**: Tests need to be written just before the production code that makes them pass.
- **One Assert Per Test**: Strive for a single concept to be tested per test function.

## 10. Boundaries & Third-Party Code

- **Clean Boundaries**: Keep third-party interfaces strictly isolated. Wrap them in your own interfaces so you aren't tied to their specific implementation.
- **Learning Tests**: Don't experiment with a new API in production code. Write "learning tests" to verify your understanding of the third-party API.

---

**Execution Protocol**
1. **Static Analysis**: Automatically reject commits failing lint/format checks.
2. **Code Reviews**: Be rigorous but constructive. Do not let bad code enter the repository.
3. **Refactoring Phase**: Always factor in time for cleanup before declaring a feature complete.
