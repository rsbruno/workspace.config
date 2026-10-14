# Fix, test, register and report

## 3. Fix

- Fix in place, following each skill. Do not change business rules that the requirement docs define. Divergences and missing rules go to the developer.
- **Schema change:**
  - Write a hand-written migration `drizzle/migrations/<next>_<slug>.sql` and add its entry to `meta/_journal.json`. Do not trust `db:generate` when snapshots are out of sync.
  - Convert existing data explicitly in the migration (for example `USING round(col * 1000)::bigint`).
  - Write the rollback statement in the implementation note.
  - Apply the migration to the dev database (`APP_ENV=dev pnpm db:migrate`) and confirm the column with `information_schema`.
- **Seeds/policies:** if an endpoint gained or lost a permission, update `policy.enum.ts`, `drizzle/seeds/policies/data.json` and the feature links in the same change.

## 4. Test

After the module suite is green, remove the module's entries from every `known*` list and run `pnpm test:architecture` (`backend-test` 9). The refactor is not done while a `known*` entry of the module remains.

Follow `backend-test` completely: inventory, the three layers, the feature + permission matrix, organization isolation, translations, the OpenAPI contract, mutation checks, coverage config and the `test:<module>:cov` script. Running the module suite is part of this task.

## 5. Register and report

- Update `docs/implementation/<module>.md` with a dated section covering: what changed, the organization-scope exceptions, migrations + rollback, tests and the frontend impact. Update the requirement if it diverged (rules in `AGENTS.md`).
- Final report, in this order:
  - findings fixed;
  - findings pending a decision;
  - global/unscoped exceptions;
  - frontend impact;
  - test results with the mutation checks;
  - what was not verified (`tsc`, lint, the global suite, other environments).
