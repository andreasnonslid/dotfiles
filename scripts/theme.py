#!/usr/bin/env python3
"""Theme generator entry point. The code lives in scripts/themegen/ (see its modules);
usage: theme.py list colors|styles | current | colors NAME | style NAME | apply [COLORS [STYLE]] | ...
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from themegen.cli import main  # noqa: E402

if __name__ == "__main__":
    main(sys.argv)
