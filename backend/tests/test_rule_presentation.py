from copy import deepcopy
import json

from app.rules import evaluate, present_assessment


def test_legacy_presentation_preserves_classification_and_stored_assessment():
    stored = {
        'status': 'review', 'version': 'legacy',
        'pending_rules': ['Taxa de performance'],
        'rules': [
            {'key': 'Taxa de Performance', 'label': 'Taxa de performance', 'value': '-',
             'status': 'pending', 'source': 'Aula 5.4',
             'expected': 'Papel/passivo: ausente',
             'note': 'Traço ou vazio na planilha não comprova inexistência da taxa.'},
            {'key': 'Quantidade de Imóveis', 'source': 'Pedido do usuário',
             'value': 8, 'status': 'acceptable',
             'expected': 'Usuário: mínimo 8; curso: preferido ≥10', 'note': ''},
        ],
        'notes': ['Conferência documental preservada.'],
    }
    before = deepcopy(stored)
    shown = present_assessment(stored)
    assert stored == before
    assert shown['status'] == stored['status']
    assert shown['pending_rules'] == stored['pending_rules']
    assert shown['rules'][0]['source'] == 'Gestão e taxas'
    assert shown['rules'][0]['status'] == 'pending'
    assert shown['rules'][0]['value'] == '-'
    assert shown['rules'][1]['expected'] == 'Mínimo 8; preferido ≥10'
    assert shown['notes'] == stored['notes']
    text = json.dumps(shown, ensure_ascii=False).lower()
    assert 'aula ' not in text and 'curso:' not in text


def test_new_assessments_have_neutral_explanations(records):
    for kind in ('stocks', 'fiis'):
        for record in records[kind]:
            assessment = evaluate(kind, record['data'])
            text = json.dumps(assessment, ensure_ascii=False).lower()
            assert 'aula ' not in text
            assert 'o curso' not in text
            assert 'o pdf' not in text
            assert 'curso:' not in text
