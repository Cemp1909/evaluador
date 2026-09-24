-- VERSIÓN CORREGIDA: usar si ya se ejecutó la base inicial de 12 tablas.
-- Conserva los datos existentes; no vuelve a crear las tablas.
-- Ejecutar completo, una sola vez, en SQL Editor de Supabase.

begin;

-- 1. Perfil de profesor por defecto
-- Cada usuario nuevo de Supabase Auth recibe un perfil de profesor.
-- El rol no se lee de los metadatos enviados durante el registro.

alter table public.perfiles
  alter column rol set default 'profesor',
  alter column activo set default false;

create or replace function public.crear_perfil_profesor_por_defecto()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.perfiles (id, nombre, rol, activo)
  values (
    new.id,
    coalesce(
      nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(btrim(new.email), ''),
      'Profesor'
    ),
    'profesor',
    false
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function public.crear_perfil_profesor_por_defecto()
  from public, anon, authenticated;

drop trigger if exists al_crear_usuario_asignar_profesor on auth.users;
create trigger al_crear_usuario_asignar_profesor
after insert on auth.users
for each row execute function public.crear_perfil_profesor_por_defecto();

-- Completa perfiles faltantes de cuentas creadas antes de esta migración,
-- sin cambiar los roles que ya se hubieran asignado.
insert into public.perfiles (id, nombre, rol, activo)
select
  usuario.id,
  coalesce(
    nullif(btrim(usuario.raw_user_meta_data ->> 'full_name'), ''),
    nullif(btrim(usuario.email), ''),
    'Profesor'
  ),
  'profesor',
  false
from auth.users as usuario
on conflict (id) do nothing;

-- 2. Lectura del perfil propio
-- Permite a cada usuario autenticado consultar únicamente su perfil.
-- No concede permisos para insertar, actualizar ni cambiar el rol.

grant select on table public.perfiles to authenticated;

drop policy if exists perfil_propio_lectura on public.perfiles;
create policy perfil_propio_lectura
on public.perfiles
for select
to authenticated
using (id = (select auth.uid()));

-- 3. Ciudad, dirección y teléfono de colegios
-- Datos de contacto de la sede principal del colegio.
-- Son opcionales para no invalidar colegios creados antes de esta migración.

alter table public.colegios
  add column if not exists ciudad text,
  add column if not exists direccion text,
  add column if not exists telefono text;

comment on column public.colegios.ciudad is
  'Ciudad o municipio de la sede principal del colegio.';
comment on column public.colegios.direccion is
  'Dirección de la sede principal; puede usarse para abrir el mapa.';
comment on column public.colegios.telefono is
  'Teléfono de contacto como texto para conservar prefijo +57 y extensiones.';

-- 4. Permisos, guardado académico y archivos privados
-- Las funciones SECURITY DEFINER evitan políticas recursivas sobre perfiles.

create or replace function public.rol_actual()
returns text language sql stable security definer set search_path = '' as $$
  select p.rol from public.perfiles p
  where p.id = (select auth.uid()) and p.activo = true
$$;

create or replace function public.zona_actual()
returns text language sql stable security definer set search_path = '' as $$
  select p.zona from public.perfiles p
  where p.id = (select auth.uid()) and p.activo = true
$$;

create or replace function public.puede_ver_colegio(p_colegio uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((select
    public.rol_actual() = 'administrador'
    or (public.rol_actual() = 'coordinador' and c.zona = public.zona_actual())
    or (public.rol_actual() = 'profesor' and exists (
      select 1 from public.visitas_programadas v
      where v.colegio_id = c.id and v.estado <> 'cancelada'
        and (v.responsable_id = (select auth.uid()) or exists (
          select 1 from public.visitas_acompanantes a
          where a.visita_id = v.id and a.perfil_id = (select auth.uid())
        ))
    ))
  from public.colegios c where c.id = p_colegio), false)
$$;

create or replace function public.puede_administrar_colegio(p_colegio uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((select
    public.rol_actual() = 'administrador'
    or (public.rol_actual() = 'coordinador' and c.zona = public.zona_actual())
  from public.colegios c where c.id = p_colegio), false)
$$;

create or replace function public.es_acompanante(p_visita uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.visitas_acompanantes a
    where a.visita_id = p_visita and a.perfil_id = (select auth.uid()))
$$;

revoke all on function public.rol_actual() from public, anon;
revoke all on function public.zona_actual() from public, anon;
revoke all on function public.puede_ver_colegio(uuid) from public, anon;
revoke all on function public.puede_administrar_colegio(uuid) from public, anon;
revoke all on function public.es_acompanante(uuid) from public, anon;
grant execute on function public.rol_actual() to authenticated;
grant execute on function public.zona_actual() to authenticated;
grant execute on function public.puede_ver_colegio(uuid) to authenticated;
grant execute on function public.puede_administrar_colegio(uuid) to authenticated;
grant execute on function public.es_acompanante(uuid) to authenticated;

-- El modelo actual identifica al docente escolar por nombre. Esta función
-- devuelve un identificador estable aun cuando RLS oculte otra asignación.
create unique index if not exists docentes_nombre_unico
  on public.docentes_colegio (lower(btrim(nombre)));
create or replace function public.obtener_o_crear_docente(p_nombre text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  resultado uuid;
  limpio text := btrim(p_nombre);
begin
  if public.rol_actual() not in ('administrador', 'coordinador', 'profesor')
    or limpio = '' then
    raise exception 'No autorizado o nombre vacío';
  end if;
  insert into public.docentes_colegio (nombre) values (limpio)
  on conflict ((lower(btrim(nombre)))) do nothing;
  select id into resultado from public.docentes_colegio
  where lower(btrim(nombre)) = lower(limpio);
  return resultado;
end;
$$;
revoke all on function public.obtener_o_crear_docente(text) from public, anon;
grant execute on function public.obtener_o_crear_docente(text) to authenticated;

create unique index if not exists asignacion_docente_inicio_unico
  on public.asignaciones_docentes (docente_id, colegio_id, nivel, fecha_inicio);

-- Un RPC equivale a una transacción: cierra asignaciones antiguas antes de
-- abrir las nuevas, incluso al transferir un docente entre colegios.
create or replace function public.guardar_asignaciones_academicas(p_datos jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare
  item jsonb;
  docente jsonb;
  colegio uuid;
  persona uuid;
  inicio timestamptz;
  fin timestamptz;
  pasada integer;
  rol text := public.rol_actual();
begin
  if rol not in ('administrador', 'coordinador', 'profesor') or
    jsonb_typeof(p_datos) <> 'array' then
    raise exception 'Operación no autorizada';
  end if;
  for item in select value from jsonb_array_elements(p_datos) loop
    select id into colegio from public.colegios
    where lower(btrim(nombre)) = lower(btrim(item ->> 'nombre'));
    if colegio is null then
      if rol = 'profesor' then
        raise exception 'El profesor no puede crear colegios';
      end if;
      insert into public.colegios (nombre, zona)
      values (btrim(item ->> 'nombre'),
        case when rol = 'coordinador' then public.zona_actual() else null end)
      returning id into colegio;
    elsif not public.puede_ver_colegio(colegio) then
      raise exception 'No tienes acceso a este colegio';
    end if;
  end loop;
  for pasada in 0..1 loop
    for item in select value from jsonb_array_elements(p_datos) loop
      select id into colegio from public.colegios
      where lower(btrim(nombre)) = lower(btrim(item ->> 'nombre'));
      for docente in select value from jsonb_array_elements(item -> 'asignaciones') loop
        inicio := (docente ->> 'fecha_inicio')::timestamptz;
        fin := (docente ->> 'fecha_fin')::timestamptz;
        if (pasada = 0 and fin is null) or (pasada = 1 and fin is not null) then
          continue;
        end if;
        persona := public.obtener_o_crear_docente(docente ->> 'nombre');
        insert into public.asignaciones_docentes
          (docente_id, colegio_id, nivel, fecha_inicio, fecha_fin)
        values (persona, colegio, docente ->> 'nivel', inicio, fin)
        on conflict (docente_id, colegio_id, nivel, fecha_inicio)
        do update set fecha_fin = excluded.fecha_fin;
      end loop;
      colegio := null;
    end loop;
  end loop;
end;
$$;
revoke all on function public.guardar_asignaciones_academicas(jsonb)
  from public, anon;
grant execute on function public.guardar_asignaciones_academicas(jsonb)
  to authenticated;

-- El perfil propio se concedió en 002. Se añaden lecturas limitadas para
-- seleccionar responsables de agenda; nadie puede cambiar su propio rol.
drop policy if exists perfiles_equipo_lectura on public.perfiles;
create policy perfiles_equipo_lectura on public.perfiles for select to authenticated
using (public.rol_actual() = 'administrador'
  or (public.rol_actual() = 'coordinador' and zona = public.zona_actual()));
grant update (nombre, zona, activo, rol) on public.perfiles to authenticated;
drop policy if exists perfiles_admin_actualiza on public.perfiles;
create policy perfiles_admin_actualiza on public.perfiles for update to authenticated
using (public.rol_actual() = 'administrador')
with check (public.rol_actual() = 'administrador');

grant select, insert, update on public.colegios to authenticated;
drop policy if exists colegios_lectura on public.colegios;
create policy colegios_lectura on public.colegios for select to authenticated
using (public.puede_ver_colegio(id));
drop policy if exists colegios_insertar on public.colegios;
create policy colegios_insertar on public.colegios for insert to authenticated
with check (public.rol_actual() = 'administrador'
  or (public.rol_actual() = 'coordinador' and zona = public.zona_actual()));
drop policy if exists colegios_actualizar on public.colegios;
create policy colegios_actualizar on public.colegios for update to authenticated
using (public.puede_administrar_colegio(id))
with check (public.puede_administrar_colegio(id));

grant select, insert on public.docentes_colegio to authenticated;
drop policy if exists docentes_lectura on public.docentes_colegio;
create policy docentes_lectura on public.docentes_colegio for select to authenticated
using (exists (select 1 from public.asignaciones_docentes a
  where a.docente_id = docentes_colegio.id and public.puede_ver_colegio(a.colegio_id)));
drop policy if exists docentes_insertar on public.docentes_colegio;
create policy docentes_insertar on public.docentes_colegio for insert to authenticated
with check (public.rol_actual() in ('administrador', 'coordinador', 'profesor'));

grant select, insert, update on public.asignaciones_docentes to authenticated;
drop policy if exists asignaciones_lectura on public.asignaciones_docentes;
create policy asignaciones_lectura on public.asignaciones_docentes for select to authenticated
using (public.puede_ver_colegio(colegio_id));
drop policy if exists asignaciones_insertar on public.asignaciones_docentes;
create policy asignaciones_insertar on public.asignaciones_docentes for insert to authenticated
with check (public.puede_ver_colegio(colegio_id));
drop policy if exists asignaciones_actualizar on public.asignaciones_docentes;
create policy asignaciones_actualizar on public.asignaciones_docentes for update to authenticated
using (public.puede_ver_colegio(colegio_id))
with check (public.puede_ver_colegio(colegio_id));

grant select, insert, update, delete on public.visitas_programadas to authenticated;
drop policy if exists visitas_lectura on public.visitas_programadas;
create policy visitas_lectura on public.visitas_programadas for select to authenticated
using (public.puede_administrar_colegio(colegio_id)
  or (public.rol_actual() = 'profesor' and
    (responsable_id = (select auth.uid()) or public.es_acompanante(id))));
drop policy if exists visitas_insertar on public.visitas_programadas;
create policy visitas_insertar on public.visitas_programadas for insert to authenticated
with check (public.puede_administrar_colegio(colegio_id));
drop policy if exists visitas_actualizar on public.visitas_programadas;
create policy visitas_actualizar on public.visitas_programadas for update to authenticated
using (public.puede_administrar_colegio(colegio_id)
  or (public.rol_actual() = 'profesor' and responsable_id = (select auth.uid())))
with check (public.puede_administrar_colegio(colegio_id)
  or (public.rol_actual() = 'profesor' and responsable_id = (select auth.uid())));
drop policy if exists visitas_borrar on public.visitas_programadas;
create policy visitas_borrar on public.visitas_programadas for delete to authenticated
using (public.puede_administrar_colegio(colegio_id));

alter table public.visitas_programadas
  add column if not exists responsable_nombre text not null default '';
alter table public.visitas_acompanantes
  add column if not exists nombre text not null default '';

create or replace function public.guardar_visitas_academicas(p_visitas jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare
  item jsonb;
  acompanante jsonb;
  anterior public.visitas_programadas%rowtype;
  colegio uuid;
  responsable uuid;
  perfil uuid;
  nombre_persona text;
  total integer;
  rol text := public.rol_actual();
  anterior_encontrada boolean;
begin
  if rol not in ('administrador', 'coordinador', 'profesor') or
    jsonb_typeof(p_visitas) <> 'array' then
    raise exception 'Operación no autorizada';
  end if;
  for item in select value from jsonb_array_elements(p_visitas) loop
    select * into anterior from public.visitas_programadas
    where id = (item ->> 'id')::uuid;
    anterior_encontrada := found;
    if anterior_encontrada and rol = 'profesor' then
      if (item ->> 'estado') not in ('realizada', 'cancelada') or
        anterior.estado = 'cancelada' or
        ((item ->> 'estado') = 'cancelada' and
          btrim(coalesce(item ->> 'motivo_cancelacion', '')) = '') then
        raise exception 'Estado de visita no permitido para el profesor';
      end if;
      if not (anterior.responsable_id = (select auth.uid())
              or public.es_acompanante(anterior.id)) or
        (item ->> 'fecha')::timestamptz is distinct from anterior.fecha or
        (item ->> 'colegio') is distinct from
          (select c.nombre from public.colegios c where c.id = anterior.colegio_id) or
        (item ->> 'tipo') is distinct from anterior.tipo or
        (item ->> 'numero_clase')::integer is distinct from anterior.numero_clase or
        (item ->> 'periodo')::smallint is distinct from anterior.periodo or
        (item ->> 'profesor_responsable') is distinct from anterior.responsable_nombre or
        (item ->> 'ubicacion') is distinct from anterior.ubicacion or
        (item ->> 'observacion') is distinct from anterior.observacion then
        raise exception 'El profesor solo puede actualizar el estado de su visita';
      end if;
      update public.visitas_programadas set
        estado = item ->> 'estado',
        motivo_cancelacion = coalesce(item ->> 'motivo_cancelacion', ''),
        ultima_novedad = coalesce(item ->> 'ultima_novedad', '')
      where id = anterior.id;
      continue;
    end if;
    if rol = 'profesor' then
      raise exception 'El profesor no puede crear visitas';
    end if;
    select c.id into colegio from public.colegios c
    where lower(btrim(c.nombre)) = lower(btrim(item ->> 'colegio'));
    if colegio is null or not public.puede_administrar_colegio(colegio) then
      raise exception 'Colegio no autorizado';
    end if;
    if anterior_encontrada and anterior.colegio_id is distinct from colegio and
      not public.puede_administrar_colegio(anterior.colegio_id) then
      raise exception 'Visita anterior no autorizada';
    end if;
    nombre_persona := btrim(item ->> 'profesor_responsable');
    select count(*), (array_agg(id))[1] into total, responsable from public.perfiles
    where activo and perfiles.rol = 'profesor'
      and lower(btrim(perfiles.nombre)) = lower(nombre_persona);
    if total <> 1 then
      raise exception 'El responsable debe corresponder a un único perfil activo';
    end if;
    insert into public.visitas_programadas
      (id, colegio_id, fecha, tipo, nivel, numero_clase, periodo, serie_id,
       intervalo_dias, duracion_minutos, responsable_id, responsable_nombre,
       ubicacion, observacion, estado, motivo_cancelacion, ultima_novedad)
    values
      ((item ->> 'id')::uuid, colegio, (item ->> 'fecha')::timestamptz,
       item ->> 'tipo', item ->> 'nivel', (item ->> 'numero_clase')::integer,
       (item ->> 'periodo')::smallint, (item ->> 'serie_id')::uuid,
       (item ->> 'intervalo_dias')::integer,
       (item ->> 'duracion_minutos')::integer, responsable, nombre_persona,
       coalesce(item ->> 'ubicacion', ''), coalesce(item ->> 'observacion', ''),
       item ->> 'estado', coalesce(item ->> 'motivo_cancelacion', ''),
       coalesce(item ->> 'ultima_novedad', ''))
    on conflict (id) do update set
      colegio_id = excluded.colegio_id,
      fecha = excluded.fecha,
      tipo = excluded.tipo,
      nivel = excluded.nivel,
      numero_clase = excluded.numero_clase,
      periodo = excluded.periodo,
      serie_id = excluded.serie_id,
      intervalo_dias = excluded.intervalo_dias,
      duracion_minutos = excluded.duracion_minutos,
      responsable_id = excluded.responsable_id,
      responsable_nombre = excluded.responsable_nombre,
      ubicacion = excluded.ubicacion,
      observacion = excluded.observacion,
      estado = excluded.estado,
      motivo_cancelacion = excluded.motivo_cancelacion,
      ultima_novedad = excluded.ultima_novedad;
    delete from public.visitas_acompanantes where visita_id = (item ->> 'id')::uuid;
    for acompanante in select value from jsonb_array_elements(item -> 'acompanantes') loop
      nombre_persona := btrim(acompanante #>> '{}');
      select count(*), (array_agg(id))[1] into total, perfil from public.perfiles
      where activo and perfiles.rol = 'profesor'
        and lower(btrim(perfiles.nombre)) = lower(nombre_persona);
      if total <> 1 then
        raise exception 'Cada acompañante debe corresponder a un único perfil activo';
      end if;
      insert into public.visitas_acompanantes (visita_id, perfil_id, nombre)
      values ((item ->> 'id')::uuid, perfil, nombre_persona);
    end loop;
    colegio := null;
  end loop;
end;
$$;
revoke all on function public.guardar_visitas_academicas(jsonb)
  from public, anon;
grant execute on function public.guardar_visitas_academicas(jsonb)
  to authenticated;

grant select, insert, delete on public.visitas_acompanantes to authenticated;
drop policy if exists acompanantes_lectura on public.visitas_acompanantes;
create policy acompanantes_lectura on public.visitas_acompanantes for select to authenticated
using (exists (select 1 from public.visitas_programadas v
  where v.id = visita_id and public.puede_ver_colegio(v.colegio_id)));
drop policy if exists acompanantes_insertar on public.visitas_acompanantes;
create policy acompanantes_insertar on public.visitas_acompanantes for insert to authenticated
with check (exists (select 1 from public.visitas_programadas v
  where v.id = visita_id and public.puede_administrar_colegio(v.colegio_id)));
drop policy if exists acompanantes_borrar on public.visitas_acompanantes;
create policy acompanantes_borrar on public.visitas_acompanantes for delete to authenticated
using (exists (select 1 from public.visitas_programadas v
  where v.id = visita_id and public.puede_administrar_colegio(v.colegio_id)));

grant select, insert, update, delete on public.fechas_bloqueadas to authenticated;
drop policy if exists fechas_lectura on public.fechas_bloqueadas;
create policy fechas_lectura on public.fechas_bloqueadas for select to authenticated
using (public.rol_actual() is not null);
drop policy if exists fechas_insertar on public.fechas_bloqueadas;
create policy fechas_insertar on public.fechas_bloqueadas for insert to authenticated
with check (public.rol_actual() in ('administrador', 'coordinador'));
drop policy if exists fechas_actualizar on public.fechas_bloqueadas;
create policy fechas_actualizar on public.fechas_bloqueadas for update to authenticated
using (public.rol_actual() in ('administrador', 'coordinador'))
with check (public.rol_actual() in ('administrador', 'coordinador'));
drop policy if exists fechas_borrar on public.fechas_bloqueadas;
create policy fechas_borrar on public.fechas_bloqueadas for delete to authenticated
using (public.rol_actual() in ('administrador', 'coordinador'));

grant select, insert, update on public.evaluaciones_capacitacion to authenticated;
drop policy if exists evaluaciones_lectura on public.evaluaciones_capacitacion;
create policy evaluaciones_lectura on public.evaluaciones_capacitacion for select to authenticated
using (public.puede_administrar_colegio(colegio_id)
  or responsable_id = (select auth.uid()));
drop policy if exists evaluaciones_insertar on public.evaluaciones_capacitacion;
create policy evaluaciones_insertar on public.evaluaciones_capacitacion for insert to authenticated
with check (public.puede_ver_colegio(colegio_id)
  and (public.puede_administrar_colegio(colegio_id)
    or responsable_id = (select auth.uid())));
drop policy if exists evaluaciones_actualizar on public.evaluaciones_capacitacion;
create policy evaluaciones_actualizar on public.evaluaciones_capacitacion for update to authenticated
using (public.puede_administrar_colegio(colegio_id)
  or responsable_id = (select auth.uid()))
with check (public.puede_administrar_colegio(colegio_id)
  or responsable_id = (select auth.uid()));

grant select, insert, update, delete on public.clases_capacitacion to authenticated;
drop policy if exists clases_lectura on public.clases_capacitacion;
create policy clases_lectura on public.clases_capacitacion for select to authenticated
using (exists (select 1 from public.evaluaciones_capacitacion e
  where e.id = evaluacion_id and public.puede_ver_colegio(e.colegio_id)));
drop policy if exists clases_insertar on public.clases_capacitacion;
create policy clases_insertar on public.clases_capacitacion for insert to authenticated
with check (exists (select 1 from public.evaluaciones_capacitacion e
  where e.id = evaluacion_id and
    (public.puede_administrar_colegio(e.colegio_id)
      or e.responsable_id = (select auth.uid()))));
drop policy if exists clases_actualizar on public.clases_capacitacion;
create policy clases_actualizar on public.clases_capacitacion for update to authenticated
using (exists (select 1 from public.evaluaciones_capacitacion e
  where e.id = evaluacion_id and
    (public.puede_administrar_colegio(e.colegio_id)
      or e.responsable_id = (select auth.uid()))))
with check (exists (select 1 from public.evaluaciones_capacitacion e
  where e.id = evaluacion_id and
    (public.puede_administrar_colegio(e.colegio_id)
      or e.responsable_id = (select auth.uid()))));
drop policy if exists clases_borrar on public.clases_capacitacion;
create policy clases_borrar on public.clases_capacitacion for delete to authenticated
using (exists (select 1 from public.evaluaciones_capacitacion e
  where e.id = evaluacion_id and public.puede_administrar_colegio(e.colegio_id)));

grant select, insert, update, delete on public.asistencias to authenticated;
drop policy if exists asistencias_lectura on public.asistencias;
create policy asistencias_lectura on public.asistencias for select to authenticated
using (exists (select 1 from public.clases_capacitacion c
  join public.evaluaciones_capacitacion e on e.id = c.evaluacion_id
  where c.id = clase_id and public.puede_ver_colegio(e.colegio_id)));
drop policy if exists asistencias_insertar on public.asistencias;
create policy asistencias_insertar on public.asistencias for insert to authenticated
with check (exists (select 1 from public.clases_capacitacion c
  join public.evaluaciones_capacitacion e on e.id = c.evaluacion_id
  where c.id = clase_id and
    (public.puede_administrar_colegio(e.colegio_id)
      or e.responsable_id = (select auth.uid()))));
drop policy if exists asistencias_actualizar on public.asistencias;
create policy asistencias_actualizar on public.asistencias for update to authenticated
using (exists (select 1 from public.clases_capacitacion c
  join public.evaluaciones_capacitacion e on e.id = c.evaluacion_id
  where c.id = clase_id and
    (public.puede_administrar_colegio(e.colegio_id)
      or e.responsable_id = (select auth.uid()))))
with check (exists (select 1 from public.clases_capacitacion c
  join public.evaluaciones_capacitacion e on e.id = c.evaluacion_id
  where c.id = clase_id and
    (public.puede_administrar_colegio(e.colegio_id)
      or e.responsable_id = (select auth.uid()))));
drop policy if exists asistencias_borrar on public.asistencias;
create policy asistencias_borrar on public.asistencias for delete to authenticated
using (exists (select 1 from public.clases_capacitacion c
  join public.evaluaciones_capacitacion e on e.id = c.evaluacion_id
  where c.id = clase_id and
    (public.puede_administrar_colegio(e.colegio_id)
      or e.responsable_id = (select auth.uid()))));

alter table public.reportes_periodo add column if not exists autor_id uuid
  references public.perfiles(id);
alter table public.reportes_periodo
  add column if not exists codigo text,
  add column if not exists firma_coordinador_ruta text,
  add column if not exists nombre_coordinador text;
create unique index if not exists reportes_periodo_codigo_unico
  on public.reportes_periodo (codigo);
grant select, insert, update on public.reportes_periodo to authenticated;
drop policy if exists reportes_lectura on public.reportes_periodo;
create policy reportes_lectura on public.reportes_periodo for select to authenticated
using (public.puede_administrar_colegio(colegio_id)
  or autor_id = (select auth.uid()));
drop policy if exists reportes_insertar on public.reportes_periodo;
create policy reportes_insertar on public.reportes_periodo for insert to authenticated
with check (public.puede_ver_colegio(colegio_id)
  and (public.puede_administrar_colegio(colegio_id)
    or autor_id = (select auth.uid())));
drop policy if exists reportes_actualizar on public.reportes_periodo;
create policy reportes_actualizar on public.reportes_periodo for update to authenticated
using (public.puede_administrar_colegio(colegio_id) or autor_id = (select auth.uid()))
with check (public.puede_administrar_colegio(colegio_id) or autor_id = (select auth.uid()));

grant select, update on public.configuracion_academica to authenticated;
drop policy if exists configuracion_lectura on public.configuracion_academica;
create policy configuracion_lectura on public.configuracion_academica for select to authenticated
using (public.rol_actual() is not null);
drop policy if exists configuracion_actualizar on public.configuracion_academica;
create policy configuracion_actualizar on public.configuracion_academica for update to authenticated
using (public.rol_actual() = 'administrador')
with check (public.rol_actual() = 'administrador');

-- RLS protege filas. Los disparadores protegen campos sensibles dentro de
-- una fila editable por un profesor y evitan asistencia de otro colegio.
create or replace function public.validar_cambio_visita()
returns trigger language plpgsql set search_path = '' as $$
begin
  if public.rol_actual() = 'profesor' and
    row(new.colegio_id, new.fecha, new.tipo, new.nivel, new.numero_clase,
        new.periodo, new.serie_id, new.intervalo_dias, new.duracion_minutos,
        new.responsable_id, new.ubicacion, new.observacion)
    is distinct from
    row(old.colegio_id, old.fecha, old.tipo, old.nivel, old.numero_clase,
        old.periodo, old.serie_id, old.intervalo_dias, old.duracion_minutos,
        old.responsable_id, old.ubicacion, old.observacion) then
    raise exception 'El profesor solo puede actualizar el estado de su visita';
  end if;
  return new;
end;
$$;
revoke all on function public.validar_cambio_visita() from public, anon, authenticated;
drop trigger if exists validar_cambio_visita on public.visitas_programadas;
create trigger validar_cambio_visita before update on public.visitas_programadas
for each row execute function public.validar_cambio_visita();

create or replace function public.validar_reporte_profesor()
returns trigger language plpgsql set search_path = '' as $$
begin
  if public.rol_actual() = 'profesor' then
    if new.aprobado_por is not null or new.aprobado_en is not null or
      new.firma_coordinador_ruta is not null or
      new.nombre_coordinador is not null then
      raise exception 'El profesor no puede aprobar reportes';
    end if;
    if tg_op = 'UPDATE' then
      if old.aprobado_por is not null or old.aprobado_en is not null or
        new.autor_id is distinct from old.autor_id or
        new.colegio_id is distinct from old.colegio_id then
        raise exception 'El profesor no puede modificar un reporte aprobado ni cambiar su propietario';
      end if;
    end if;
  end if;
  return new;
end;
$$;
revoke all on function public.validar_reporte_profesor() from public, anon, authenticated;
drop trigger if exists validar_reporte_profesor on public.reportes_periodo;
create trigger validar_reporte_profesor before insert or update on public.reportes_periodo
for each row execute function public.validar_reporte_profesor();

create or replace function public.validar_evaluacion_profesor()
returns trigger language plpgsql set search_path = '' as $$
begin
  if public.rol_actual() = 'profesor' and
    (new.colegio_id is distinct from old.colegio_id or
     new.responsable_id is distinct from old.responsable_id) then
    raise exception 'El profesor no puede cambiar el colegio ni el responsable';
  end if;
  return new;
end;
$$;
revoke all on function public.validar_evaluacion_profesor() from public, anon, authenticated;
drop trigger if exists validar_evaluacion_profesor on public.evaluaciones_capacitacion;
create trigger validar_evaluacion_profesor
before update on public.evaluaciones_capacitacion
for each row execute function public.validar_evaluacion_profesor();

create or replace function public.validar_asistencia_colegio()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  colegio_clase uuid;
  colegio_docente uuid;
begin
  select e.colegio_id into colegio_clase
  from public.clases_capacitacion c
  join public.evaluaciones_capacitacion e on e.id = c.evaluacion_id
  where c.id = new.clase_id;
  select a.colegio_id into colegio_docente
  from public.asignaciones_docentes a where a.id = new.asignacion_id;
  if colegio_clase is distinct from colegio_docente then
    raise exception 'La asistencia debe corresponder al colegio de la clase';
  end if;
  return new;
end;
$$;
revoke all on function public.validar_asistencia_colegio() from public, anon, authenticated;
drop trigger if exists validar_asistencia_colegio on public.asistencias;
create trigger validar_asistencia_colegio
before insert or update on public.asistencias
for each row execute function public.validar_asistencia_colegio();

create or replace function public.validar_referencias_colegio()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  colegio_padre uuid;
  colegio_referencia uuid;
begin
  if tg_table_name = 'clases_capacitacion' then
    if new.visita_id is null then return new; end if;
    select e.colegio_id into colegio_padre
      from public.evaluaciones_capacitacion e where e.id = new.evaluacion_id;
    select v.colegio_id into colegio_referencia
      from public.visitas_programadas v where v.id = new.visita_id;
  elsif tg_table_name = 'reportes_periodo' then
    if new.asignacion_id is null then return new; end if;
    colegio_padre := new.colegio_id;
    select a.colegio_id into colegio_referencia
      from public.asignaciones_docentes a where a.id = new.asignacion_id;
  else
    return new;
  end if;
  if colegio_padre is distinct from colegio_referencia then
    raise exception 'La referencia pertenece a otro colegio';
  end if;
  return new;
end;
$$;
revoke all on function public.validar_referencias_colegio()
  from public, anon, authenticated;
drop trigger if exists validar_clase_visita on public.clases_capacitacion;
create trigger validar_clase_visita
before insert or update on public.clases_capacitacion
for each row execute function public.validar_referencias_colegio();
drop trigger if exists validar_reporte_asignacion on public.reportes_periodo;
create trigger validar_reporte_asignacion
before insert or update on public.reportes_periodo
for each row execute function public.validar_referencias_colegio();

alter table public.evaluaciones_capacitacion
  add column if not exists fotos_rutas text[] not null default '{}';

-- Una evaluación y todas sus clases/asistencias se confirman juntas.
create or replace function public.guardar_evaluacion_academica(p_evaluacion jsonb)
returns void language plpgsql security invoker set search_path = '' as $$
declare
  clase jsonb;
  asistencia jsonb;
  visita uuid;
  eval_id uuid := (p_evaluacion ->> 'id')::uuid;
  id_clase_actual uuid;
  colegio uuid := (p_evaluacion ->> 'colegio_id')::uuid;
begin
  insert into public.evaluaciones_capacitacion
    (id, colegio_id, nivel, evaluador_tipo, responsable_id, estado,
     fecha_creacion, reemplazos, fotos_rutas)
  values
    (eval_id, colegio, p_evaluacion ->> 'nivel',
     p_evaluacion ->> 'evaluador_tipo',
     (p_evaluacion ->> 'responsable_id')::uuid,
     p_evaluacion ->> 'estado',
     (p_evaluacion ->> 'fecha_creacion')::timestamptz,
     coalesce(p_evaluacion -> 'reemplazos', '[]'::jsonb),
     array(select jsonb_array_elements_text(p_evaluacion -> 'fotos_rutas')))
  on conflict (id) do update set
    estado = excluded.estado,
    reemplazos = excluded.reemplazos,
    fotos_rutas = excluded.fotos_rutas;
  for clase in select value from jsonb_array_elements(p_evaluacion -> 'clases') loop
    id_clase_actual := (clase ->> 'id')::uuid;
    select v.id into visita from public.visitas_programadas v
      where v.colegio_id = colegio
        and v.nivel = (p_evaluacion ->> 'nivel')
        and v.numero_clase = (clase ->> 'numero')::integer
        and v.estado <> 'cancelada';
    insert into public.clases_capacitacion
      (id, evaluacion_id, visita_id, numero, fecha, bloques,
       bloque_canciones_seleccionado, observaciones, firma_docente_ruta,
       firmas_asistentes_rutas)
    values
      (id_clase_actual, eval_id, visita, (clase ->> 'numero')::integer,
       (clase ->> 'fecha')::timestamptz,
       coalesce(clase -> 'bloques', '[]'::jsonb),
       clase ->> 'bloque_canciones_seleccionado',
       coalesce(clase ->> 'observaciones', ''),
       clase ->> 'firma_docente_ruta',
       coalesce(clase -> 'firmas_asistentes_rutas', '[]'::jsonb))
    on conflict (id) do update set
      visita_id = excluded.visita_id,
      fecha = excluded.fecha,
      bloques = excluded.bloques,
      bloque_canciones_seleccionado = excluded.bloque_canciones_seleccionado,
      observaciones = excluded.observaciones,
      firma_docente_ruta = excluded.firma_docente_ruta,
      firmas_asistentes_rutas = excluded.firmas_asistentes_rutas;
    delete from public.asistencias a where a.clase_id = id_clase_actual;
    for asistencia in select value from jsonb_array_elements(clase -> 'asistencias') loop
      insert into public.asistencias
        (clase_id, asignacion_id, asistio, registrado_por)
      values
        (id_clase_actual, (asistencia ->> 'asignacion_id')::uuid,
         (asistencia ->> 'asistio')::boolean, (select auth.uid()));
    end loop;
  end loop;
end;
$$;
revoke all on function public.guardar_evaluacion_academica(jsonb)
  from public, anon;
grant execute on function public.guardar_evaluacion_academica(jsonb)
  to authenticated;

insert into storage.buckets (id, name, public)
values ('academico', 'academico', false)
on conflict (id) do nothing;
drop policy if exists academico_archivos_lectura on storage.objects;
create policy academico_archivos_lectura on storage.objects
for select to authenticated
using (bucket_id = 'academico' and
  (owner_id = (select auth.uid()::text) or
   public.puede_administrar_colegio(((storage.foldername(name))[1])::uuid) or
   exists (select 1 from public.reportes_periodo r where r.autor_id = (select auth.uid())
     and r.firma_coordinador_ruta = storage.objects.name)));

drop policy if exists academico_archivos_insertar on storage.objects;
create policy academico_archivos_insertar on storage.objects
for insert to authenticated
with check (bucket_id = 'academico' and
  (storage.foldername(name))[2] = (select auth.uid()::text) and
  public.puede_ver_colegio(((storage.foldername(name))[1])::uuid));
drop policy if exists academico_archivos_borrar on storage.objects;
create policy academico_archivos_borrar on storage.objects
for delete to authenticated
using (bucket_id = 'academico' and
  (owner_id = (select auth.uid()::text) or
   public.puede_administrar_colegio(((storage.foldername(name))[1])::uuid)));

-- Borrador del reporte: persistencia remota privada por usuario.
create table if not exists public.borradores_reportes (
  autor_id uuid primary key references public.perfiles(id) on delete cascade,
  datos jsonb not null check (jsonb_typeof(datos) = 'object')
);
alter table public.borradores_reportes enable row level security;
revoke all on public.borradores_reportes from anon, authenticated;
grant select, insert, update, delete on public.borradores_reportes to authenticated;
drop policy if exists borrador_propio on public.borradores_reportes;
create policy borrador_propio on public.borradores_reportes
for all to authenticated
using (autor_id = (select auth.uid()) and public.rol_actual() is not null)
with check (autor_id = (select auth.uid()) and public.rol_actual() is not null);

-- Sincronización sin conexión: revisión optimista y recibos de reintentos.
alter table public.evaluaciones_capacitacion add column if not exists revision bigint not null default 1;
alter table public.reportes_periodo add column if not exists revision bigint not null default 1;
alter table public.borradores_reportes add column if not exists revision bigint not null default 1;
alter table public.borradores_reportes add column if not exists eliminado boolean not null default false;

create or replace function public.incrementar_revision_academica()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' then new.revision := 1;
  else new.revision := old.revision + 1; end if;
  return new;
end;
$$;
revoke all on function public.incrementar_revision_academica() from public, anon, authenticated;
drop trigger if exists revision_evaluacion on public.evaluaciones_capacitacion;
create trigger revision_evaluacion before insert or update on public.evaluaciones_capacitacion
for each row execute function public.incrementar_revision_academica();
drop trigger if exists revision_reporte on public.reportes_periodo;
create trigger revision_reporte before insert or update on public.reportes_periodo
for each row execute function public.incrementar_revision_academica();
drop trigger if exists revision_borrador on public.borradores_reportes;
create trigger revision_borrador before insert or update on public.borradores_reportes
for each row execute function public.incrementar_revision_academica();

create or replace function public.revisar_padre_academico()
returns trigger language plpgsql security invoker set search_path = '' as $$
declare padre uuid;
begin
  if tg_table_name = 'clases_capacitacion' then
    if tg_op = 'DELETE' then padre := old.evaluacion_id; else padre := new.evaluacion_id; end if;
  else
    select c.evaluacion_id into padre from public.clases_capacitacion c
    where c.id = case when tg_op = 'DELETE' then old.clase_id else new.clase_id end;
  end if;
  update public.evaluaciones_capacitacion set revision = revision where id = padre;
  return null;
end;
$$;
revoke all on function public.revisar_padre_academico() from public, anon, authenticated;
drop trigger if exists revision_clase_padre on public.clases_capacitacion;
create trigger revision_clase_padre after insert or update or delete on public.clases_capacitacion
for each row execute function public.revisar_padre_academico();
drop trigger if exists revision_asistencia_padre on public.asistencias;
create trigger revision_asistencia_padre after insert or update or delete on public.asistencias
for each row execute function public.revisar_padre_academico();

create table if not exists public.sincronizacion_recibos (
  operacion uuid primary key,
  usuario_id uuid not null references public.perfiles(id) on delete cascade,
  tipo text not null check (tipo in ('evaluacion', 'reporte', 'borrador')),
  recurso text not null,
  revision bigint not null,
  creado_en timestamptz not null default now()
);
alter table public.sincronizacion_recibos enable row level security;
revoke all on public.sincronizacion_recibos from anon, authenticated;
grant select, insert on public.sincronizacion_recibos to authenticated;
drop policy if exists recibos_propios on public.sincronizacion_recibos;
create policy recibos_propios on public.sincronizacion_recibos for all to authenticated
using (usuario_id = (select auth.uid()) and public.rol_actual() is not null)
with check (usuario_id = (select auth.uid()) and public.rol_actual() is not null);

create or replace function public.sincronizar_academico(
  p_operacion uuid, p_tipo text, p_recurso text, p_revision bigint, p_datos jsonb
) returns bigint language plpgsql security invoker set search_path = '' as $$
declare
  actual bigint;
  recibo public.sincronizacion_recibos%rowtype;
  reporte public.reportes_periodo%rowtype;
begin
  if auth.uid() is null or public.rol_actual() is null then raise exception 'Sesión no autorizada'; end if;
  if p_revision < 0 or p_revision is null or p_recurso is null or p_operacion is null
     or jsonb_typeof(p_datos) is distinct from 'object' then raise exception 'Operación inválida'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_tipo || ':' || p_recurso, 0));
  select * into recibo from public.sincronizacion_recibos where operacion = p_operacion;
  if found then
    if recibo.tipo <> p_tipo or recibo.recurso <> p_recurso then raise exception 'Identificador reutilizado'; end if;
    return recibo.revision;
  end if;
  if p_tipo = 'evaluacion' then
    if (p_datos->>'id') is distinct from p_recurso then raise exception 'Identificador inválido'; end if;
    select revision into actual from public.evaluaciones_capacitacion where id = p_recurso::uuid for update;
    if coalesce(actual, 0) <> p_revision then raise exception 'SYNC_CONFLICT'; end if;
    perform public.guardar_evaluacion_academica(p_datos);
    select revision into actual from public.evaluaciones_capacitacion where id = p_recurso::uuid;
  elsif p_tipo = 'reporte' then
    if (p_datos->>'codigo') is distinct from p_recurso then raise exception 'Identificador inválido'; end if;
    select * into reporte from public.reportes_periodo where codigo = p_recurso for update;
    if coalesce(reporte.revision, 0) <> p_revision then raise exception 'SYNC_CONFLICT'; end if;
    if reporte.aprobado_en is not null then raise exception 'El reporte ya está aprobado'; end if;
    insert into public.reportes_periodo (
      codigo, colegio_id, grado, periodo, fecha_hora, nota, puntaje_maximo, datos,
      firma_colegio_ruta, firma_docente_colegio_ruta, firma_course_child_ruta, evidencia_rutas, autor_id
    ) values (
      p_recurso, (p_datos->>'colegio_id')::uuid, p_datos->>'grado', (p_datos->>'periodo')::smallint,
      (p_datos->>'fecha_hora')::timestamptz, (p_datos->>'nota')::numeric,
      (p_datos->>'puntaje_maximo')::numeric, p_datos->'datos', p_datos->>'firma_colegio_ruta',
      p_datos->>'firma_docente_colegio_ruta', p_datos->>'firma_course_child_ruta',
      array(select jsonb_array_elements_text(p_datos->'evidencia_rutas')), auth.uid()
    ) on conflict (codigo) do update set
      grado = excluded.grado, periodo = excluded.periodo, fecha_hora = excluded.fecha_hora,
      nota = excluded.nota, puntaje_maximo = excluded.puntaje_maximo, datos = excluded.datos,
      firma_colegio_ruta = excluded.firma_colegio_ruta,
      firma_docente_colegio_ruta = excluded.firma_docente_colegio_ruta,
      firma_course_child_ruta = excluded.firma_course_child_ruta, evidencia_rutas = excluded.evidencia_rutas
    returning revision into actual;
  elsif p_tipo = 'borrador' then
    if p_recurso <> auth.uid()::text then raise exception 'Borrador ajeno'; end if;
    select revision into actual from public.borradores_reportes where autor_id = auth.uid() for update;
    if coalesce(actual, 0) <> p_revision then raise exception 'SYNC_CONFLICT'; end if;
    insert into public.borradores_reportes (autor_id, datos, eliminado)
    values (auth.uid(), p_datos->'datos', coalesce((p_datos->>'eliminado')::boolean, false))
    on conflict (autor_id) do update set datos = excluded.datos, eliminado = excluded.eliminado
    returning revision into actual;
  else raise exception 'Tipo de operación inválido'; end if;
  if actual is null then raise exception 'El servidor no confirmó el cambio'; end if;
  insert into public.sincronizacion_recibos (operacion, usuario_id, tipo, recurso, revision)
  values (p_operacion, auth.uid(), p_tipo, p_recurso, actual);
  return actual;
end;
$$;
revoke all on function public.sincronizar_academico(uuid,text,text,bigint,jsonb) from public, anon;
grant execute on function public.sincronizar_academico(uuid,text,text,bigint,jsonb) to authenticated;


-- Permite a la app comprobar la compatibilidad antes de aceptar pendientes.
create or replace function public.version_sincronizacion_academica()
returns integer language sql immutable set search_path = '' as $$ select 1 $$;
revoke all on function public.version_sincronizacion_academica() from public, anon;
grant execute on function public.version_sincronizacion_academica() to authenticated;
commit;
