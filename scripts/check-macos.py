"""Verifica o aplicativo realmente extraído do ZIP, incluindo sua abertura.

Executar no macOS: python3 scripts/check-macos.py dist/Investir-macOS.zip
O teste de abertura não substitui a notarização ou testes em um Mac físico.
"""
from pathlib import Path
import os
import plistlib
import subprocess
import sys
import tempfile


def check(archive: Path):
    with tempfile.TemporaryDirectory(prefix='investir-package-') as directory:
        subprocess.run(['ditto', '-x', '-k', str(archive), directory], check=True)
        app = Path(directory) / 'Investir.app'
        info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
        binary = app / 'Contents/MacOS' / info['CFBundleExecutable']
        if not os.access(binary, os.X_OK):
            raise RuntimeError('Executável sem permissão de execução no ZIP.')
        subprocess.run(['codesign', '--verify', '--deep', '--strict',
                        '--verbose=2', str(app)], check=True)
        entitlement_xml = subprocess.check_output(
            ['codesign', '-d', '--entitlements', ':-', str(app)])
        entitlements = plistlib.loads(entitlement_xml)
        if 'keychain-access-groups' in entitlements:
            raise RuntimeError('Build local contém Keychain Sharing restrito.')
        macho_magics = {b'\xca\xfe\xba\xbe', b'\xbe\xba\xfe\xca',
                        b'\xcf\xfa\xed\xfe', b'\xfe\xed\xfa\xcf'}
        checked = 0
        for path in (app / 'Contents').rglob('*'):
            if path.is_symlink() or not path.is_file():
                continue
            with path.open('rb') as file:
                magic = file.read(4)
            if magic not in macho_magics:
                continue
            arches = subprocess.check_output(
                ['lipo', '-archs', str(path)], text=True).split()
            if not {'arm64', 'x86_64'} <= set(arches):
                raise RuntimeError(f'Binário sem as duas arquiteturas: {path}')
            checked += 1
        if checked == 0:
            raise RuntimeError('Nenhum binário nativo encontrado.')
        print(f'Assinatura válida; {checked} binários Intel/Apple Silicon; '
              'sem permissão restrita de Keychain Sharing.', flush=True)
        with tempfile.TemporaryFile() as log:
            process = subprocess.Popen([str(binary)], stdout=log,
                                       stderr=subprocess.STDOUT)
            try:
                try:
                    status = process.wait(timeout=20)
                except subprocess.TimeoutExpired:
                    print('Aplicativo extraído abriu e permaneceu ativo por 20s.',
                          flush=True)
                else:
                    log.seek(0)
                    details = log.read().decode('utf-8', errors='replace')
                    raise RuntimeError(
                        f'Aplicativo encerrou ao abrir (status {status}).\n{details}')
            finally:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()


if __name__ == '__main__':
    if sys.platform != 'darwin':
        raise SystemExit('A verificação nativa deve ser executada no macOS.')
    check(Path(sys.argv[1]).resolve(strict=True))
