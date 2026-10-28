"""Gera projetos nativos usando o SDK Flutter instalado, sem sobrescrever Dart.

Executar: python3 tool/bootstrap.py (a partir de frontend).
"""
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]


def main():
    if not shutil.which('flutter'):raise SystemExit('Instale o Flutter 3.38.5 ou posterior e adicione flutter/bin ao PATH.')
    markers={'android':'android/app/build.gradle.kts','macos':'macos/Runner.xcodeproj/project.pbxproj'}
    missing=[x for x in ('android','macos') if not (ROOT/markers[x]).exists()]
    if missing:
        with tempfile.TemporaryDirectory(prefix='investir-native-') as temp:
            generated=Path(temp)/'investir'
            subprocess.run(['flutter','create','--no-pub','--platforms=android,macos','--org=br.com.vitorsetragni','--project-name=investir',str(generated)],check=True)
            for platform in missing:shutil.copytree(generated/platform,ROOT/platform,dirs_exist_ok=True)
    manifest=ROOT/'android/app/src/main/AndroidManifest.xml'
    text=manifest.read_text().replace('android:label="investir"','android:label="Investir"')
    if 'android.permission.INTERNET' not in text:text=text.replace('<application','<uses-permission android:name="android.permission.INTERNET"/>\n    <application',1)
    if 'android:usesCleartextTraffic' not in text:text=text.replace('<application','<application android:usesCleartextTraffic="false"',1)
    if 'android:allowBackup' not in text:text=text.replace('<application','<application android:allowBackup="false"',1)
    manifest.write_text(text)
    gradle=ROOT/'android/app/build.gradle.kts'
    text=gradle.read_text().replace('compileSdk = flutter.compileSdkVersion','compileSdk = 36').replace('targetSdk = flutter.targetSdkVersion','targetSdk = 36').replace('minSdk = flutter.minSdkVersion','minSdk = 23').replace('ndkVersion = flutter.ndkVersion','ndkVersion = "28.2.13676358"')
    if 'useLegacyPackaging' not in text:text=text.replace('android {','android {\n    packaging { jniLibs { useLegacyPackaging = false } }',1)
    # Se houver chave persistente, usa-a. Sem ela, Flutter mantém assinatura de teste.
    if 'investirSigning' not in text:
        text='import java.util.Properties\n'+text
        block='''
val investirSigning = Properties()
val investirKeyFile = rootProject.file("key.properties")
if (investirKeyFile.exists()) investirKeyFile.inputStream().use { investirSigning.load(it) }
'''
        end=text.index('\nandroid {');text=text[:end]+'\n'+block+text[end:]
        signing='''
    signingConfigs {
        if (investirKeyFile.exists()) create("investirRelease") {
            keyAlias = investirSigning.getProperty("keyAlias")
            keyPassword = investirSigning.getProperty("keyPassword")
            storeFile = file(investirSigning.getProperty("storeFile"))
            storePassword = investirSigning.getProperty("storePassword")
        }
    }
'''
        text=text.replace('    buildTypes {',signing+'\n    buildTypes {',1)
        text=text.replace('signingConfig = signingConfigs.getByName("debug")','signingConfig = signingConfigs.getByName(if (investirKeyFile.exists()) "investirRelease" else "debug")')
    gradle.write_text(text)
    for filename in ('DebugProfile.entitlements','Release.entitlements'):
        path=ROOT/'macos/Runner'/filename
        with path.open('rb') as file:ent=plistlib.load(file)
        ent.update({'com.apple.security.network.client':True,'com.apple.security.files.user-selected.read-only':True,'keychain-access-groups':['$(AppIdentifierPrefix)br.com.vitorsetragni.investir']})
        with path.open('wb') as file:plistlib.dump(ent,file)
    config=ROOT/'macos/Runner/Configs/AppInfo.xcconfig'
    config.write_text(config.read_text().replace('PRODUCT_NAME = investir','PRODUCT_NAME = Investir'))
    from icons import generate
    generate()
    print('Android e macOS preparados. Execute flutter pub get, flutter analyze e flutter test.')


if __name__=='__main__':main()
