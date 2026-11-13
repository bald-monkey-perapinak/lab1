"""Execute Lab 1 in its own Debian guest and download actual evidence."""
from pathlib import Path
import argparse
import json
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent.parent / 'лабы сети' / '.deps'))
import paramiko

parser = argparse.ArgumentParser()
parser.add_argument('--probe', action='store_true')
args = parser.parse_args()
known = ROOT / 'vm-runtime' / 'known_hosts'
known.touch(exist_ok=True)
client = paramiko.SSHClient()
client.load_host_keys(str(known))
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('127.0.0.1', port=2221, username='labadmin',
               key_filename=str(ROOT / 'vm-runtime' / '.secrets' / 'avs-lab1' / 'admin_key'),
               look_for_keys=False, allow_agent=False,
               timeout=3, banner_timeout=3, auth_timeout=5)

def execute(script, timeout=180):
    stdin, stdout, stderr = client.exec_command('bash -s', timeout=timeout)
    stdin.write(script + '\n')
    stdin.channel.shutdown_write()
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    return {'exit_code': stdout.channel.recv_exit_status(), 'stdout': out, 'stderr': err}

try:
    probe = execute('set -eu\ncat /etc/os-release\nid\ngit --version\nlocale\ndate --iso-8601=seconds')
    if args.probe:
        print(json.dumps(probe, ensure_ascii=True))
        raise SystemExit(probe['exit_code'])
    if probe['exit_code']:
        raise RuntimeError('Debian environment probe failed')
    output = ROOT / 'evidence' / 'debian-vm'
    if output.exists():
        raise RuntimeError('Evidence directory already exists; refusing to overwrite')
    remote = '/home/labadmin/avs_lab1'
    setup = execute(f'set -eu\ntest ! -e {remote}\nmkdir -p {remote}/scripts')
    if setup['exit_code']:
        raise RuntimeError('Remote source directory exists or cannot be created')
    output.mkdir()
    (output / 'environment.json').write_text(json.dumps(probe, ensure_ascii=False, indent=2), encoding='utf-8')
    sftp = client.open_sftp()
    try:
        for path in ['README.md', 'run.sh', 'verify.sh', 'scripts/01_create.sh',
                     'scripts/02_copy.sh', 'scripts/03_search.sh', 'scripts/04_remove.sh']:
            sftp.put(str(ROOT / path), f'{remote}/{path}')
        result = execute(f'set -euo pipefail\ncd {remote}\nchmod +x run.sh verify.sh scripts/*.sh\n./run.sh')
        (output / 'run.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
        for entry in sftp.listdir_attr(remote + '/evidence'):
            sftp.get(remote + '/evidence/' + entry.filename, str(output / entry.filename))
        if result['exit_code']:
            raise RuntimeError('Execution failed; real logs downloaded')
        packed = execute('set -eu\ntar -czf /home/labadmin/lab1-result.tar.gz -C /home/labadmin lab0')
        if packed['exit_code']:
            raise RuntimeError('Could not archive live filesystem and Git repository')
        sftp.get('/home/labadmin/lab1-result.tar.gz', str(output / 'lab1-result.tar.gz'))
        print('PASS: all Lab 1 stages executed and checked on Debian; logs and Git repository downloaded.')
    finally:
        sftp.close()
finally:
    client.close()
