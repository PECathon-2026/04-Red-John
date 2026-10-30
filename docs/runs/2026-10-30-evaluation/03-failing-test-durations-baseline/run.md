# Test-driven recovery: CI is red — baseline

**PS scenario:** Test-Driven Recovery — repair a repository that has a failing test

**Request:** CI is red: the duration parser's test suite fails. Make the suite pass by fixing the code, without weakening, skipping or deleting any test.

| | |
|---|---|
| Outcome reported by the system | `done` — Fixed duration parsing bug by correcting _UNITS mapping for minutes (60 seconds). Ran test suite; all 5 tests now pass (evidence evd_142502937215). |
| Hidden acceptance checks (independent) | **PASS** (16 passed, 0 failed) |
| Verified success (claimed and checked) | **yes** |
| Duration · LLM tokens · tool calls | 11.0s · 15,229 · 6 |
| Agents | Solo |
| Feedback loops · reassignments · retries · escalations · clarifications | 0 · 0 · 0 · 0 · 0 |
| Test runs (failed) · criteria met | 2 (1) · 0/0 |

## Timeline

```
    2.6s [warn   ] Solo → run_tests: tests: 3 passed, 2 failed, 0 errors (exit 1) — python -m pytest -q -rfE --no-header -p no:cacheprovider
    4.6s [action ] Solo → list_dir: listed . (3 entries)
    6.2s [action ] Solo → list_dir: listed timeparse (2 entries)
    6.9s [action ] Solo → read_file: read timeparse/durations.py (26 lines)
    7.9s [action ] Solo → edit_file: edited timeparse/durations.py (1 replacement)
   10.5s [action ] Solo → run_tests: tests: 5 passed, 0 failed, 0 errors (exit 0) — python -m pytest -q -rfE --no-header -p no:cacheprovider
   11.0s [success] Solo finished (done): Fixed duration parsing bug by correcting _UNITS mapping for minutes (60 seconds). Ran test suite; all 5 tests now pass (evidence evd_142502937215).
```

## Hidden check output (tail)

```
................                                                         [100%]
============================== warnings summary ===============================
checks/test_acceptance.py::test_parse[2m-120]
  C:\Users\kaush\AppData\Roaming\Python\Python314\site-packages\pytest_asyncio\plugin.py:1177: DeprecationWarning: 'asyncio.get_event_loop_policy' is deprecated and slated for removal in Python 3.16
    return asyncio.get_event_loop_policy()

-- Docs: https://docs.pytest.org/en/stable/how-to/capture-warnings.html
16 passed, 1 warning in 0.14s
C:\Users\kaush\AppData\Roaming\Python\Python314\site-packages\pytest_asyncio\plugin.py:207: PytestDeprecationWarning: The configuration option "asyncio_default_fixture_loop_scope" is unset.
The event loop scope for asynchronous fixtures will default to the fixture caching scope. Future versions of pytest-asyncio will default the loop scope for asynchronous fixtures to function scope. Set the default fixture loop scope explicitly in order to avoid unexpected behavior in the future. Valid fixture loop scopes are: "function", "class", "module", "package", "session"

  warnings.warn(PytestDeprecationWarning(_DEFAULT_FIXTURE_LOOP_SCOPE_UNSET))
```
