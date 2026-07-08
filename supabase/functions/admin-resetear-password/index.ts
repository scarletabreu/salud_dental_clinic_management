import { createClient } from 'jsr:@supabase/supabase-js@2';

Deno.serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const callerClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user: caller } } = await callerClient.auth.getUser();
    if (!caller) {
      return new Response(JSON.stringify({ error: 'No autenticado' }), { status: 401 });
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: esAdmin } = await admin
      .from('admins')
      .select('id')
      .eq('id', caller.id)
      .maybeSingle();
    if (!esAdmin) {
      return new Response(JSON.stringify({ error: 'No autorizado' }), { status: 403 });
    }

    const { targetUuid, nuevaPassword } = await req.json();
    if (!targetUuid || !nuevaPassword || nuevaPassword.length < 6) {
      return new Response(JSON.stringify({ error: 'Datos inválidos' }), { status: 400 });
    }

    const { error } = await admin.auth.admin.updateUserById(targetUuid, {
      password: nuevaPassword,
    });
    if (error) throw error;

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 400 });
  }
});