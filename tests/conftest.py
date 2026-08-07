import sys
from pathlib import Path

# symlink.py lives at the repo root, not on the default test path.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
