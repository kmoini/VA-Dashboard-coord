---
name: unit-tests-have-no-container
description: tests/Unit runs pure PHPUnit with NO Laravel container; any config()/app() call reached from a class those tests cover (DocumentRoleDetector, BalanceForward, ...) fails "Target class [config] does not exist". Run tests/Unit before every push, plus the PostgreSQL gate list locally.
metadata:
  type: feedback
---

Gate RED on 2026-10-27 (f6c133cd): DepositSlipRepresenter::enabled() called config() from DocumentRoleDetector::detect(), and tests/Unit/DocumentRoleDetectorTest (12 cases) runs the detector without a container. The other session fixed it (5db4f84a: DocumentRoleDetector::depositSlipsOn() reads the flag only when app()->bound('config'), else off).

**Why:** the Feature suites all boot Laravel, so a config() call in a service looks fine until a Unit test constructs the class bare. SQLite shows it too, but only if tests/Unit is run.

**How to apply:** before pushing a branch to the gate run `vendor/bin/phpunit tests/Unit` as well as the Feature suites, and the PostgreSQL list locally (recipe in [[ci-gate-on-server]]). Inside classes covered by Unit tests, guard container access with `app()->bound('config')` or take the flag as a constructor argument.
