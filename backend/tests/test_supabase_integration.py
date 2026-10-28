import asyncio
from unittest.mock import MagicMock
import httpx
import pytest
from fastapi import HTTPException
from app import auth,database


@pytest.mark.parametrize('status,expected',[(401,401),(429,429),(503,503)])
def test_auth_preserves_provider_error_meaning(monkeypatch,status,expected):
    real=httpx.AsyncClient
    transport=httpx.MockTransport(lambda r:httpx.Response(status,json={'error':'provider_message'}))
    monkeypatch.setattr(auth,'configured',lambda:type('S',(),{'supabase_url':'https://project.supabase.co','supabase_anon_key':'test-publishable-key'})())
    monkeypatch.setattr(auth.httpx,'AsyncClient',lambda **kwargs:real(transport=transport,**kwargs))
    with pytest.raises(HTTPException) as exc:asyncio.run(auth.auth_request('user',token='test-token'))
    assert exc.value.status_code==expected


def test_production_checks_schema_without_running_ddl(monkeypatch):
    cfg=MagicMock(app_env='production');conn=MagicMock()
    conn.execute.return_value.all.return_value=[('assets',True),('snapshots',True),('market_cache',True)]
    engine=MagicMock();engine.dialect.name='postgresql';engine.connect.return_value.__enter__.return_value=conn
    session=MagicMock();session.get.return_value=object()
    factory=MagicMock();factory.begin.return_value.__enter__.return_value=session
    monkeypatch.setattr(database,'settings',lambda:cfg)
    monkeypatch.setattr(database,'engine',engine)
    monkeypatch.setattr(database,'SessionLocal',factory)
    create=MagicMock();monkeypatch.setattr(database.Base.metadata,'create_all',create)
    database.initialize()
    create.assert_not_called();engine.begin.assert_not_called()
    assert all(str(call.args[0]).startswith('SELECT ') for call in conn.execute.call_args_list)


def test_production_refuses_schema_without_rls(monkeypatch):
    conn=MagicMock();conn.execute.return_value.all.return_value=[('assets',False),('snapshots',True),('market_cache',True)]
    engine=MagicMock();engine.dialect.name='postgresql';engine.connect.return_value.__enter__.return_value=conn
    monkeypatch.setattr(database,'settings',lambda:MagicMock(app_env='production'))
    monkeypatch.setattr(database,'engine',engine)
    with pytest.raises(RuntimeError,match='RLS'):database.initialize()
