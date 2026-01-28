# TypeScript Conventions

## Strict Typing

- `strict: true` required in tsconfig
- Never use `any` — use `unknown` if the type is truly unknown
- Explicit types on function parameters and return values

## Syntax Choices

| Case                   | Use                  | Example                                                                |
| ---------------------- | -------------------- | ---------------------------------------------------------------------- |
| Objects/contracts      | `interface`          | `interface User { id: string }`                                        |
| Unions/intersections   | `type`               | `type Status = 'active' \| 'inactive'`                                 |
| Constants              | `as const`           | `const ROLES = ['admin', 'user'] as const`                             |
| State discrimination   | Discriminated unions | `type State = { status: 'loading' } \| { status: 'success'; data: T }` |

## Prefer Native Utility Types

- `Partial<T>`, `Required<T>` — optionality
- `Pick<T, K>`, `Omit<T, K>` — property selection
- `Record<K, V>` — typed dictionaries
- `ReturnType<T>`, `Parameters<T>` — function inference
- `Awaited<T>` — Promise unwrapping

## Type Guards

```typescript
function isUser(value: unknown): value is User {
  return typeof value === "object" && value !== null && "id" in value;
}
```

## Avoid

- `// @ts-ignore` and `// @ts-expect-error` without justification
- Overly broad types (`object`, `Function`)
- Type assertions (`as`) except in legitimate cases (e.g., DOM)
