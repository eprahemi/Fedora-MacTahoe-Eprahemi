function __mactahoe_migrate_fastfetch --description 'Retire only the verified pre-3.7.5 startup call'
    # Unprivileged; syntax checks never source the user configuration.
    python3 -c '
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile

# Exact historical config prefix, b332baea through 0b82d40f^.
legacy = """if status is-interactive

    # Commands to run in interactive sessions can go here

end

if status is-interactive

    fastfetch

end

# ── Override unknown-command handler with funny errors + did-you-mean ──
if test -f ~/.config/fish/functions/__fish_default_command_not_found_handler.fish
    source ~/.config/fish/functions/__fish_default_command_not_found_handler.fish
end

starship init fish | source
set -gx TERMINAL kitty
set -gx TERM kitty
set -gx ANI_CLI_PLAYER vlc
""".encode()
path = Path(sys.argv[1])
staged = None

def syntax(data):
    return subprocess.run(["fish", "--no-config", "--no-execute"], input=data,
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0

def identity(s):
    return (s.st_dev, s.st_ino, s.st_size, s.st_mtime_ns, s.st_ctime_ns, s.st_mode, s.st_uid, s.st_gid)

try:
    for parent in (path.parent, *path.parent.parents):
        if parent.is_symlink():
            raise ValueError("symlinked fish directory; left untouched")
    try:
        before = path.lstat()
    except FileNotFoundError:
        sys.exit(0)
    if not stat.S_ISREG(before.st_mode) or before.st_uid != os.getuid() or before.st_nlink != 1:
        raise ValueError("config.fish must be an owned, single-link regular file; left untouched")
    original = path.read_bytes()
    offset = original.find(legacy)
    if offset < 0 or original.count(legacy) != 1 or not syntax(original[:offset]):
        if b"fastfetch" in original or b"ANI_CLI_PLAYER vlc" in original:
            print("config.fish may contain an old MacTahoe block or custom fastfetch; ambiguous content left untouched (review startup commands manually).", file=sys.stderr)
        sys.exit(0)
    if not syntax(original):
        raise ValueError("invalid Fish syntax; config.fish left untouched")
    call = offset + legacy.index(b"    fastfetch\n")
    candidate = original[:call] + original[call + len(b"    fastfetch\n"):]
    if not syntax(candidate):
        raise ValueError("migration failed Fish syntax validation")
    # Private persistent backup, independent of rotating tar snapshots.
    backup_dir = Path(tempfile.mkdtemp(prefix=".mactahoe-fastfetch-backup-", dir=path.parent))
    with (backup_dir / "config.fish").open("xb") as backup:
        os.fchmod(backup.fileno(), 0o600)
        backup.write(original)
        backup.flush()
        os.fsync(backup.fileno())
    fd, staged = tempfile.mkstemp(prefix=".mactahoe-fastfetch-", dir=path.parent)
    with os.fdopen(fd, "wb") as output:
        output.write(candidate)
        output.flush()
        os.fchmod(output.fileno(), stat.S_IMODE(before.st_mode))
        os.fchown(output.fileno(), before.st_uid, before.st_gid)
        os.fsync(output.fileno())
    if identity(path.lstat()) != identity(before) or path.read_bytes() != original:
        raise ValueError("config.fish changed during migration; publication refused")
    os.replace(staged, path)
    staged = None
    print("Retired verified legacy MacTahoe fastfetch; private backup: " + str(backup_dir / "config.fish"), file=sys.stderr)
except (OSError, ValueError, subprocess.SubprocessError) as error:
    print("Fastfetch migration failed: " + str(error), file=sys.stderr)
    sys.exit(1)
finally:
    if staged is not None:
        os.unlink(staged)
' "$argv[1]"
end
