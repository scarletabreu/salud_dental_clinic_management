-- ============================================================================
--  Overlay de login para el E2E de navegador.
--
--  El seed de certificación crea a los tres actores con correo `@cert.local`,
--  que es correcto para las jornadas por REST: allí se autentica contra GoTrue
--  con el correo literal.
--
--  La pantalla de login, en cambio, no pide correo sino usuario, y deriva el
--  correo con un dominio fijo:
--
--      usuario_repository_impl.dart:50 → '$username@saluddental.com'
--
--  Así que los actores de certificación son inalcanzables desde la interfaz.
--  Este overlay reescribe su correo a `<username>@saluddental.com`, que es
--  exactamente lo que la app compone al enviar el formulario.
--
--  Es seguro hacerlo después del alta: `handle_new_user` no copia el correo a
--  ninguna tabla de `public` —vive sólo en `auth.users`—, de modo que no hay
--  nada que quede desincronizado. Se actualiza también `auth.identities`,
--  donde GoTrue guarda su propia copia dentro de `identity_data`.
--
--  Sólo para el stack local. No tiene ningún sentido en una instancia remota.
--    psql "$DB_URL" -f supabase/tests/e2e_ui_login_overlay.sql
-- ============================================================================

do $overlay$
declare
  v_afectados int;
begin
  update auth.users u
     set email = usr.username || '@saluddental.com',
         updated_at = now()
    from public.usuarios usr
   where usr.id = u.id
     and u.email like '%@cert.local';

  get diagnostics v_afectados = row_count;

  update auth.identities i
     set identity_data = jsonb_set(
           i.identity_data, '{email}', to_jsonb(u.email), true
         ),
         updated_at = now()
    from auth.users u
   where u.id = i.user_id
     and u.email like '%@saluddental.com';

  raise notice 'E2E overlay: % actores alcanzables desde el login.', v_afectados;
end;
$overlay$;

select username, u.email
  from public.usuarios usr
  join auth.users u on u.id = usr.id
 order by username;
