# Infisical CLI Gotchas

- **`secrets delete` defaults to `--type personal`** — most env secrets in a shared project/env are `shared`, not `personal` overrides. Running `infisical secrets delete <key>` without `--type shared` targets the (usually non-existent) personal override and returns `404 Secret not found`, which looks like a wrong-project/path error but is actually a wrong-type error. Always pass `--type shared` when deleting a shared env secret:

  ```sh
  infisical secrets delete --type shared <KEY>
  ```

  Same caution applies to `secrets get` / `set` when you expect a shared value but only see personal (or vice versa).

- **Multi-round env renames cascade across already-provisioned secrets** — when an env var is renamed more than once across PRs (e.g. `PUBLIC_API_URL` → `API_PUBLIC_URL` → `BACKEND_API_URL`), each intermediate name may have been set in Infisical by an earlier provisioning pass. When reprovisioning, keep the name the **currently-deployed image** reads (so it keeps booting), add the name the **next image** will read, and delete any intermediate name no image has ever read (to avoid residue). Decide keep-vs-delete per name by mapping it to "which image version reads it", not by recency.

- **Verify before assuming a key is missing** — a `404`/empty result can mean wrong `--type` (see above), wrong `--env` / `--path`, or a genuine miss. Disambiguate by listing (`infisical secrets --env <e>`) before concluding the key is unset.
