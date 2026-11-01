param([switch]$SkipStart)
$ErrorActionPreference = 'Stop'
$repository = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Push-Location $repository
try {
    if (@(& git status --porcelain).Count -gt 0) { throw 'Commit all changes before deployment.' }
    $revision = (& git rev-parse HEAD).Trim()
    if ($revision -notmatch '^[0-9a-f]{40}$') { throw 'Invalid Git revision.' }
    $archive = Join-Path ([System.IO.Path]::GetTempPath()) "rallly-$revision.tar"
    & git archive --format=tar -o $archive HEAD
    if ($LASTEXITCODE -ne 0) { throw 'git archive failed.' }
    & scp -O -q -o BatchMode=yes -o ConnectTimeout=12 $archive "nas:/tmp/rallly-$revision.tar"
    if ($LASTEXITCODE -ne 0) { throw 'Source transfer failed.' }
    $bootstrap = @'
import json, pathlib, secrets, shutil, tarfile, urllib.parse
revision = '__REVISION__'
root = pathlib.Path('/volume1/docker/rallly')
private = pathlib.Path('/volume1/@rallly-secrets')
private.mkdir(mode=0o700, exist_ok=True)
private.chmod(0o700)
for name in ('releases', 'source', 'backups'):
    (root / name).mkdir(parents=True, exist_ok=True, mode=0o700 if name == 'backups' else 0o755)
archive = pathlib.Path('/tmp/rallly-' + revision + '.tar')
release = root / 'releases' / revision
release.mkdir(exist_ok=True)
with tarfile.open(archive) as source:
    for member in source.getmembers():
        if not (release / member.name).resolve().is_relative_to(release.resolve()) or not (member.isfile() or member.isdir()):
            raise RuntimeError('Unsafe source archive entry')
    source.extractall(release)
archive.unlink()
if not (private / 'app.env').exists():
    # Credentials from the previously authorized local SMTP setup; never output.
    prior = pathlib.Path('/volume1/@pollaris-secrets/app.env')
    if not prior.exists():
        raise RuntimeError('Prepare the private SMTP configuration before first deployment.')
    old = dict(line.split('=', 1) for line in prior.read_text().splitlines() if '=' in line and not line.startswith('#'))
    smtp = urllib.parse.urlsplit(old['MAILER_DSN'])
    if smtp.scheme != 'smtps':
        raise RuntimeError('Verified SMTPS configuration is required.')
    db_password = secrets.token_hex(32)
    access_key = 'GK' + secrets.token_hex(16)
    storage_secret = secrets.token_hex(32)
    variables = {
        'NODE_ENV': 'production', 'NEXT_PUBLIC_SELF_HOSTED': 'true',
        'NEXT_PUBLIC_BASE_URL': 'https://termine.marek-sommerfeld.de',
        'SECRET_PASSWORD': secrets.token_hex(64),
        'DATABASE_URL': 'postgresql://rallly:' + db_password + '@db:5432/rallly',
        'SUPPORT_EMAIL': old['MAILER_FROM'], 'NOREPLY_EMAIL': old['MAILER_FROM'],
        'NOREPLY_EMAIL_NAME': 'Rallly', 'INITIAL_ADMIN_EMAIL': old['MAILER_FROM'],
        'SMTP_HOST': smtp.hostname, 'SMTP_PORT': str(smtp.port or 465),
        'SMTP_SECURE': 'true', 'SMTP_REJECT_UNAUTHORIZED': 'true',
        'SMTP_USER': urllib.parse.unquote(smtp.username),
        'SMTP_PWD': urllib.parse.unquote(smtp.password),
        'REGISTRATION_ENABLED': 'true', 'EMAIL_LOGIN_ENABLED': 'true',
        'RATE_LIMIT_ENABLED': 'true', 'NEXT_TELEMETRY_DISABLED': '1',
        'S3_ENDPOINT': 'http://garage:3900', 'S3_BUCKET_NAME': 'rallly',
        'S3_REGION': 'garage', 'S3_ACCESS_KEY_ID': access_key,
        'S3_SECRET_ACCESS_KEY': storage_secret,
    }
    assert all('\n' not in value and '\r' not in value for value in variables.values())
    (private / 'app.env').write_text(''.join(key + '=' + value + '\n' for key, value in variables.items()))
    (private / 'postgres.env').write_text('POSTGRES_DB=rallly\nPOSTGRES_USER=rallly\nPOSTGRES_PASSWORD=' + db_password + '\n')
    (private / 'garage.env').write_text('GARAGE_DEFAULT_ACCESS_KEY=' + access_key + '\nGARAGE_DEFAULT_SECRET_KEY=' + storage_secret + '\nGARAGE_DEFAULT_BUCKET=rallly\n')
    (private / 'garage.toml').write_text('metadata_dir = "/var/lib/garage/meta"\ndata_dir = "/var/lib/garage/data"\ndb_engine = "sqlite"\nreplication_factor = 1\nrpc_bind_addr = "[::]:3901"\nrpc_public_addr = "127.0.0.1:3901"\nrpc_secret = "' + secrets.token_hex(32) + '"\n[s3_api]\ns3_region = "garage"\napi_bind_addr = "[::]:3900"\n')
    for name in ('app.env', 'postgres.env', 'garage.env', 'garage.toml'):
        (private / name).chmod(0o600)
current = root / 'current'
if current.is_symlink() and current.resolve() != release:
    previous = root / 'previous'
    if previous.is_symlink(): previous.unlink()
    previous.symlink_to(current.resolve(), target_is_directory=True)
if current.is_symlink(): current.unlink()
if not current.exists(): current.symlink_to(release, target_is_directory=True)
shutil.copyfile(release / 'deploy/nas/compose.yaml', root / 'compose.yaml')
(root / 'release.env').write_text('RALLLY_APP_IMAGE=local/rallly-community:' + revision + '\nRALLLY_APP_VERSION=4.16.4-community.' + revision[:12] + '\n')
source_archive = root / 'source' / ('rallly-' + revision + '.tar.gz')
with tarfile.open(source_archive, 'w:gz') as target:
    target.add(release, arcname='rallly-' + revision)
source_archive.chmod(0o644)
current_source = root / 'source' / 'rallly-current.tar.gz'
if current_source.is_symlink(): current_source.unlink()
if not current_source.exists(): current_source.symlink_to(source_archive.name)
# Check actual runtime secrets against every archived file before publication.
secret_values = [value.encode() for key, value in dict(line.split('=', 1) for line in (private/'app.env').read_text().splitlines() if '=' in line).items() if key in ('SECRET_PASSWORD','SMTP_PWD','S3_SECRET_ACCESS_KEY')]
with tarfile.open(source_archive) as target:
    for member in target.getmembers():
        if member.isfile():
            data = target.extractfile(member).read()
            if any(value and value in data for value in secret_values):
                raise RuntimeError('Runtime secret found in source archive; publication blocked.')
print('Prepared source revision ' + revision + '; secret scan passed.')
'@
    $bootstrap.Replace('__REVISION__', $revision) | & ssh -o BatchMode=yes -o ConnectTimeout=12 nas 'sudo -n python3 -'
    if ($LASTEXITCODE -ne 0) { throw 'Release preparation failed.' }
    & ssh -o BatchMode=yes -o ConnectTimeout=12 nas 'cd /volume1/docker/rallly && sudo -n docker compose --env-file release.env config --quiet && sudo -n docker compose --env-file release.env build app'
    if ($LASTEXITCODE -ne 0) { throw 'Production build failed.' }
    if (-not $SkipStart) {
        & ssh -o BatchMode=yes -o ConnectTimeout=12 nas 'cd /volume1/docker/rallly && sudo -n docker compose --env-file release.env up -d --wait --wait-timeout 240'
        if ($LASTEXITCODE -ne 0) { throw 'Container startup failed.' }
    }
    Remove-Item -LiteralPath $archive
    Write-Output "Deployed Rallly community source revision $revision"
}
finally { Pop-Location }
