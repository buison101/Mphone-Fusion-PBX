# Repository Guidelines

## Project Structure & Module Organization

This repository is a FusionPBX PHP application. Feature modules live in `app/<module>/` and usually include `app_config.php`, `app_languages.php`, `app_menu.php`, and one or more page/controller PHP files. Core platform modules are under `core/`, including authentication, users, groups, domains, menus, installs, and upgrades. Shared classes, functions, vendor libraries, JavaScript, templates, and install resources are in `resources/`. Theme and branding work belongs in `themes/default/` or project-specific themes such as `themes/mybrand/`. The `secure/` directory is reserved for protected runtime/configuration material.

## Build, Test, and Development Commands

There is no root build system in this tree. Use targeted checks before committing:

```sh
php -l path/to/file.php
find app core resources themes -name '*.php' -print0 | xargs -0 -n1 php -l
lua app/switch/resources/scripts/resources/tests/self_test.lua
```

`php -l` catches syntax errors in changed PHP files. The `find` command runs a broader syntax sweep. The Lua command runs the available FreeSWITCH script self-test when script resources are changed. Run the app through the configured web server and verify login/module pages after UI or permission changes.

## Coding Style & Naming Conventions

Match the surrounding FusionPBX style. Use tabs for PHP indentation, keep opening `<?php` tags and license headers consistent with nearby files, and prefer existing helper functions/classes from `resources/` over new utility patterns. Name modules and files with lowercase snake case, for example `app/device_logs/device_logs.php`. Keep module metadata files named exactly as expected: `app_config.php`, `app_defaults.php`, `app_languages.php`, and `app_menu.php`.

## Testing Guidelines

This repository has limited automated tests, so contributors are responsible for focused manual verification. Test the exact module changed, its permissions/menu visibility, database reads or writes, and any FreeSWITCH-facing behavior. For language or UI changes, check the relevant pages in the browser and confirm text renders without layout regressions.

## Commit & Pull Request Guidelines

Recent commits use short, direct summaries, often in Vietnamese, such as `Chinh lai sidebar 8`. Keep commits concise and scoped to one logical change. Pull requests should describe the affected module, summarize manual or command-line checks performed, link any issue or ticket, and include screenshots for visible UI/theme changes.

## Security & Configuration Tips

Do not commit secrets, local database credentials, generated call recordings, or environment-specific runtime files. Treat files under `secure/` and deployment config as sensitive. Validate user input with existing FusionPBX patterns and preserve permission checks when editing module pages.
