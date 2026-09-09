# 16_data_odbc_northwind — not portable to Linux/macOS (no source file here, on purpose)

This directory is deliberately a README and not a `.cpp`. `build_all.sh` discovers
examples by walking for `*.cpp`, so nothing here is built, and nothing here
pretends to run.

The Windows example is
[`examples/cpp/reporting/16_data_odbc_northwind.cpp`](../../../cpp/reporting/16_data_odbc_northwind.cpp)
(Delphi original: `examples/delphi/reporting/16_data_odbc_northwind.dpr`). Its
whole subject, in its own words, is:

> LumasReport example 16 — ODBC data provider over the real Northwind.mdb.
> Covers: the "odbc" data provider, a live DB connection + JOIN + ORDER BY …
> Uses the 64-bit "Microsoft Access Driver (\*.mdb, \*.accdb)".

Both halves of that sentence are Windows-only, so there is no honest POSIX
version of *this* example. Porting it by swapping the provider would not be a
port — it would be a different example that no longer demonstrates the thing it
exists to demonstrate. (Example 19, whose subject is the `.lrpt` walkthrough and
the embedded preview rather than ODBC, *is* ported here — see
`../19_northwind_preview.cpp` — and it documents its own data-source divergence
at the top of the file.)

## Exactly what is Windows-only

### 1. The engine's `odbc` report data provider has no POSIX implementation

`cpp/src/pdf/rpt_data_odbc.cpp` wraps its entire live binding in

```cpp
#if defined(_WIN32) && LUMAS_HAS_ODBC
```

The `#else` branch still *registers* the provider — so the name `odbc` keeps
resolving and you get a specific error instead of "unknown provider" — but its
`Open()` does only this:

```cpp
throw ERptDataError(RPT_E_DATA_CONN,
    "ODBC runtime is not available on this system "
    "(live ODBC binding is not yet implemented on non-Windows platforms)");
```

and `RptOdbcAvailable()` returns `false`.

The binding is Win32-specific *by construction*, not by oversight: it has zero
link-time dependency on any ODBC import library because it `LoadLibrary`s
`odbc32.dll` and resolves every entry point with `GetProcAddress`. The POSIX
equivalent would be `dlopen("libodbc.so.2")` against unixODBC (or iODBC), which
does not exist in the file yet.

**Note carefully that "the symbol links" proves nothing here.** `LUMAS_HAS_ODBC`
is *ON* for desktop POSIX (a macOS configure prints `ODBC=ON`), and the project
rule is that gating removes implementations, never symbols — every `rpt*` export
is present and callable on Linux and macOS. The feature-off replacement
(`cpp/src/pdf/feature_stub_odbc.cpp`, used on iOS/Android) even says so
explicitly: ODBC "is not an ABI surface at all", it is a provider registered by
name, so the 1630/1630 export gate is unaffected either way.

### Observed behaviour, not inferred

The Windows source above compiles **unmodified** for Linux (the only path it
needs is the `.mdb`, and it checks for that itself). Compiled against
`cpp/build/cmake_linux_x64/LumasPdf.so` with the `.mdb` reachable, it runs and
prints:

```
render failed
  ! rpt error 4002 [api] at rptRender: ODBC runtime is not available on this system (live ODBC binding is not yet implemented on non-Windows platforms)
```

exit code `0`, no PDF and no text export produced — only the `.lrpt` it writes
before touching the data. `4002` is `RPT_E_DATA_CONN`. That output is precisely
the "prints a not-supported message and exits 0" non-deliverable this README
exists instead of.

### 2. The data source is a Microsoft Access / JET database

`wrappers/vcl/Examples/Northwind.mdb` is a JET `.mdb`. Even with a working
unixODBC binding in the engine there is nothing to point it at: Microsoft ships
no Access/JET ODBC driver for Linux or macOS, and the SDK's Linux build container
has neither a driver manager nor MDBTools installed (`odbcinst`, `isql`,
`mdb-export` are all absent).

## What a POSIX user should do instead

Pick whichever matches your actual situation:

* **You want a *database* datasource and you are on POSIX.** You cannot, today,
  through this engine — the `odbc` provider is the only DB-backed provider it
  has. Use `csv`, `json`, `xml`, or `mem` and let your application do the query.
  Any DB client (`psql -c … --csv`, `mysql --batch`, `sqlite3 -csv`) writes a
  file the `csv` provider reads directly, and the report definition is otherwise
  identical — the `<datasource>` element is the only line that changes.
  `reporting/06_data_csv.cpp` and `reporting/07_data_json_xml.cpp` show those
  providers; `reporting/08_custom_provider.cpp` shows feeding rows in
  programmatically, which is the right shape if you already have a live
  connection in your own code.
* **You specifically want *this* report, the Northwind product catalog, on
  POSIX.** Run `../19_northwind_preview.cpp`. It renders the same
  `Categories INNER JOIN Products` result set — the same 77 rows in the same
  order, exported from that very `Northwind.mdb` — through the `csv` provider,
  with a richer layout, and previews it in the embedded viewer.
* **You need the `.mdb` itself read on POSIX.** Convert it once on a Windows box
  (or with MDBTools' `mdb-export`, which is a converter, not an ODBC driver) and
  ship the result as CSV/JSON/SQLite.

## What would have to exist in the engine for this example to work

Both of these, not either:

1. **A POSIX ODBC binding in `cpp/src/pdf/rpt_data_odbc.cpp`.** The file is
   already structured for it: the deterministic kernel
   (`ParseQueryParams`, `RptOdbcSqlTypeToKind`, `RptOdbcPrepareBind`, the
   `RptOdbcConvert*` family, `RptOdbcOpErrorCode`) is platform-neutral, is built
   on every platform today, and is byte-gated against the Delphi oracle by
   `cpp/tools/rptodbc_diff.cpp` + `cpp/tools/check_rptodbc.py`. What is missing is
   only the loader and handle plumbing: replace the `LoadLibrary`/`GetProcAddress`
   of `odbc32.dll` with `dlopen`/`dlsym` of `libodbc.so.2` (unixODBC) or
   `libiodbc.so.2`, and widen the `#if defined(_WIN32) && LUMAS_HAS_ODBC` guard
   accordingly. One real wrinkle: the cursor binds and fetches through the `W`
   entry points (`SQLDriverConnectW`, `SQLDescribeColW`, `SQL_C_WCHAR`) using
   `wchar_t`, which is 2 bytes on Windows and 4 on POSIX — unixODBC's
   `SQLWCHAR` is 2 bytes, so those buffers need `char16_t`, not `wchar_t`
   (the same `wchar_t`-ABI issue already tracked for this port generally).
2. **A driver for the data.** With (1) done you would have a driver *manager*,
   not a driver. Reading `Northwind.mdb` needs an Access/JET driver, which does
   not exist for POSIX; the realistic path is to migrate the data to something a
   POSIX ODBC driver *does* speak (PostgreSQL, MySQL, SQLite) and change the
   `conn=` string. That makes the example's SQL and grouping demonstrable on
   POSIX, but it is a change to the example's premise, and it is blocked behind
   (1) regardless.

Until (1) lands, "ODBC on POSIX" is an engine gap, not an example gap, which is
why it is written down here instead of worked around in code.
