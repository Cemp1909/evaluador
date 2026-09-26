begin;

create or replace function public.eliminar_usuario_gestionado(p_usuario uuid)
returns void
language plpgsql
security definer set search_path = ''
as $$
declare
  rol_objetivo text;
begin
  if public.rol_actual() <> 'administrador' then
    raise exception 'Solo el administrador puede eliminar usuarios.';
  end if;
  if p_usuario = (select auth.uid()) then
    raise exception 'El administrador no puede eliminar su propia cuenta.';
  end if;

  select p.rol into rol_objetivo
  from public.perfiles p
  where p.id = p_usuario;

  if rol_objetivo is null then
    raise exception 'Usuario no encontrado.';
  end if;
  if rol_objetivo not in ('profesor', 'coordinador') then
    raise exception 'Solo se pueden eliminar profesores y coordinadores.';
  end if;

  update public.visitas_programadas
  set responsable_id = null where responsable_id = p_usuario;
  delete from public.visitas_acompanantes where perfil_id = p_usuario;
  update public.fechas_bloqueadas
  set bloqueada_por = null where bloqueada_por = p_usuario;
  update public.evaluaciones_capacitacion
  set responsable_id = null where responsable_id = p_usuario;
  update public.asistencias
  set registrado_por = null where registrado_por = p_usuario;
  update public.reportes_periodo
  set aprobado_por = null where aprobado_por = p_usuario;
  update public.reportes_periodo
  set autor_id = null where autor_id = p_usuario;
  update public.configuracion_academica
  set actualizado_por = null where actualizado_por = p_usuario;

  delete from auth.users where id = p_usuario;
end;
$$;

revoke all on function public.eliminar_usuario_gestionado(uuid)
from public, anon;
grant execute on function public.eliminar_usuario_gestionado(uuid)
to authenticated;

commit;
