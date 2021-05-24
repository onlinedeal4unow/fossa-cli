# Hacking

## Quickstart

Use [ghcup][ghcup] to install the `cabal` cli tool and the ghc version we're using:

```sh
$ ghcup install ghc 8.10
<long running output, about 4 min on my machine>
$ ghcup set ghc 8.10
$ cabal update
$ cabal build
```

### Quickstart Explanation

Ok, the quickstart worked for you, but why, and how?

> `ghcup install ghc 8.10`

When you install `ghcup`, `ghc` and `cabal-install` are installed automatically as part of the initial installation (see [Tools](#Tools) for descriptions of `ghc` and `cabal-install`).
The `ghc` version that is automatically installed may not be the correct version we use (though it may work just fine).  So we install the correct version with `ghcup install ghc 8.10`.
Currently, the best place to check the correct version is our CI build files (try `.github/workflows/build.yml`).

> `ghcup set ghc 8.10`

`ghcup` works by setting symlinks to the "active" version of the tool you're using.  Here, we're telling `ghcup` to set GHC 8.10 as the active GHC version.
Now, when you run `ghc`, you'll be running GHC 8.10.

> `cabal update`

Cabal caches a local index of packages (and their metadata) to try to resolve dependencies for builds.
This cache often goes out of date since new package versions are released often.  `cabal update` will refresh this cache.

> `cabal build`

This builds the actual project, and is a perfect sanity check for checking that you have the correct tools installed.
You'll use this command a lot.

### Building

In the base directory, run `cabal build`

### Running tests

In the base directory, run `cabal test`

## Tools

| name | description |
| ---- | ----------- |
| [ghcup][ghcup] | Used to manage installed versions of ghc and cabal-install |
| ghc | The haskell compiler (installed via ghcup) |
| cabal-install | The package manager we use (installed via ghcup). Accessed via `cabal` on most setups. |
| [haskell-language-server][hls] | LSP server for haskell projects, a.k.a. HLS |
| [hlint][hlint] | A linting + hints tool for haskell code. It provides really useful suggestions.  `hlint` is bundled with HLS |
| [ormolu][ormolu] | A haskell source code formatter, `ormolu` is bundled with HLS |
| [fourmolu][fourmolu] | A forked version of ormolu that we are evaluating |

### Installing haskell-language-server

In VSCode: Install the "Haskell Language Server" (`haskell.haskell`) plugin in VSCode.

If you installed HLS in the old, complicated way, you can safely remove it.  HLS now bundles all of its needed tools.

## Linting

We do not recommend using `hlint` outside of the `haskell-language-server`, since by default it does not properly scan the project, and can even choke entirely.
See [haskell-anguage-server][hls] for configuration instructions.

`hlint` errors may become required changes in pull requests, but we do not currently run `hlint` in CI, as there are a few outstanding lint errors that have not yet been fixed.
You do not need to enforce that `hlint` passes to submit a PR, but it does help greatly, for both the author and reviewer.

## Formatting

Currently, we do not have a standardized formatting solution.  We have been using `ormolu`, but are now evaluating `fourmolu`, as it provides some configuration options that we want to take advantage of.

You can use HLS to format your code.  Since we are not yet standardized, formatting is not a blanket requirement.  However a code reviewer may ask you to format new files or files that have been mostly changed.
We do not recommend using formatters outside of HLS yet, as there are some issues with configuration (see [FAQ](#FAQ) for more info).

## Docs

| name | description |
| ---- | ----------- |
| [hoogle][hoogle] | Search for type signatures or symbols |
| [hackage][hackage] | Package repository; can be used to browse invdividual package docs ("haddocks") |

If on macOS, [dash](https://kapeli.com/dash) is a great tool that allows for downloading searchable package haddocks

On linux, you can use [zeal](https://zealdocs.org/).  (Currently there is an issue with building third-party docsets, if you discover a solution to get e.g.: `aeson` docs in `zeal`, please file an issue or submit a PR to fix these docs.)

## Cheatsheets

### Cabal cheatsheet

| command | description |
| ------- | ----------- |
| `cabal repl` | opens the ghci repl on the project |
| `cabal build` | build spectrometer |
| `cabal test` | build + run tests |
| `cabal run binary-name -- arg1 arg2` | build + run an executable named `binary-name`, and with args `arg1` `arg2` |

### GHCI cheatsheet

Use `cabal repl` to open ghci.

| command | description |
| ------- | ----------- |
| `:r`/`:reload` | reload the project |
| `:t`/`:type <symbol>` | query the type of a symbol |
| `:i`/`:info <symbol>` | query info about a symbol -- docs, where it was defined, etc |
| `:l`/`:load <Module.Name>` | load a specific file into the repl |

## FAQ/Troubleshooting

### Cabal is complaining about dependencies, and I don't understand it

Yeah, haskell tools can be a little over-explainy and use too many technicalities. Try these steps (one at a time):

* Run `cabal update`.  This solves most problems with dependencies and should be a go-to for these issues.
* Check your GHC version.  Some dependencies are baked-in (sort of) to the compiler, so make sure you're using the correct version.
* Update `ghcup`, then re-check all of your haskell tools' versions.  `ghcup tui` is a great interface for this, but you can use normal commands.

### I tried using ormolu/hlint, and it choked on some syntax that builds fine

We use a fair amount of GHC extensions, which can greatly change the syntax of a file.  When the extensions are listed at the top of a file
using `{#- LANGUAGE GADTs -#}`-style syntax, these tools can easily pick that up.  But some extensions, like `TypeApplications`, are so ubiquitous
that we define them everywhere using cabal's `default-extensions` feature.  If these also extensions modify syntax (like `TypeApplications` does), then
these tools can choke, and sometimes pretty poorly.

Using these tools through HLS should prevent these issues, since HLS checks for build-system-provided extensions.

### GHC/hlint is telling me to add/remove a language extension.  Is that safe?

Yes.  Missing language extensions are usually compile-time errors, and will be caught in CI.  Unused extensions are caught by hlint, and can be safely removed.
If, for any reason, GHC teel you add an extension, and hlint tells you to remove the extension you just added, keep it there and ignore hiint.  You should also file
an issue in this repository for that scenario, since we may be able to fix that.

[fourmolu]: https://github.com/fourmolu/fourmolu
[ghcup]: https://www.haskell.org/ghcup
[hackage]: https://hackage.haskell.org/
[hlint]: https://github.com/ndmitchell/hlint
[hls]: https://github.com/haskell/haskell-language-server
[hoogle]: https://hoogle.haskell.org/
[ormolu]: https://github.com/tweag/ormolu