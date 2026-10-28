"""Ícone original do app, gerado com a biblioteca padrão do Python."""
from pathlib import Path
import struct
import zlib
import math

ROOT=Path(__file__).resolve().parents[1]


def png(size):
    raw=bytearray()
    points=[(.22,.65),(.39,.48),(.54,.57),(.77,.30)]
    for y in range(size):
        raw.append(0)
        for x in range(size):
            u=(x+.5)/size;v=(y+.5)/size
            # Fundo arredondado, gráfico em verde e dois eixos discretos.
            dx=max(.18-u,0,u-.82);dy=max(.18-v,0,v-.82)
            alpha=255 if math.hypot(dx,dy)<=.18 else 0
            color=(11,17,27)
            if (.195<u<.215 and .24<v<.78) or (.2<u<.80 and .765<v<.785):color=(57,77,97)
            for (ax,ay),(bx,by) in zip(points,points[1:]):
                k=max(0,min(1,((u-ax)*(bx-ax)+(v-ay)*(by-ay))/((bx-ax)**2+(by-ay)**2)))
                if math.hypot(u-ax-k*(bx-ax),v-ay-k*(by-ay))<.024:color=(116,229,178)
            raw.extend((*color,alpha))
    def chunk(typ,data):return struct.pack('!I',len(data))+typ+data+struct.pack('!I',zlib.crc32(typ+data)&0xffffffff)
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',size,size,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(bytes(raw),9))+chunk(b'IEND',b'')


def generate():
    for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
        p=ROOT/f'android/app/src/main/res/mipmap-{density}/ic_launcher.png';p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(png(size))
    for size in (16,32,64,128,256,512,1024):
        p=ROOT/f'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{size}.png';p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(png(size))


if __name__=='__main__':generate()
