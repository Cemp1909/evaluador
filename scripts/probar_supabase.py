"""Pruebas reales. Lee claves localmente; no imprime credenciales ni datos personales.
Sin .env.pruebas: solo disponibilidad y rechazo de acceso anónimo.
Con TEST_EMAIL/TEST_PASSWORD: guarda un borrador temporal, inicia otra sesión,
lo recupera y lo elimina. Requiere una cuenta de prueba sin borrador existente.
"""
import json
import sys
import uuid
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]

def env(path):
    result = {}
    if path.exists():
        for line in path.read_text().splitlines():
            if '=' in line and not line.lstrip().startswith('#'):
                key, value = line.split('=', 1)
                result[key.strip()] = value.strip().strip('\"\'')
    return result

config = env(ROOT / '.env')
account = env(ROOT / '.env.pruebas')
base = config['SUPABASE_URL'].rstrip('/')
key = config['SUPABASE_PUBLISHABLE_KEY']

def request(path, method='GET', data=None, token=None):
    headers = {'apikey': key, 'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = Request(base + path, method=method, headers=headers,
                  data=None if data is None else json.dumps(data).encode())
    try:
        with urlopen(req, timeout=20) as response:
            body = response.read()
            return response.status, json.loads(body) if body else None
    except HTTPError as error:
        try:
            payload = json.loads(error.read())
        except ValueError:
            payload = {}
        return error.code, payload

def check(ok, title):
    print(('PASS ' if ok else 'FAIL ') + title)
    if not ok:
        raise RuntimeError(title)

def login():
    status, body = request('/auth/v1/token?grant_type=password', 'POST', {
        'email': account['TEST_EMAIL'], 'password': account['TEST_PASSWORD']})
    check(status == 200 and 'access_token' in body, 'Inicio de sesión de prueba')
    return body['access_token'], body['user']['id']


def main():
    status, _ = request('/auth/v1/health')
    check(status == 200, 'Conectividad con Supabase Auth')
    for table in ('perfiles', 'colegios', 'reportes_periodo', 'evaluaciones_capacitacion'):
        status, payload = request('/rest/v1/' + table + '?select=*&limit=1')
        check(status in (401, 403) and payload.get('code') == '42501',
              'Acceso anónimo bloqueado: ' + table)
    if not account.get('TEST_EMAIL') or not account.get('TEST_PASSWORD'):
        print('PENDIENTE: escritura y recuperación autenticadas; configura .env.pruebas.')
        return
    token, uid = login()
    status, version = request('/rest/v1/rpc/version_sincronizacion_academica', 'POST', {}, token)
    check(status == 200 and version == 1, 'Migración de sincronización aplicada')
    path = '/rest/v1/borradores_reportes?autor_id=eq.' + uid
    status, rows = request(path, token=token)
    check(status == 200 and rows == [], 'Cuenta de prueba sin borrador previo')
    marker = str(uuid.uuid4())
    inserted = False
    try:
        operacion = {'p_operacion': str(uuid.uuid4()), 'p_tipo': 'borrador',
                     'p_recurso': uid, 'p_revision': 0,
                     'p_datos': {'eliminado': False, 'datos': {'prueba_conexion': marker}}}
        status, revision = request('/rest/v1/rpc/sincronizar_academico', 'POST', operacion, token)
        check(status == 200 and revision == 1, 'Escritura por sincronización del borrador temporal')
        inserted = True
        status, repetida = request('/rest/v1/rpc/sincronizar_academico', 'POST', operacion, token)
        check(status == 200 and repetida == revision, 'Reintento idempotente confirmado')
        conflicto = dict(operacion, p_operacion=str(uuid.uuid4()))
        status, error = request('/rest/v1/rpc/sincronizar_academico', 'POST', conflicto, token)
        check(status >= 400 and 'SYNC_CONFLICT' in error.get('message', ''), 'Revisión antigua rechazada sin sobrescribir')
        new_token, new_uid = login()
        check(new_uid == uid, 'Misma identidad en una nueva sesión')
        status, rows = request(path, token=new_token)
        check(status == 200 and len(rows) == 1 and
              rows[0]['datos'].get('prueba_conexion') == marker,
              'Recuperación real desde una nueva sesión')
    finally:
        if inserted:
            status, _ = request(path, 'DELETE', token=token)
            check(status in (200, 204), 'Limpieza del borrador temporal')
        request('/auth/v1/logout?scope=local', 'POST', token=token)
    print('Prueba real completada; no se modificaron colegios ni evaluaciones.')

if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print('PRUEBA INTERRUMPIDA: ' + type(error).__name__)
        sys.exit(1)
