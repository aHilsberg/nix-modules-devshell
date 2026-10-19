---
role:
    - maintainers
topic:
    - nix-conventions
type: convention
last-substantial-update: "2026-10-18"
---

# Nix conventions in `nix-modules-devshell`

`nix-modules-devshell` follows the generic convention below for the project library and package set.

```text
nix-modules-devshell/
├── flake.nix                  # Wires projectLib, overlays, imports, and exports
├── lib.nix                    # Builds projectLib, including mkPkgs
├── pkgs.nix                   # Supplies the provider's perSystem.pkgs
├── modules/
│   ├── *.lib.nix              # Feature constructors and library exports
└── tests/
    └── test.lib.nix           # Shared test library fragment
```

## Generic convention

### Project library (`lib.nix`)

Every project with its own nix functionality library provides a `lib.nix` at the repository root.

In this project, `lib.nix` is a **pure library builder**, imported before `flake-parts.lib.mkFlake`, not a flake-parts module. It:

- discovers and imports `*.lib.nix` fragments in `modules/` and `devshell-submodules/`, plus the existing `tests/test.lib.nix` once;
- recursively merges their exports, allowing shared attribute-set branches but rejecting duplicate leaves;
- uses `lib.fix` so fragments can refer to the completed `projectLib`;
- returns the library attribute set without declaring module options or setting `_module.args` itself.

`flake.nix` makes the result available as `projectLib` to the provider's own flake-parts modules. It also passes the library explicitly to the consumer-facing root module through `importApply`; feature discovery does not depend on a module argument obtained from configuration.

Ordinary provider modules can use the library argument:

```nix
{projectLib, ...}: {
  # projectLib.<namespace>.<function>
}
```

Feature constructors instead capture `projectLib` in their context stage. See the [Developer Guide](Developer_Guide.md#module-pattern) for the complete fragment pattern.

### Package set (`pkgs.nix`)

`pkgs` denotes the complete package set that a project is allowed to reference. It does not necessarily consist only of unmodified `nixpkgs`; through overlays, it can:

- provide additional packages;
- override existing packages;
- selectively hide packages or attributes;
- apply shared package configuration across the project.

The provider standardizes creation of this package set through `projectLib.mkPkgs`, defined by the library builder. It uses the provider's overlays registered in `flake.overlays` when importing `nixpkgs` for a system. The separate `pkgs.nix` module selects the resulting set as the provider's ordinary `perSystem.pkgs` argument; the pure library builder does not configure module arguments itself.

Provider modules should use this supplied `pkgs` instead of importing `nixpkgs` themselves with a different overlay or package configuration. Consumer projects control their own `pkgs`; applying the exported devshell module does not replace it with the provider's package set.

---

Overlays are commonly registered through `flake.overlays`. Example:

```nix
flake.overlays.devshell = inputs.devshell.overlays.default;
```

This makes additional packages and customizations part of the centrally created project package set.

## Project-specific conventions

### Library attribute sets

`projectLib` is available to this project's flake-parts modules as a top-level module argument. It contains the internal project library, including `projectLib.mkPkgs`.

#### Adding library functions

Export internal functions from a discovered library fragment, or add a shared primitive to the builder's base exports. They become available as `projectLib.<name>` without becoming part of the exported flake module's public option interface. Avoid duplicate export leaves, which are rejected rather than overwritten.

Feature fragments export constructors under `projectLib.modules.flake.<name>` or `projectLib.modules.devshell.<name>`. Both registries are applied automatically; do not maintain a parallel module list. Keys use camelCase, including `fileGeneration`, `gitHooks`, and `globalStartup`, independently of hyphenated file names and existing option names. A fragment may export to both registries, as `modules/formatting.lib.nix` does.

Every constructor accepts context before returning an ordinary module, even when context is unused. Flake constructors receive `{localInputs, projectLib, withSystem}`. Shell constructors additionally receive the consumer's `self`, `perSysCfg`, and `perSysOptions`, and the provider's `customPkgs`. Ordinary `config`, `lib`, `name`, `options`, and `pkgs` remain module arguments; shared shell `pkgs` and `system` come through `submoduleWith.specialArgs`.

### Package set

The provider's complete package set follows the shared Nix conventions, including the overlays registered in its `flake.overlays`.

Inside `perSystem` or a shell module, use the ordinary `pkgs` argument for that evaluation scope. Do not import `inputs.nixpkgs` separately. Use the provider's `projectLib.mkPkgs` helper when its package set is needed outside `perSystem`.

For consumer shell features, distinguish these three package sources:

- `pkgs`: the consumer's ordinary package set, supplied to shell modules through `specialArgs`;
- `perSysCfg.packages`: the consumer's per-system package outputs, used for consumer-specific artifacts such as `generate-nix-managed-files`;
- `customPkgs`: the provider's per-system package outputs, obtained through the provider-bound `withSystem system ({config, ...}: config.packages)` and populated by `packages/` and package-producing `modules/` features.

The constructor refactor does not change the existing `customPkgs.run-git-hooks` provenance: its package is still from the provider, while the shell's hook enablement and installation script use the consumer's `perSysCfg`. `perSysCfg` and `perSysOptions` supply cross-scope settings and schema, not an option-injection mechanism.
