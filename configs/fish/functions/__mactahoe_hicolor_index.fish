function __mactahoe_hicolor_index --description 'Merge local hicolor directory declarations'
    if test (count $argv) -ne 1; or test -z "$argv[1]"
        printf '%s\n' 'A hicolor directory is required' >&2
        return 2
    end
    python3 -c '
import configparser
import os
from pathlib import Path
import re
import stat
import sys
import tempfile

root = Path(sys.argv[1]).absolute()
path = root / "index.theme"
required = {
    "48x48/apps": {"Size": "48", "Context": "Applications", "Type": "Fixed"},
    "256x256/apps": {"Size": "256", "Context": "Applications", "Type": "Fixed"},
    "scalable/apps": {"Size": "48", "Context": "Applications", "Type": "Scalable",
                      "MinSize": "1", "MaxSize": "512"},
}

def identity():
    try:
        s = path.lstat()
    except FileNotFoundError:
        return None
    if not stat.S_ISREG(s.st_mode):
        raise ValueError("index.theme is not a regular file")
    return s

def parse(text):
    p = configparser.ConfigParser(interpolation=None, strict=True, inline_comment_prefixes=("#", ";"))
    p.optionxform = str
    p.read_string(text)
    if p.defaults() or "Icon Theme" not in p:
        raise ValueError("invalid icon theme header")
    return p

tmp = None
try:
    # Never follow a redirected destination, including a symlinked size directory.
    for parent in (root, *root.parents):
        if parent.is_symlink():
            raise ValueError("symlinked icon destination")
    for directory in required:
        for part in (root / directory, (root / directory).parent):
            if part.is_symlink():
                raise ValueError("symlinked icon directory")
    root.mkdir(parents=True, exist_ok=True)
    before = identity()
    text = path.read_text() if before else (
        "[Icon Theme]\nName=Hicolor\nComment=Fallback icon theme (local overrides)\nHidden=true\n")
    p = parse(text)
    dirs = [d.strip() for d in p["Icon Theme"].get("Directories", "").split(",") if d.strip()]
    dirs.extend(d for d in required if d not in dirs)
    changes = {"Icon Theme": {"Directories": ",".join(dirs)}, **required}
    # Edit only owned keys; preserve unrelated lines, sections and comments verbatim.
    lines = text.splitlines(keepends=True)
    section = None
    seen = {}
    output = []
    def finish():
        if section in changes:
            for key, value in changes[section].items():
                if key not in seen[section]:
                    output.append(f"{key}={value}\n")
    for line in lines:
        header = re.match(r"^\s*\[([^]]+)\]\s*(?:[#;].*)?$", line)
        if header:
            finish()
            section = header[1]
            seen[section] = set()
        key = re.match(r"^(\s*)([^#;\s][^=:]*?)(\s*[=:]\s*)(.*?)(\r?\n)?$", line)
        if key and section in changes and key[2].strip() in changes[section]:
            name = key[2].strip()
            seen[section].add(name)
            value = changes[section][name]
            if p[section].get(name) != value:
                comment = re.search(r"\s+[#;].*$", key[4])
                suffix = comment[0] if comment else ""
                line = f"{key[1]}{key[2]}{key[3]}{value}{suffix}\n"
        output.append(line if line.endswith("\n") else line + "\n")
    finish()
    for section, values in required.items():
        if section not in seen:
            output.append("\n[" + section + "]\n")
            output.extend(f"{k}={v}\n" for k, v in values.items())
    merged = "".join(output)
    checked = parse(merged)
    for section, values in required.items():
        assert all(checked[section][k] == v for k, v in values.items())
    if before and merged == text:
        sys.exit(0)
    fd, tmp = tempfile.mkstemp(prefix=".index.theme-", dir=root)
    with os.fdopen(fd, "w") as f:
        f.write(merged)
        f.flush()
        if before:
            os.fchown(f.fileno(), before.st_uid, before.st_gid)
        os.fchmod(f.fileno(), stat.S_IMODE(before.st_mode) if before else 0o644)
        os.fsync(f.fileno())
    current = identity()
    def stamp(s):
        return (s.st_dev, s.st_ino, s.st_size, s.st_mtime_ns, s.st_ctime_ns) if s else None
    if stamp(current) != stamp(before):
        raise ValueError("index.theme changed during merge")
    if before:
        os.replace(tmp, path)
    else:
        os.link(tmp, path)  # no-clobber creation
except (OSError, ValueError, configparser.Error) as e:
    print(f"Cannot merge hicolor index: {e}", file=sys.stderr)
    sys.exit(1)
finally:
    if tmp and os.path.exists(tmp):
        os.unlink(tmp)
' "$argv[1]"
end
