import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
const {PGlite} = await import(process.env.PGLITE_MODULE ?? '@electric-sql/pglite');
import {readFileSync} from 'node:fs';
const db = new PGlite();
const root = new URL('../', import.meta.url).pathname;
try {
await db.exec(`create role anon; create role authenticated;
create schema auth; create schema storage;
create table auth.users(id uuid primary key, raw_user_meta_data jsonb default '{}', email text);
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
grant usage on schema auth, storage to authenticated, anon;
grant execute on function auth.uid() to authenticated, anon;
create table storage.buckets(id text primary key,name text,public boolean);
create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text,owner_id text);
alter table storage.objects enable row level security;
create function storage.foldername(text) returns text[] language sql immutable as $$ select string_to_array($1,'/') $$;
`);
await db.exec(readFileSync(root+'supabase/instalacion_completa.sql','utf8'));
console.log('Instalación completa: OK');
await db.exec(readFileSync(root+'supabase/actualizar_base_existente.sql','utf8'));
await db.exec(readFileSync(root+'supabase/actualizar_base_existente.sql','utf8'));
console.log('Actualización repetida dos veces: OK');

const admin=randomUUID(), prof=randomUUID(), other=randomUUID(), school=randomUUID();
await db.query(`insert into auth.users(id,email) values ($1,'admin@test'),($2,'prof@test'),($3,'otro@test')`,[admin,prof,other]);
await db.query(`update public.perfiles set rol='administrador' where id=$1`,[admin]);
await db.query(`insert into public.colegios(id,nombre) values ($1,'Pruebas')`,[school]);
await db.query(`insert into public.visitas_programadas(colegio_id,fecha,tipo,nivel,numero_clase,responsable_id) values ($1,now(),'Preescolar','preescolar',1,$2)`,[school,prof]);
async function usuario(uid) {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[uid]);
  await db.exec('set role authenticated');
}
async function sync(id,tipo,recurso,revision,datos) {
  return (await db.query('select public.sincronizar_academico($1,$2,$3,$4,$5) as revision',[id,tipo,recurso,revision,datos])).rows[0].revision;
}
await usuario(prof);
const op=randomUUID();
assert.equal(await sync(op,'borrador',prof,0,{datos:{compromiso:'Original'}}),1);
assert.equal(await sync(op,'borrador',prof,0,{datos:{compromiso:'Original'}}),1);
assert.equal((await db.query('select count(*)::int n from public.sincronizacion_recibos')).rows[0].n,1);
await assert.rejects(()=>sync(randomUUID(),'borrador',prof,0,{datos:{}}),/SYNC_CONFLICT/);
assert.equal(await sync(randomUUID(),'borrador',prof,1,{eliminado:true,datos:{}}),2);
assert.equal(await sync(randomUUID(),'borrador',prof,2,{eliminado:false,datos:{compromiso:'Nuevo'}}),3);
await assert.rejects(()=>sync(randomUUID(),'borrador',other,0,{datos:{}}),/Borrador ajeno/);
console.log('Borradores: idempotencia, conflicto, borrado lógico y aislamiento: OK');
const eid=randomUUID(), cid=randomUUID();
const evaluation={id:eid,colegio_id:school,nivel:'preescolar',evaluador_tipo:'Preescolar',responsable_id:prof,estado:'borrador',fecha_creacion:new Date().toISOString(),fotos_rutas:[],reemplazos:[],clases:[{id:cid,numero:1,bloques:[],asistencias:[]}]};
let rev=await sync(randomUUID(),'evaluacion',eid,0,evaluation);
assert.ok(rev>1);
await db.query("update public.clases_capacitacion set observaciones='Desde otro dispositivo' where id=$1",[cid]);
await assert.rejects(()=>sync(randomUUID(),'evaluacion',eid,rev,evaluation),/SYNC_CONFLICT/);
assert.equal((await db.query('select observaciones from public.clases_capacitacion where id=$1',[cid])).rows[0].observaciones,'Desde otro dispositivo');
console.log('Evaluaciones: los cambios directos de clase invalidan la revisión: OK');
const report={codigo:'reporte-test',colegio_id:school,grado:'Preescolar',periodo:1,fecha_hora:new Date().toISOString(),nota:4,puntaje_maximo:5,datos:{compromiso:'Prueba'},evidencia_rutas:[]};
assert.equal(await sync(randomUUID(),'reporte',report.codigo,0,report),1);
assert.equal(await sync(randomUUID(),'reporte',report.codigo,1,{...report,datos:{compromiso:'Editado'}}),2);
const intentoConfiguracion = await db.query("update public.configuracion_academica set asistencia_minima_profesor=1 returning *");
assert.equal(intentoConfiguracion.rows.length,0);
assert.equal((await db.query('select asistencia_minima_profesor from public.configuracion_academica')).rows[0].asistencia_minima_profesor,80);
await usuario(admin);
await db.query("update public.reportes_periodo set aprobado_por=$1, aprobado_en=now() where codigo=$2",[admin,report.codigo]);
await assert.rejects(()=>sync(randomUUID(),'reporte',report.codigo,3,report),/aprobado/);
await usuario(other);
assert.equal((await db.query('select * from public.borradores_reportes')).rows.length,0);
await assert.rejects(()=>sync(randomUUID(),'evaluacion',eid,0,evaluation),/row-level|policy|permiso/i);
await db.exec('reset role; set role anon');
await assert.rejects(()=>db.query('select * from public.sincronizacion_recibos'),/permission denied/);
console.log('Reportes, aprobación, permisos de profesor y acceso anónimo: OK');
} catch(e) {console.error(e.message, e.detail ?? '', e.where ?? '');process.exitCode=1;}
await db.close();
