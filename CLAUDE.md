# Cn::Util

A grab-bag of helpers the author uses in nearly every script -- `dir`,
`execute`, `file2string`, `format_commas`, `json_file_to_ref`,
`ref_to_json_file`, `random_key`, `random_value`, `structure` and `st` -- and,
through `import`, `autodie`, `p`/`np` and `Devel::Confess` for the caller. It
was `Util.pm` until 0.01, `Util::Con` for 0.01 and 0.02, `Util::Cn` for
0.021, and is now the CPAN distribution `Cn-Util`.

The global `~/.claude/CLAUDE.md` comment doctrine applies here in full. Perl
source is indented with tabs. `~/Scripts/stats/CLAUDE.md` and
`~/Scripts/MatPlotLib-Simple/CLAUDE.md` are the models this distribution
follows; where this file is silent, theirs apply.

## Back-compatible to perl 5.10.1

`dist.ini` declares `perl = 5.010001` and `lib/Cn/Util.pm` says
`require 5.010001`. 5.10.1 rather than 5.10.0 because `import` hands the
caller `autodie`, which is core from 5.10.1.

- `lib/` and `t/` are limited to 5.10 syntax: no signatures, no
  `:prototype(...)` attribute (write the prototype in the old position,
  `sub st (\[@$%&];%) {`), no postfix dereference, no `no source::encoding`,
  and `say` only under `use feature 'say'`. Tests open with
  `require 5.010001; use strict; use warnings FATAL => 'all';`.
- The author scripts in the root (`md2pod.pl`, `x.pl`, `list.pl`,
  `security.policy.pl`) are not shipped and may use modern perl.
- A minimum version in `dist.ini` is a fact about when a feature appeared,
  and the comment there says where it came from. `Term::ANSIColor = 3.00` is
  not decoration: 5.10.1 ships 2.00, which dies on the `bright_` colours
  `structure` uses.
- Raising the minimum perl is a maintainer decision, not a way to make a
  failure go away.

Run the suite on 5.10.1 as well as the default perl for any change to `lib/`:

    prove -Ilib t/
    ~/perl5/perlbrew/perls/perl-5.10.1/bin/prove -Ilib t/

`perl-5.12.5` (long double) has the prerequisites installed too. The other
perlbrew perls lack `Capture::Tiny` and `Parallel::ForkManager`, so the suite
cannot run there until they are installed.

### `autodie` is imported through a closure, not inside the eval

`import` compiles `sub { autodie->import(':default') }` in a string eval
carrying the caller's package and `#line`, and calls it after the eval has
returned. Calling `autodie->import` inside the eval works with 5.44's autodie
2.37 but not with 2.06 (5.10.1, 5.12.5), which un-installs itself as the eval
returns. `t/00-load.t` checks it in a separate script, because a `use` made
through `use_ok` is itself inside a string eval.

## Windows is a supported platform

The same rule as Matplotlib-Simple, for the same reason: CPAN Testers smokes
Strawberry Perl, and there is no Windows machine here.

- No hardcoded `/tmp` or other absolute path in `lib/` or `t/`; use
  `File::Temp`'s `tempdir` and `File::Spec`.
- A test builds no shell command line, except `t/execute.t`, whose function
  takes one. That file runs `$^X` with a double-quoted `-e` program that `sh`
  and `cmd.exe` read alike; its header says what that rules out. Anything
  else spawns with the list form of `system` and passes paths in `@ARGV`, as
  the autodie check in `t/00-load.t` does.
- `symlink` is unavailable or unprivileged on Windows, so a test that needs
  one skips when it cannot make one.
- No file, directory or package segment may be a Windows device name (`CON`,
  `PRN`, `AUX`, `NUL`, `COM0`-`COM9`, `LPT0`-`LPT9`, in any case, with or
  without an extension). The distribution was `Util-Con` for 0.01 and 0.02,
  and could not be built on Windows at all; `t/windows-names.t` checks it.

## `Util.pm` in the root is a shim, not the module

`~/perl5/perlbrew/perls/perl-5.44.0/lib/site_perl/5.44.0/x86_64-linux/Util.pm`
is a symlink to the root `Util.pm`, and about 55 scripts under `~/Scripts` say
`use Util`. The root `Util.pm` loads `lib/Cn/Util.pm` (resolving the symlink
with `abs_path`) and `goto`s its `import`, so those scripts keep working.
It is not shipped: `dist.ini`'s `[PruneFiles]` whitelist and `MANIFEST.SKIP`
both keep it out. Edit `lib/Cn/Util.pm`, never the shim, and do not delete
the shim while anything still says `use Util`.

`old.util.pm` is code retired from the module years ago, kept for reference
and not shipped.

## Layout

- `lib/Cn/Util.pm` -- the module, with its POD after the
  `# from md2pod.pl` line. That POD is generated from `README.md`.
- `t/00-load.t` -- exports, the `p`/`np` stubs (including into a package other
  than `main`, and leaving one the caller already has), and `autodie`.
- `t/<function>.t` -- one file per function or pair of functions.
- `t/windows-names.t` -- no path or package segment is a Windows device name.
- `md2pod.pl` -- README.md to POD, then `Test::Pod` and `CPAN::Changes` checks.
- `dzil.sh` -- the release script.
- `compile.sh` -- builds, tests and installs into the first perl on `PATH`,
  in the root. That is safe only because `dist.ini`'s `[MakeMaker::Awesome]`
  gives `Makefile.PL` a `MY::libscan` that drops root-level `*.pm` and `*.pl`
  (the shim among them) and `DIR => []`, which stops EUMM building a
  leftover `Cn-Util-$VERSION/`.
- `security.policy.pl` -- writes `SECURITY.md`; see its header.

## Documentation

Edit `README.md`, then run `perl md2pod.pl`; never edit the POD in the module.
Keep tables out of `README.md`: `md2pod.pl` turns a table into `=for html`,
which `perldoc` in a terminal does not show, so the argument lists are
bulleted instead.

## Releasing

`$VERSION` in `lib/Cn/Util.pm` is the source of truth (`[VersionFromModule]`).
Bump it there, add a `Changes` section under that version, then:

    sh dzil.sh    # md2pod.pl, dzil release, dzil build, copy Makefile.PL back

`Changes` is edited by hand and is the only copy of the notes. A version line
is `<version> <date> <tz>`, entries group under `[Bracketed headings]`, and an
entry says what was wrong and what the user will now observe -- the 0.01
section is the model. `md2pod.pl` runs `changes_file_ok`, so a malformed edit
fails there rather than at upload.

`[Git::GatherDir]` builds from the git index, so a new file has to be
`git add`ed before `dzil build` will include it.
