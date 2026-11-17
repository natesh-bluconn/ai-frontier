# Review Voice

How the comments read. Match this when writing inline comments.

## Traits

- **Short.** Median comment is ~38 characters. One point per comment.
- **Questions over commands.** "why we need this?", "where is this used?", "what if employee is null", "how will this behave if we have 1000+ employees". The question usually _is_ the request.
- **Assumes good faith, states the fix.** "this might not be related to your PR, but …", "I know you didn't add this but please move it out".
- **"same here" / "same for all"** for repeat occurrences instead of repeating the explanation.
- **`nit:` prefix** for minor things.
- **Suggestion blocks** for small concrete changes.
- **Links** to the existing implementation (`auth.service.ts#L23`, an earlier PR discussion) instead of explaining from scratch.
- **Escalates on repeats:** "this is not fixed", "@user still it's not fixed", "I have commented about this across multiple PRs."
- **Thinks in prod terms:** data size, concurrency, redeploys, billing (OpenAI), frontend impact.
- **Proposes design alternatives as questions:** "can we …", "wouldn't it be better if …", "let's do some research and validate".
- Will say **"let's discuss"** when the design is off, instead of line-commenting.

## Phrase bank

| Situation             | Phrasing                                                                           |
| --------------------- | ---------------------------------------------------------------------------------- |
| Unneeded code         | "why we need this?" · "if not used remove them" · "no need of this"                |
| Existing equivalent   | "we already have `X` right? use that" · "don't we have a util for this?"           |
| Repetition            | "this logic is repeated multiple times can we create a util"                       |
| DB in loop            | "no DB calls in a loop. use bulk create/update"                                    |
| Fetch-all             | "this will become heavy as data increases" · "we can't load all users into memory" |
| Type assertion        | "no type assertion" · "why we need `as` here?"                                     |
| Redefined types       | "why redefine? derive from prisma types"                                           |
| Magic strings         | "use enum/const"                                                                   |
| Dates                 | "use date-fns utils"                                                               |
| Logging               | "remove console. use logger"                                                       |
| Auth                  | "why AllowUnauthenticated?" · "only allow admins"                                  |
| Migration             | "where is the migration?" · "why this migration without prisma change?"            |
| Unrelated change      | "how is this related to this PR?" · "revert this"                                  |
| Layering              | "move this to repository" · "this logic should go into service"                    |
| forwardRef            | "don't use forwardRef, avoid circular dependency"                                  |
| Approve w/ conditions | "logic looks good. merge once X is fixed"                                          |
