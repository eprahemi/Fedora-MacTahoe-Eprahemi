#!/usr/bin/env python3
"""Installer asset transactions. No broad deletion, image-based pack guessing or eval.

Settings/snapshots run as the desktop user; only the fixed system pack publication
runs through sudo. Recovery copies are private transaction data, not user originals.
Retired system assets go through root's gio Trash (not the desktop user's Trash).
Unknown legacy avatar entries are augmented, never guessed or silently purged.
An active account icon may remain at its old pathname as a protected dependency;
that single protected image is not evidence that the extra collection is installed.
"""
import ast
import configparser
import fcntl
import hashlib
import json
import os
import re
from pathlib import Path
import shutil
import shlex
import signal
import stat
import subprocess
import sys
import tempfile
import urllib.parse
import xml.etree.ElementTree as ET
import zipfile

SYSTEM = Path('/usr/share')
ACCOUNTS = Path('/var/lib/AccountsService/users')
SCHEMA = 'org.gnome.desktop.background'
KEYS = ('picture-uri', 'picture-uri-dark', 'picture-options', 'color-shading-type',
        'primary-color', 'secondary-color')
MARKER = '.mactahoe-pack.json'
DEPENDENCIES = '.mactahoe-active-dependencies.json'
IMAGES = {'.jpg', '.jpeg', '.png', '.webp', '.jxl', '.avif', '.bmp', '.gif', '.heic'}


def run(*args, **kw):
    return subprocess.run(args, check=True, text=True, capture_output=True, **kw).stdout.strip()


def data_home():
    p = Path(os.environ.get('XDG_DATA_HOME') or Path.home() / '.local/share')
    return p if p.is_absolute() else Path.home() / '.local/share'


def private_dir(parent, prefix):
    parent.mkdir(parents=True, exist_ok=True)
    # Refuse indirect/foreign writable snapshot/transaction storage.
    for p in (parent, *parent.parents):
        if p.is_symlink():
            raise ValueError(f'Symlinked storage is not supported: {p}')
    return Path(tempfile.mkdtemp(prefix=prefix, dir=parent))


def write_json(path, value):
    fd, name = tempfile.mkstemp(prefix=path.name + '.', dir=path.parent)
    temporary = Path(name)
    with os.fdopen(fd, 'w') as stream:
        stream.write(json.dumps(value, sort_keys=True, indent=2) + '\n')
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)
    fd = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def sync_tree(path):
    for item in [path] + (list(path.rglob('*')) if path.is_dir() else []):
        fd = os.open(item, os.O_RDONLY)
        try:
            os.fsync(fd)
        finally:
            os.close(fd)


def local_path(value, parent=None):
    uri = urllib.parse.urlsplit(value)
    if uri.scheme:
        if uri.scheme != 'file' or uri.netloc not in ('', 'localhost'):
            return None
        return Path(urllib.parse.unquote(uri.path))
    if not value:
        return None
    p = Path(value)
    return p if p.is_absolute() else (parent / p if parent else None)


def snapshot():
    settings = {k: run('gsettings', 'get', SCHEMA, k) for k in KEYS}
    explicit = {k: run('dconf', 'read', '/org/gnome/desktop/background/' + k) for k in KEYS}
    folder = private_dir(data_home() / 'fedora-mactahoe/preserved-backgrounds', 'snapshot-')
    copied, dependencies, visiting, original_hashes = {}, {}, set(), {}

    def save(path):
        path = Path(os.path.abspath(path))
        key = str(path)
        if key in visiting:
            raise ValueError('Cyclic wallpaper XML reference')
        if key in copied:
            return copied[key], dependencies[key]
        if not path.is_file():
            raise ValueError(f'Active wallpaper dependency is missing: {path}')
        visiting.add(key)
        target = folder / (hashlib.sha256(os.fsencode(path)).hexdigest() + path.suffix)
        shutil.copy2(path, target)
        original_hashes[key] = hashlib.sha256(target.read_bytes()).hexdigest()
        if hashlib.sha256(path.read_bytes()).hexdigest() != original_hashes[key]:
            raise ValueError('Active wallpaper changed during preservation; retry')
        all_paths = {key}
        if path.suffix.lower() == '.xml':
            tree = ET.parse(target)
            # GNOME slideshows: file/from/to, including resolution-specific size
            # children. Picker XML: filename/filename-dark. Recurse through XMLs.
            def rewrite(node, relevant=False):
                relevant = relevant or node.tag.split('}')[-1] in ('file', 'from', 'to', 'filename', 'filename-dark')
                if relevant and len(node) == 0 and (node.text or '').strip():
                    value = node.text.strip()
                    ref = local_path(value, path.parent)
                    if ref is None:
                        raise ValueError('Non-local wallpaper XML dependency cannot be preserved')
                    new, children = save(ref)
                    all_paths.update(children)
                    node.text = Path(new).as_uri() if value.startswith('file:') else new
                for child in node:
                    rewrite(child, relevant)
            rewrite(tree.getroot())
            shutil.copy2(path, target.with_suffix('.original.xml'))
            tree.write(target, encoding='utf-8', xml_declaration=True)
        visiting.remove(key)
        copied[key] = str(target)
        dependencies[key] = sorted(all_paths)
        return str(target), sorted(all_paths)

    roots = {}
    for key in ('picture-uri', 'picture-uri-dark'):
        value = ast.literal_eval(settings[key])
        path = local_path(value)
        if path is not None:
            new, refs = save(path)
            roots[key] = {'copy': new, 'paths': refs}
    sync_tree(folder)
    write_json(folder / 'snapshot.json', {'settings': settings, 'explicit': explicit,
                                         'roots': roots, 'original_hashes': original_hashes})
    return str(folder / 'snapshot.json')


def restore(snapshot_file):
    saved = json.loads(Path(snapshot_file).read_text())
    errors = []
    for key in KEYS:
        try:
            value = saved['explicit'][key]
            path = '/org/gnome/desktop/background/' + key
            root = saved['roots'].get(key)
            if root:
                try:
                    intact = all(Path(p).is_file() and hashlib.sha256(Path(p).read_bytes()).hexdigest() ==
                                 saved.get('original_hashes', {}).get(p) for p in root['paths'])
                except OSError:
                    intact = False
                if not intact:
                    # A signal after a successful publication, or a failed disk
                    # rollback, must never restore a now-missing original URI.
                    value = repr(Path(root['copy']).as_uri())
            if value:
                run('dconf', 'write', path, value)
            else:
                run('dconf', 'reset', path)
        except Exception as error:
            errors.append(str(error))
    if errors:
        raise RuntimeError('Wallpaper settings rollback failed: ' + '; '.join(errors))


def relocate(snapshot_file, plan_file):
    saved = json.loads(Path(snapshot_file).read_text())
    plan = json.loads(Path(plan_file).read_text())
    if plan.get('preserve_paths'):
        # Recheck the latest selection, not only the snapshot taken while staging.
        # A user selecting another retiring image requires a fresh staged plan.
        for root in saved['roots'].values():
            for ref in map(Path, root['paths']):
                for target, source in plan['changes'].items():
                    target = Path(target)
                    if ref == target or target in ref.parents:
                        candidate = Path(source) if source else None
                        if candidate and target in ref.parents:
                            candidate = candidate / ref.relative_to(target)
                        if not candidate or not candidate.is_file() or hashlib.sha256(candidate.read_bytes()).hexdigest() != saved['original_hashes'][str(ref)]:
                            raise ValueError('Active wallpaper changed after staging; rerun safely')
        return
    targets = plan['expected']
    try:
        for key, root in saved['roots'].items():
            if any(Path(ref) == Path(t) or Path(t) in Path(ref).parents for ref in root['paths'] for t in targets):
                run('gsettings', 'set', SCHEMA, key, repr(Path(root['copy']).as_uri()))
    except BaseException:
        restore(snapshot_file)
        raise


def locations(kind):
    if kind == 'wallpaper':
        return [SYSTEM / 'backgrounds/Wallvault Wallpapers', SYSTEM / 'backgrounds/Wallvault Wallpapers +18',
                SYSTEM / 'gnome-background-properties/wallvault-wallpapers.xml',
                SYSTEM / 'gnome-background-properties/wallvault-wallpapers-18.xml']
    if kind == 'avatar':
        return [SYSTEM / 'pixmaps/faces', SYSTEM / 'pixmaps/faces +18']
    raise ValueError('Unknown pack kind')


def stock_records(kind):
    """Exact RPM file records, never directories/globs or inferred custom packs.

    Only original package bytes qualify for cleanup. Modified/replaced stock paths
    are user data. RPM absence/unavailability safely means no stock cleanup.
    """
    try:
        names = run('rpm', '-qa', '--qf', '%{NAME}\n').splitlines()
        packages = [n for n in names if re.fullmatch(r'f[0-9]+-backgrounds-(base|gnome)', n) or
                    n in ('gnome-backgrounds', 'fedora-workstation-backgrounds')] if kind == 'wallpaper' else ['gnome-control-center']
        records = {}
        for package in packages:
            try:
                dump = run('rpm', '-q', '--dump', package)
            except subprocess.CalledProcessError:
                continue
            for line in dump.splitlines():
                fields = line.split()
                if len(fields) < 5:
                    continue
                name, _, _, digest, mode = fields[:5]
                if not stat.S_ISREG(int(mode, 8)):
                    continue
                if kind == 'wallpaper':
                    release = package.split('-')[0]
                    if package in ('gnome-backgrounds', 'fedora-workstation-backgrounds'):
                        folder = 'gnome' if package == 'gnome-backgrounds' else 'fedora-workstation'
                        allowed = (name.startswith('/usr/share/backgrounds/' + folder + '/') or
                                   (Path(name).parent == Path('/usr/share/gnome-background-properties') and name.endswith('.xml')))
                    else:
                        allowed = (name.startswith('/usr/share/backgrounds/' + release + '/') or
                                   name == '/usr/share/gnome-background-properties/' + release + '.xml')
                else:
                    allowed = name.startswith('/usr/share/pixmaps/faces/') and len(Path(name).parts) == 6
                if allowed and re.fullmatch(r'[0-9a-f]{32}|[0-9a-f]{64}', digest):
                    records[SYSTEM / Path(name).relative_to('/usr/share')] = digest
        return records
    except (OSError, subprocess.CalledProcessError):
        return {}


def persisted_icons():
    """Read all persisted selections; unreadable metadata must never mean none."""
    try:
        icons = []
        for account in ACCOUNTS.iterdir() if ACCOUNTS.is_dir() else []:
            if account.is_symlink() or not account.is_file():
                raise ValueError('Unsafe AccountsService metadata entry')
            ini = configparser.ConfigParser(interpolation=None)
            with account.open() as stream:
                ini.read_file(stream)
            icons.append(ini.get('User', 'Icon', fallback=''))
    except PermissionError:
        if ACCOUNTS != Path('/var/lib/AccountsService/users') or os.geteuid() == 0:
            raise
        # Fixed read-only program, isolated system interpreter, no helper import,
        # caller paths, shell interpolation, or privileged mutation.
        code = '''import configparser,json,os,stat
root='/var/lib/AccountsService/users'
icons=[]
fd=os.open(root,os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW)
try:
 for name in os.listdir(fd):
  f=os.open(name,os.O_RDONLY|os.O_NOFOLLOW|os.O_NONBLOCK,dir_fd=fd)
  with os.fdopen(f) as stream:
   if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode):
    raise ValueError('Nonregular account metadata')
   ini=configparser.ConfigParser(interpolation=None)
   ini.read_file(stream)
   icons.append(ini.get('User','Icon',fallback=''))
finally:
 os.close(fd)
print(json.dumps(icons))
'''
        icons = json.loads(run('sudo', '-n', '--', '/usr/bin/python3', '-I', '-c', code))
    if (not isinstance(icons, list) or len(icons) > 100000 or
            any(not isinstance(p, str) or len(p) > 4096 or '\x00' in p or
                (p and (not Path(p).is_absolute() or '..' in Path(p).parts))
                for p in icons)):
        raise ValueError('Invalid AccountsService icon enumeration')
    return [p for p in icons if p]


def stock_changes(kind):
    protected = set()
    if kind == 'wallpaper':
        saved = json.loads(Path(snapshot()).read_text())
        protected.update(Path(p) for root in saved['roots'].values() for p in root['paths'])
    else:
        protected.add(Path(account_icon()))
        protected.update(map(Path, persisted_icons()))
    changes = {}
    for path, digest in stock_records(kind).items():
        if path in protected or path.is_symlink() or not path.is_file():
            continue
        if hashlib.new('md5' if len(digest) == 32 else 'sha256', path.read_bytes()).hexdigest() == digest:
            changes[str(path)] = None
    return changes


def inventory(path):
    if path.is_symlink():
        raise ValueError(f'Symlinked pack target: {path}')
    if not path.exists():
        return None
    h = hashlib.sha256()
    paths = [path] + (sorted(path.rglob('*')) if path.is_dir() else [])
    for item in paths:
        if item.is_symlink() or not (item.is_dir() or item.is_file()):
            raise ValueError(f'Unsupported pack entry: {item}')
        st = item.stat()
        h.update(str((str(item.relative_to(path)), stat.S_IMODE(st.st_mode), st.st_uid, st.st_gid)).encode())
        if item.is_file():
            with item.open('rb') as stream:
                for block in iter(lambda: stream.read(1024 * 1024), b''):
                    h.update(block)
    return h.hexdigest()


def installed(kind, legacy_state=None):
    targets = locations(kind)
    if kind == 'wallpaper':
        adult = (targets[1].exists() and not (targets[1] / DEPENDENCIES).is_file()) or targets[3].exists()
        normal = (targets[0].exists() and not (targets[0] / DEPENDENCIES).is_file()) or targets[2].exists()
        if adult:
            return 'both' if normal else '18'
        return 'normal' if normal else 'absent'
    legacy = targets[1].exists()
    dependency_marker = targets[1] / DEPENDENCIES
    if legacy and dependency_marker.is_file() and not dependency_marker.is_symlink():
        protected = json.loads(dependency_marker.read_text())
        actual = {str(p.relative_to(targets[1])): hashlib.sha256(p.read_bytes()).hexdigest()
                  for p in targets[1].rglob('*') if p.is_file() and p != dependency_marker and not p.is_symlink()}
        legacy = protected.get('files') != actual
    marker = targets[0] / MARKER
    if marker.is_file() and not marker.is_symlink():
        value = json.loads(marker.read_text())
        if value.get('schema') != 1 or value.get('kind') != kind or value.get('variant') not in ('normal', '18', 'both', 'unknown'):
            raise ValueError('Invalid installed avatar pack metadata')
        # Known dedicated legacy collection takes precedence over a main marker.
        if legacy:
            return 'both' if value['variant'] in ('normal', 'both') else '18'
        for name, digest in value.get('files', {}).items():
            if Path(name).name != name:
                raise ValueError('Unsafe installed avatar metadata')
            item = targets[0] / name
            if not item.is_file() or item.is_symlink() or hashlib.sha256(item.read_bytes()).hexdigest() != digest:
                return 'unknown'
        return value['variant']
    if legacy:
        return '18'
    if legacy_state and targets[0].exists():
        state = json.loads(Path(legacy_state).read_text())
        # Historical successful install + explicit extra-pack answer is conservative
        # evidence requiring consent, never evidence that arbitrary images are safe.
        if state.get('steps', {}).get('install_custom_avatars') and state.get('prompts', {}).get('wallpaper_18', {}).get('choice') in (True, 'true'):
            # Prompt defaults are saved before the pack step. Keep conservative
            # historical installation evidence separately, so declining today
            # does not erase detection of the unchanged legacy collection.
            provenance = data_home() / 'fedora-mactahoe/asset-provenance.json'
            provenance.parent.mkdir(parents=True, exist_ok=True)
            if provenance.is_symlink() or provenance.parent.is_symlink():
                raise ValueError('Symlinked asset provenance storage')
            existing = json.loads(provenance.read_text()) if provenance.exists() else {}
            existing['legacy_avatar_18'] = inventory(targets[0])
            write_json(provenance, existing)
            return '18'
    provenance = data_home() / 'fedora-mactahoe/asset-provenance.json'
    if provenance.is_file() and not provenance.is_symlink() and targets[0].exists():
        evidence = json.loads(provenance.read_text()).get('legacy_avatar_18')
        if evidence and evidence == inventory(targets[0]):
            return '18'
    return 'unknown' if targets[0].exists() else 'absent'


def account_icon():
    parts = shlex.split(run('busctl', '--system', 'get-property', 'org.freedesktop.Accounts',
                            '/org/freedesktop/Accounts/User' + str(os.getuid()),
                            'org.freedesktop.Accounts.User', 'IconFile'))
    if len(parts) != 2 or parts[0] != 's':
        raise ValueError('Cannot determine current account avatar safely')
    return parts[1]


def validate_image(path):
    with Path(path).open('rb') as stream:
        header = stream.read(64)
    coder = None
    if header.startswith(b'\xff\xd8\xff'):
        coder = 'JPEG'
    elif header.startswith(b'\x89PNG\r\n\x1a\n'):
        coder = 'PNG'
    elif header[:6] in (b'GIF87a', b'GIF89a'):
        coder = 'GIF'
    elif header[:4] == b'RIFF' and header[8:12] == b'WEBP':
        coder = 'WEBP'
    elif header.startswith(b'BM'):
        coder = 'BMP'
    elif header.startswith(b'\xff\x0a') or header.startswith(b'\x00\x00\x00\x0cJXL \r\n\x87\n'):
        coder = 'JXL'
    elif header[4:8] == b'ftyp' and header[8:12] in (b'avif', b'avis', b'heic', b'heix', b'hevc', b'hevx', b'mif1'):
        coder = 'HEIC'
    if not coder:
        raise ValueError(f'Unrecognized raster image: {Path(path).name}')
    tool = shutil.which('magick') or shutil.which('identify')
    if not tool:
        raise RuntimeError('ImageMagick is required to validate asset packs')
    args = [tool] + (['identify'] if Path(tool).name == 'magick' else [])
    # Decode rather than trusting a ZIP signature or image header. Warnings from
    # truncated/corrupt payloads are failures, before any installed file moves.
    limits = ['-limit', 'memory', '256MiB', '-limit', 'map', '512MiB',
              '-limit', 'disk', '1GiB', '-limit', 'time', '30']
    image = coder + ':' + str(path) + '[0]'
    result = run(*args, *limits, '-regard-warnings', '-format', '%w %h', image, timeout=40)
    dims = result.split()
    if len(dims) != 2 or min(map(int, dims)) < 1 or int(dims[0]) * int(dims[1]) > 100000000:
        raise ValueError(f'Invalid image: {path.name}')
    decoder = shutil.which('magick') or shutil.which('convert')
    if not decoder:
        raise RuntimeError('ImageMagick is required to decode asset packs')
    run(decoder, *limits, '-regard-warnings', image, 'null:', timeout=40)
    return tuple(map(int, dims))


def collect_archive(archive, dest, prefix=''):
    with zipfile.ZipFile(archive) as source:
        total = 0
        for entry in source.infolist():
            p = Path(entry.filename)
            mode = entry.external_attr >> 16
            if (p.is_absolute() or '..' in p.parts or '\\' in entry.filename or
                    '\x00' in entry.orig_filename or entry.flag_bits & 1 or
                    (stat.S_IFMT(mode) not in (0, stat.S_IFREG, stat.S_IFDIR))):
                raise ValueError('Unsafe path/link in asset archive')
            total += entry.file_size
            if (total > 2 * 1024 ** 3 or len(source.infolist()) > 10000 or
                    entry.file_size > 128 * 1024 ** 2 or
                    entry.file_size > max(1, entry.compress_size) * 1000):
                raise ValueError('Asset archive exceeds staging limits')
            if entry.is_dir() or p.name.startswith('.') or '__MACOSX' in p.parts:
                continue
            if p.suffix and p.suffix.lower() not in IMAGES:
                raise ValueError(f'Unexpected asset archive file: {p.name}')
            suffix = ''
            if not p.suffix:
                # The published wallpaper archive contains a regular JPEG named
                # "80". Only recognize raster signatures, never delegate/script
                # formats, and still decode the staged media before accepting it.
                with source.open(entry) as stream:
                    header = stream.read(16)
                if header.startswith(b'\xff\xd8\xff'):
                    suffix = '.jpg'
                elif header.startswith(b'\x89PNG\r\n\x1a\n'):
                    suffix = '.png'
                elif header[:6] in (b'GIF87a', b'GIF89a'):
                    suffix = '.gif'
                elif header[:4] == b'RIFF' and header[8:12] == b'WEBP':
                    suffix = '.webp'
                else:
                    raise ValueError(f'Unrecognized extensionless asset image: {p.name}')
            target = dest / (prefix + p.name + suffix)
            with target.open('xb') as out, source.open(entry) as stream:
                shutil.copyfileobj(stream, out)
            if suffix:
                validate_image(target)


def build(kind, variant, mode, bundle, stage, archives, legacy_state=None):
    stage = Path(stage)
    targets = locations(kind)
    current = installed(kind, legacy_state)
    before = {str(t): inventory(t) for t in targets}
    payload = stage / 'payload'
    payload.mkdir()
    changes = {}
    # Defense in depth: callers cannot use contradictory saved choices to retire
    # either collection once both are installed.
    if current == 'both':
        variant, mode = 'keep', 'add'
    elif current == 'normal':
        mode = 'add'
    wanted = [] if variant == 'keep' else (['normal', '18'] if variant == 'both' else [variant])
    if mode == 'replace' and kind == 'wallpaper':
        changes = {str(t): None for t in targets}
    if kind == 'avatar' and variant != 'keep':
        faces = payload / 'faces'
        faces.mkdir()
        managed = {}
        # Unknown legacy entries and stock/vendor faces are augmented, not purged.
        if targets[0].exists():
            inventory(targets[0])
            shutil.copytree(targets[0], faces, dirs_exist_ok=True)
            # Managed files may be refreshed in add mode; unrelated/unknown files
            # are never inferred to belong to a pack from their appearance.
            marker = faces / MARKER
            if marker.is_file():
                owned = json.loads(marker.read_text()).get('files', {})
                managed.update(owned)
                for name, digest in owned.items():
                    if Path(name).name != name:
                        raise ValueError('Unsafe installed avatar manifest filename')
                    item = faces / name
                    if item.is_file() and hashlib.sha256(item.read_bytes()).hexdigest() == digest:
                        if mode == 'replace' or variant == 'both' or (variant == 'normal' and name.startswith('mactahoe-normal-')) or (variant == '18' and name.startswith('mactahoe-extra-')):
                            item.unlink()  # private staged copy only
                            managed.pop(name, None)
        changes[str(targets[0])] = str(faces)
        if mode == 'replace' and targets[1].exists():
            changes[str(targets[1])] = None
    for pack in wanted:
        images = payload / (kind + '-' + pack)
        images.mkdir()
        if pack == 'normal':
            source = Path(bundle) / ('wallpapers/background-normal' if kind == 'wallpaper' else 'assets/normal-faces')
            if not source.is_dir():
                raise ValueError('Normal asset source is missing')
            for image in sorted(source.iterdir()):
                if image.is_symlink() or not image.is_file() or image.suffix.lower() not in IMAGES:
                    raise ValueError('Unexpected normal asset source entry')
                shutil.copy2(image, images / image.name)
        else:
            for index, archive in enumerate(archives):
                collect_archive(archive, images, prefix=f'{index}-')
        files = list(images.iterdir())
        if not files:
            raise ValueError('Staged asset pack is empty')
        for image in files:
            validate_image(image)
            if kind == 'avatar':
                name = ('mactahoe-normal-' if pack == 'normal' else 'mactahoe-extra-') + image.stem + '.jpg'
                out = faces / name
                if out.exists():
                    # Never overwrite an unknown collection's colliding filename.
                    raise ValueError(f'Avatar destination collision: {name}')
                converter = shutil.which('magick') or shutil.which('convert')
                if not converter:
                    raise RuntimeError('ImageMagick avatar conversion is unavailable')
                run(converter, str(image), '-resize', '512x512^', '-gravity', 'center', '-extent', '512x512', '-quality', '92', str(out))
                if validate_image(out) != (512, 512):
                    raise ValueError('Converted avatar is not exactly 512x512')
                managed[name] = hashlib.sha256(out.read_bytes()).hexdigest()
        if kind == 'wallpaper':
            target = targets[0 if pack == 'normal' else 1]
            xml_target = targets[2 if pack == 'normal' else 3]
            xml = ET.Element('wallpapers')
            for image in sorted(files):
                entry = ET.SubElement(xml, 'wallpaper', deleted='false')
                for key, value in [('name', image.stem), ('filename', str(target / image.name)), ('options', 'zoom'),
                                   ('shade_type', 'solid'), ('pcolor', '#000000'), ('scolor', '#000000')]:
                    ET.SubElement(entry, key).text = value
            xml_file = payload / xml_target.name
            ET.ElementTree(xml).write(xml_file, encoding='utf-8', xml_declaration=True)
            ET.parse(xml_file)
            if target.is_dir():
                # Legacy wallpaper folders have no per-file ownership manifest.
                # Preserve unknown/custom entries, including changed collisions.
                for old in target.iterdir():
                    if old.name == DEPENDENCIES:
                        continue
                    dest = images / old.name
                    if old.is_dir():
                        shutil.copytree(old, dest, dirs_exist_ok=True)
                    elif not dest.exists() or old.read_bytes() != dest.read_bytes():
                        shutil.copy2(old, dest)
            changes[str(target)] = str(images)
            changes[str(xml_target)] = str(xml_file)
    if kind == 'avatar' and variant != 'keep':
        effective = ('unknown' if current == 'unknown' and variant == 'normal' else
                     ('both' if mode == 'add' and current not in ('absent', 'unknown', variant) else variant))
        write_json(faces / MARKER, {'schema': 1, 'kind': kind, 'variant': effective,
                                   'files': managed})
    # Stock faces share the managed directory. Remove only verified original RPM
    # files from the private candidate, never purge that directory or custom faces.
    stock = stock_changes(kind)
    if kind == 'avatar' and str(targets[0]) in changes:
        for target in list(stock):
            path = Path(target)
            if path.parent == targets[0]:
                candidate = faces / path.name
                if candidate.is_file():
                    candidate.unlink()
                stock.pop(target)
    changes.update(stock)
    before.update({t: inventory(Path(t)) for t in stock})
    if kind == 'wallpaper':
        saved = json.loads(Path(snapshot()).read_text())
        for root in saved['roots'].values():
            for ref in map(Path, root['paths']):
                for target, source in list(changes.items()):
                    target = Path(target)
                    if target in ref.parents:
                        if source is None:
                            candidate = payload / ('dependency-' + target.name)
                            candidate.mkdir(exist_ok=True)
                            write_json(candidate / DEPENDENCIES, {'dependency_only': True})
                            changes[str(target)] = source = str(candidate)
                        dest = Path(source) / ref.relative_to(target)
                        dest.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(ref, dest)
                    elif target == ref:
                        # Keep a directly active XML/image at its original URI.
                        candidate = payload / ('active-' + target.name)
                        shutil.copy2(ref, candidate)
                        changes[str(target)] = str(candidate)
    if any(inventory(t) != before[str(t)] for t in targets):
        raise ValueError('Installed collection changed during staging')
    expected = {t: before[t] for t in changes}
    plan = {'kind': kind, 'variant': variant, 'mode': mode, 'expected': expected, 'changes': changes,
            'preserve_paths': kind == 'wallpaper',
            'staged': {t: inventory(Path(src)) for t, src in changes.items() if src},
            'icons': [account_icon()] if kind == 'avatar' else []}
    write_json(stage / 'plan.json', plan)
    return str(stage / 'plan.json')


def copy(src, dst, preserve_owner=False):
    if src.is_dir():
        shutil.copytree(src, dst, copy_function=shutil.copy2)
    else:
        shutil.copy2(src, dst)
    if preserve_owner and os.geteuid() == 0:
        for item in [src] + (list(src.rglob('*')) if src.is_dir() else []):
            target = dst / item.relative_to(src) if src.is_dir() else dst
            st = item.stat()
            os.chown(target, st.st_uid, st.st_gid)


def remove_private(path):
    if path.is_dir():
        shutil.rmtree(path)
    elif path.exists():
        path.unlink()


def recover(txn):
    record = json.loads((txn / 'journal.json').read_text())
    allowed = {str(t) for t in locations(record['kind'])} | {str(t) for t in stock_records(record['kind'])}
    if set(record['expected']) - allowed:
        raise ValueError('Invalid recovery journal targets')
    for index, (target, old) in enumerate(record['expected'].items()):
        target = Path(target)
        backup = txn / 'backup' / str(index)
        # A completed backup precedes every publication; incomplete preparation
        # never touched targets. Recovery is repeatable after another interruption.
        if record['phase'] == 'publishing':
            retired_original = txn / 'retired' / (str(index) + '-' + target.name)
            if not retired_original.exists() and target.exists() and inventory(target) == old:
                continue
            if target.exists() and inventory(target) != record.get('replacement', {}).get(str(target)):
                raise ValueError(f'Recovery target changed externally; retained recovery copies at {txn}')
            if target.exists():
                retired = txn / ('failed-new-' + str(index))
                if retired.exists():
                    remove_private(retired)
                target.rename(retired)
            if retired_original.exists():
                retired_original.rename(target)
            elif old is not None:
                copy(backup, target, preserve_owner=True)
    remove_private(txn)


def apply(plan_file):
    plan = json.loads(Path(plan_file).read_text())
    allowed = {str(t) for t in locations(plan['kind'])} | {str(t) for t in stock_records(plan['kind'])}
    if set(plan['expected']) != set(plan['changes']) or set(plan['expected']) - allowed:
        raise ValueError('Invalid pack transaction targets')
    # Native sudo has already authenticated; never invoke shell commands/eval.
    SYSTEM.mkdir(parents=True, exist_ok=True)
    with (SYSTEM / '.mactahoe-assets.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        for pending in SYSTEM.glob('.mactahoe-assets-txn-*'):
            if pending.is_symlink() or pending.stat().st_uid != os.geteuid() or stat.S_IMODE(pending.stat().st_mode) & 0o077:
                raise ValueError('Unsafe pending asset transaction')
            recover(pending)
        for target, expected in plan['expected'].items():
            target = Path(target)
            for parent in target.parents:
                if parent.is_symlink():
                    raise ValueError('Symlinked system pack parent')
            if inventory(target) != expected:
                raise ValueError('Installed pack changed after staging; rerun for fresh consent')
        txn = private_dir(SYSTEM, '.mactahoe-assets-txn-')
        (txn / 'backup').mkdir()
        (txn / 'new').mkdir()
        (txn / 'retired').mkdir()
        plan['phase'] = 'preparing'
        write_json(txn / 'journal.json', plan)
        try:
            for index, (target, old) in enumerate(plan['expected'].items()):
                target = Path(target)
                if old is not None:
                    copy(target, txn / 'backup' / str(index), preserve_owner=True)
                source = plan['changes'][str(target)]
                if source:
                    source = Path(source)
                    if not source.resolve().is_relative_to(Path(plan_file).parent.resolve() / 'payload'):
                        raise ValueError('Asset candidate is outside private staging')
                    if inventory(source) != plan['staged'][str(target)]:
                        raise ValueError('Validated staged assets changed before publication')
                    copy(source, txn / 'new' / str(index))
                    if inventory(source) != plan['staged'][str(target)]:
                        raise ValueError('Staged assets changed during publication')
                    new = txn / 'new' / str(index)
                    for item in [new] + (list(new.rglob('*')) if new.is_dir() else []):
                        item.chmod(0o755 if item.is_dir() else 0o644)
                        original = target / item.relative_to(new) if new.is_dir() else target
                        if original.exists() and (original.is_dir() and item.is_dir() or
                                                  original.is_file() and item.is_file() and
                                                  original.read_bytes() == item.read_bytes()):
                            st = original.stat()
                            item.chmod(stat.S_IMODE(st.st_mode))
                            if os.geteuid() == 0:
                                os.chown(item, st.st_uid, st.st_gid)
            # Protect account avatars by retaining their exact dependency bytes at
            # the existing path. No account selection/AccountsService write occurs.
            if plan['kind'] == 'avatar':
                icons = list(plan.get('icons', []))
                icons.extend(persisted_icons())
                for value in icons:
                    icon = Path(value)
                    for index, target in enumerate(map(Path, plan['expected'])):
                        if (target == icon or target in icon.parents) and icon.is_file():
                            dest = txn / 'new' / str(index)
                            if target != icon:
                                dest = dest / icon.relative_to(target)
                            dest.parent.mkdir(parents=True, exist_ok=True)
                            copy(icon, dest, preserve_owner=True)
                for index, target in enumerate(map(Path, plan['expected'])):
                    new = txn / 'new' / str(index)
                    marker = new / MARKER
                    if marker.is_file():
                        metadata = json.loads(marker.read_text())
                        metadata['files'] = {name: hashlib.sha256((new / name).read_bytes()).hexdigest()
                                             for name in metadata['files'] if (new / name).is_file()}
                        write_json(marker, metadata)
                        marker.chmod(0o644)
                    elif new.is_dir() and plan['changes'][str(target)] is None:
                        write_json(new / DEPENDENCIES, {'files': {
                            str(p.relative_to(new)): hashlib.sha256(p.read_bytes()).hexdigest()
                            for p in new.rglob('*') if p.is_file()}})
                        (new / DEPENDENCIES).chmod(0o644)
            plan['replacement'] = {target: inventory(txn / 'new' / str(index))
                                   for index, target in enumerate(plan['expected'])}
            sync_tree(txn)
            plan['phase'] = 'publishing'
            write_json(txn / 'journal.json', plan)
            for index, target in enumerate(map(Path, plan['expected'])):
                target.parent.mkdir(parents=True, exist_ok=True)
                if target.exists():
                    target.rename(txn / 'retired' / (str(index) + '-' + target.name))
                new = txn / 'new' / str(index)
                if new.exists():
                    new.rename(target)
                fd = os.open(target.parent, os.O_RDONLY | os.O_DIRECTORY)
                try:
                    os.fsync(fd)
                finally:
                    os.close(fd)
            for retired in (txn / 'retired').iterdir():
                run('gio', 'trash', '--', str(retired))
                if retired.exists():
                    raise RuntimeError('Trash reported success without retiring the old collection')
            # Success is durable before discarding private recovery copies.
            plan['phase'] = 'committed'
            write_json(txn / 'journal.json', plan)
        except BaseException:
            recover(txn)
            raise
        try:
            remove_private(txn)
        except OSError as error:
            # Publication/Trash succeeded. Cleanup failure is not a reason to
            # restore settings to retired paths; next run removes this journal.
            print(f'Asset transaction committed; private cleanup retained at {txn}: {error}', file=sys.stderr)


def main(args):
    action = args[0]
    if action == 'snapshot':
        print(snapshot())
    elif action == 'restore':
        restore(args[1])
    elif action == 'relocate':
        relocate(args[1], args[2])
    elif action == 'installed':
        print(installed(args[1], args[2] if len(args) > 2 else None))
    elif action == 'build':
        print(build(*args[1:6], args[7:], args[6] if args[6] != '-' else None))
    elif action == 'apply':
        apply(args[1])
    elif action == 'desktop':
        source = Path(args[1])
        validate_image(source)
        parent = data_home() / 'fedora-mactahoe/installed-backgrounds'
        parent.mkdir(parents=True, exist_ok=True)
        for p in (parent, *parent.parents):
            if p.is_symlink():
                raise ValueError('Symlinked desktop image storage')
        target = parent / (hashlib.sha256(source.read_bytes()).hexdigest() + source.suffix)
        if target.exists() or target.is_symlink():
            if target.is_symlink() or target.read_bytes() != source.read_bytes():
                raise ValueError('Desktop image storage collision')
        else:
            with target.open('xb') as stream, source.open('rb') as original:
                shutil.copyfileobj(original, stream)
        print(target)
    elif action == 'activate':
        try:
            for key in ('picture-uri', 'picture-uri-dark'):
                run('gsettings', 'set', SCHEMA, key, repr(Path(args[2]).as_uri()))
            run('gsettings', 'set', SCHEMA, 'picture-options', 'zoom')
        except BaseException:
            restore(args[1])
            raise
    else:
        raise ValueError('Unknown asset operation')


if __name__ == '__main__':
    def interrupted(signum, frame):
        raise InterruptedError(f'Asset operation interrupted ({signum})')
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    try:
        main(sys.argv[1:])
    except Exception as error:
        print('Asset safety: ' + str(error), file=sys.stderr)
        sys.exit(1)
