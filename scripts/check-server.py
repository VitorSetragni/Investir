#!/usr/bin/env python3
"""Verificação pública da API publicada, sem escrita e sem credenciais."""
import argparse
import json
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlsplit
from urllib.request import Request, urlopen


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('api_url', help='URL HTTPS do FastAPI publicado')
    args = parser.parse_args()
    base = args.api_url.strip().rstrip('/')
    uri = urlsplit(base)
    if (uri.scheme != 'https' or not uri.netloc or uri.username or
            uri.password or uri.query or uri.fragment):
        parser.error('Use uma URL HTTPS sem credenciais, parâmetros ou fragmentos.')

    def get(path):
        request = Request(base + path, headers={'Accept': 'application/json'})
        with urlopen(request, timeout=120) as response:
            if urlsplit(response.url).scheme != 'https':
                raise ValueError('O servidor redirecionou para uma conexão sem HTTPS.')
            return json.load(response)

    try:
        health = get('/health')
        if health.get('status') != 'ok':
            raise ValueError('A verificação de saúde não respondeu status ok.')
        catalog = get('/api/catalog')
        if catalog.get('demo') is not False:
            raise ValueError('A API está em modo demonstração ou não informou o modo.')
        snapshots = {item['kind']: item for item in catalog['snapshots']}
        if set(snapshots) != {'stocks', 'fiis'}:
            raise ValueError('O catálogo não informou as duas competências.')
        assets = catalog['assets']
        if not assets:
            raise ValueError('O catálogo está vazio.')
        if len({a['ticker'] for a in assets}) != len(assets):
            raise ValueError('O catálogo contém tickers duplicados.')
        if any(a['kind'] not in snapshots for a in assets):
            raise ValueError('O catálogo contém um tipo de ativo desconhecido.')
        for kind, snapshot in snapshots.items():
            count = sum(a['kind'] == kind for a in assets)
            if count != snapshot['count']:
                raise ValueError(f'Contagem divergente para {kind}.')
            print(f"{kind}: {count} ativos, base {snapshot['reference']}")
        ticker = assets[0]['ticker']
        detail = get('/api/assets/' + quote(ticker, safe=''))
        if detail.get('ticker') != ticker or not detail.get('assessment'):
            raise ValueError('O detalhe do ativo está incompleto.')
        print(f'OK: saúde, catálogo público e detalhe de {ticker}.')
        print('Login, importação e instalação ainda exigem verificação própria.')
        return 0
    except (HTTPError, URLError, TimeoutError, ValueError, KeyError, TypeError) as error:
        # Não imprimir URL de conexão ou resposta bruta que possa conter credenciais.
        print(f'Falha na verificação ({type(error).__name__}). Confira a API e seus logs.', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
