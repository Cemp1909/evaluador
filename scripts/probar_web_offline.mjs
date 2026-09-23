import assert from 'node:assert/strict';
const {chromium} = await import(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const browser = await chromium.launch({
  executablePath: process.env.CHROME_PATH ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  headless: true,
});
try {
  const context = await browser.newContext();
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => {errors.push(error.message); console.log(error.stack);});
  page.on('console', message => {if (message.type() === 'error' || message.type() === 'log') console.log(message.text());});
  await page.goto(process.env.TEST_APP_URL ?? 'http://localhost:8765');
  await page.locator('flutter-view').waitFor({timeout: 60000});
  await page.locator('flt-semantics-placeholder').evaluate(element => element.click());
  await page.getByRole('textbox').first().waitFor({timeout: 15000});
  console.log((await page.locator('body').ariaSnapshot()).slice(0, 4000));
  await page.evaluate(() => navigator.serviceWorker.ready);
  console.log('Service worker preparado');
  await context.setOffline(true);
  await page.reload();
  await page.locator('flutter-view').waitFor({timeout: 30000});
  await page.locator('flt-semantics-placeholder').evaluate(element => element.click());
  await page.getByRole('textbox').first().waitFor({timeout: 15000});
  console.log('OFFLINE', (await page.locator('body').ariaSnapshot()).slice(0, 4000));

  // Auth y REST simulados: nunca crea cuentas ni registros en Supabase real.
  let conectado = true;
  const uid = '00000000-0000-4000-8000-000000000001';
  const perfil = {id: uid, nombre: 'Prueba navegador', rol: 'administrador', activo: true, zona: null};
  await context.route(/^https:\/\/[^/]+\.supabase\.co\//, async route => {
    if (!conectado) { await route.abort('internetdisconnected'); return; }
    const request = route.request();
    const path = new URL(request.url()).pathname;
    const json = body => route.fulfill({status: 200, contentType: 'application/json', body: JSON.stringify(body)});
    const single = (request.headers()['accept'] ?? '').includes('object');
    const rows = data => json(single ? data[0] ?? null : data);
    if (path.endsWith('/token')) {
      const b64 = object => Buffer.from(JSON.stringify(object)).toString('base64url');
      const token = `${b64({alg:'HS256'})}.${b64({sub:uid,exp:Math.floor(Date.now()/1000)+3600})}.test`;
      await json({access_token:token,refresh_token:'refresh-test',token_type:'bearer',expires_in:3600,
        user:{id:uid,aud:'authenticated',email:'prueba@example.test',app_metadata:{},user_metadata:{},created_at:'2026-01-01T00:00:00Z'}});
    } else if (path.endsWith('/perfiles')) await rows([perfil]);
    else if (path.endsWith('/version_sincronizacion_academica')) await json(1);
    else if (path.endsWith('/configuracion_academica')) await rows([{id:true,notas:{},asistencia_minima_profesor:80,evaluacion_periodos_minima_profesor:75}]);
    else await rows([]);
  });
  await context.setOffline(false);
  for (const [name, value] of [['Usuario','prueba'],['Password','prueba']]) {
    const input = page.getByRole('textbox', {name, exact:true});
    await input.click();
    // Flutter conecta el editor nativo en el siguiente frame de foco.
    await page.waitForTimeout(250);
    await input.fill(value);
    await page.waitForTimeout(250);
    assert.equal(await input.inputValue(), value);
  }
  await page.getByRole('button', {name: 'Sign in', exact: true}).click();
  try { await page.getByRole('button', {name:'Sign out', exact:true}).waitFor({timeout:15000}); } catch (error) { console.log(await page.locator('body').ariaSnapshot()); throw error; }
  console.log('Inicio de sesión simulado y copia cifrada: OK');
  conectado = false;
  await context.setOffline(true);
  await page.reload();
  await page.locator('flutter-view').waitFor();
  await page.locator('flt-semantics-placeholder').evaluate(element => element.click());
  try { await page.getByRole('button', {name:'Sign out', exact:true}).waitFor({timeout:15000}); } catch (error) { console.log(await page.locator('body').ariaSnapshot()); throw error; }
  const locks = await page.evaluate(() => navigator.locks.query());
  assert.ok(locks.held.some(lock => lock.name.startsWith('academic-editor-')));
  console.log('Sesión y datos recuperados al reiniciar sin red: OK');
  const second = await context.newPage();
  second.on('pageerror', error => errors.push(error.message));
  await second.goto(process.env.TEST_APP_URL ?? 'http://localhost:8765');
  await second.locator('flutter-view').waitFor();
  await second.locator('flt-semantics-placeholder').evaluate(element => element.click());
  await second.getByRole('textbox', {name:'Usuario'}).waitFor({timeout:15000});
  const secondView = await second.locator('body').ariaSnapshot();
  assert.match(secondView, /otra pestaña/);
  await second.close();
  assert.ok(await page.getByRole('button', {name:'Sign out', exact:true}).isVisible());
  console.log('Segunda pestaña bloqueada sin cerrar la sesión original: OK');
  assert.deepEqual(errors, []);
  console.log('Apertura web sin red: OK, sin errores de página');
  await context.close();
} finally { await browser.close(); }
