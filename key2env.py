#! /usr/bin/env python3.12
"""
Extracts the SECRET_KEY from Django settings.py, stores it in .envrc,
and replaces the line in settings.py with an environment variable lookup.
"""

import fileinput
import os
import re
import sys
import stat

SECRET_RE = re.compile(r"^SECRET_KEY = '([^']+)'")
PATHLIB_RE = re.compile(r"^from pathlib import Path")


def main(app_dir: str) -> None:
    settings = os.path.join(app_dir, 'settings.py')

    secret = extract_and_replace_key(settings)
    if not secret:
        raise SystemExit(f"No SECRET_KEY found in {settings}.")

    envrc_file = '.envrc'
    with open(envrc_file, 'a') as envrc:
        envrc.write(f"export DJANGO_SECRET_KEY='{secret}'\n")
    os.chmod(envrc_file, stat.S_IRUSR | stat.S_IWUSR)


def extract_and_replace_key(settings_file: str) -> str | None:
    secret_key = None

    for line in fileinput.input(settings_file, inplace=True):

        match = SECRET_RE.match(line)
        if match:
            secret_key = match.group(1)
            print("SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')")
        elif PATHLIB_RE.match(line):
            print('import os')
            print(line, end='')
        else:
            print(line, end='')

    return secret_key


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(f"USAGE: {sys.argv[0]} <app_dir>")

    main(sys.argv[1])
