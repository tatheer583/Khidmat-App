import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { createClient } from '@supabase/supabase-js';

// Deliberately refuses production: these accounts and files belong only in a
// disposable local Supabase stack, which CI destroys after the run.
const config = JSON.parse(await readFile(process.argv[2], 'utf8'));
const url = config.API_URL;
assert(['localhost', '127.0.0.1'].includes(new URL(url).hostname), 'Local Supabase only');
const options = { auth: { persistSession: false, autoRefreshToken: false } };
const admin = createClient(url, config.SERVICE_ROLE_KEY, options);
const anonymous = createClient(url, config.ANON_KEY, options);
const clients = [admin, anonymous];
let passed = 0;
function check(value, message) { assert.ok(value, message); console.log('PASS: ' + message); passed++; }
async function data(request, label) {
  const result = await request;
  if (result.error) throw new Error(label + ': ' + result.error.message);
  return result.data;
}
async function account(role) {
  const email = role + '-' + randomUUID() + '@example.test';
  const password = randomUUID() + 'Aa!3';
  const { user } = await data(admin.auth.admin.createUser({
    email, password, email_confirm: true, user_metadata: { full_name: role },
  }), 'create local account');
  const client = createClient(url, config.ANON_KEY, options);
  clients.push(client);
  await data(client.auth.signInWithPassword({ email, password }), 'password login');
  await data(client.rpc('complete_profile', {
    p_full_name: 'Test ' + role, p_role: role === 'worker' ? 'worker' : 'customer',
    p_city: 'Islamabad', p_location: 'House 12, G-13', p_profession: 'Plumber',
    p_experience_years: 5, p_bio: 'Plumbing repairs and installation',
  }), 'profile onboarding');
  return { user, client };
}
async function nextChange(client, table, filter, event = 'INSERT') {
  let resolveChange, rejectChange;
  const result = new Promise((resolve, reject) => { resolveChange = resolve; rejectChange = reject; });
  // Attach immediately so a subscription timeout cannot become unhandled.
  result.catch(() => {});
  let timer;
  const channel = client.channel('test-' + randomUUID(), {
    config: { postgres_changes_options: { wait: true } },
  }).on('system', {}, payload => {
    console.log('Realtime ' + table + ': ' + payload.status + ' / ' + payload.message);
  }).on('postgres_changes', {
    event, schema: 'public', table, filter,
  }, payload => { clearTimeout(timer); resolveChange(payload.new); });
  await new Promise((resolve, reject) => {
    const startup = setTimeout(() => reject(new Error('Realtime readiness timed out: ' + table)), 25000);
    channel.subscribe(status => {
      if (status === 'SUBSCRIBED') { clearTimeout(startup); resolve(); }
      if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT' || status === 'CLOSED') {
        clearTimeout(startup); reject(new Error('Realtime subscription failed: ' + table));
      }
    });
  });
  timer = setTimeout(() => rejectChange(new Error('Realtime delivery timed out: ' + table)), 20000);
  return { result, channel };
}

try {
  const health = await data(anonymous.rpc('app_health'), 'public health');
  check(health.ready && health.schema_version === 3, 'Public health reports installed services');
  const customer = await account('customer');
  const worker = await account('worker');
  const outsider = await account('outsider');
  const own = await data(customer.client.from('profiles').select(), 'private profiles');
  check(own.length === 1 && own[0].id === customer.user.id, 'Authenticated HTTP reads respect profile privacy');
  const listing = await data(worker.client.from('providers').insert({
    user_id: worker.user.id, name: 'Local Test Worker', category: 'Plumber',
    city: 'Islamabad', location: 'G-13', price_min: 1200, price_max: 1500,
    available_slots: ['09:00', '12:00'], description: 'Plumbing repairs',
  }).select().single(), 'listing creation');
  check((await data(customer.client.from('providers').select().eq('id', listing.id),
    'hidden listing')).length === 0, 'Unapproved listings stay hidden');
  await data(admin.from('providers').update({ is_approved: true }).eq('id', listing.id), 'operator approval');

  const day = new Date(Date.now() + 86400000).toISOString().slice(0, 10);
  const quote = await data(customer.client.rpc('quote_provider', { p_provider_id: listing.id }), 'server quote');
  check(quote.final_price === 1200, 'Server uses the authorized rate');
  const incoming = await nextChange(worker.client, 'bookings', 'provider_user_id=eq.' + worker.user.id);
  const params = { p_quote_id: quote.id, p_date: day, p_slot: '09:00',
    p_location: 'House 12, G-13, Islamabad', p_notes: 'Leaking pipe' };
  const booking = await data(customer.client.rpc('create_booking', params), 'booking');
  check((await incoming.result).id === booking.id, 'Worker receives booking over a real Realtime WebSocket');
  await worker.client.removeChannel(incoming.channel);
  check((await data(customer.client.rpc('create_booking', params), 'retry')).id === booking.id,
    'Retrying the same booking returns its original ID');
  const slots = await data(customer.client.rpc('available_slots', { p_provider_id: listing.id, p_date: day }), 'slots');
  check(slots.length === 1 && slots[0] === '12:00', 'HTTP availability excludes the reservation');
  check((await data(outsider.client.from('bookings').select(), 'outsider bookings')).length === 0,
    'An unrelated account cannot read bookings');

  const messageChange = await nextChange(worker.client, 'messages', 'booking_id=eq.' + booking.id);
  await data(customer.client.from('messages').insert({
    booking_id: booking.id, sender_id: customer.user.id, body: 'Please fix the pipe',
  }), 'chat send');
  check((await messageChange.result).body === 'Please fix the pipe', 'Private chat is delivered in realtime');
  await worker.client.removeChannel(messageChange.channel);
  const intrusion = await outsider.client.from('messages').insert({
    booking_id: booking.id, sender_id: outsider.user.id, body: 'Not a participant',
  });
  check(Boolean(intrusion.error), 'Private chat rejects an outsider');

  const image = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aTr8AAAAASUVORK5CYII=', 'base64');
  const path = booking.id + '/' + customer.user.id + '/test.png';
  await data(customer.client.storage.from('booking-media').upload(path, image, { contentType: 'image/png' }), 'photo upload');
  const photo = await data(worker.client.storage.from('booking-media').download(path), 'photo download');
  check(Buffer.from(await photo.arrayBuffer()).equals(image), 'Participant downloads the exact uploaded photo');
  const privatePhoto = await outsider.client.storage.from('booking-media').download(path);
  check(Boolean(privatePhoto.error), 'Storage HTTP rejects an unrelated account');
  const signed = await data(worker.client.storage.from('booking-media').createSignedUrl(path, 60), 'signed photo URL');
  check((await fetch(signed.signedUrl)).ok, 'Private images load through signed URLs');

  const changed = await nextChange(customer.client, 'bookings', 'id=eq.' + booking.id, 'UPDATE');
  await data(worker.client.rpc('transition_booking', { p_booking_id: booking.id, p_status: 'accepted' }), 'accept');
  check((await changed.result).status === 'accepted', 'Customer receives job status in realtime');
  await customer.client.removeChannel(changed.channel);
  for (const status of ['in_progress', 'completed']) {
    await data(worker.client.rpc('transition_booking', { p_booking_id: booking.id, p_status: status }), 'job progress');
  }
  await data(customer.client.from('reviews').insert({
    booking_id: booking.id, customer_id: customer.user.id, provider_id: listing.id, stars: 5,
  }), 'review');
  const reviewed = await data(customer.client.from('providers').select().eq('id', listing.id).single(), 'metrics');
  check(reviewed.completed_jobs === 1 && reviewed.review_count === 1 && reviewed.rating === 5,
    'Completed jobs and verified reviews update the provider metrics');
  const refreshed = await data(customer.client.auth.refreshSession(), 'session refresh');
  check(Boolean(refreshed.session), 'Authenticated session refresh works');
  await data(customer.client.auth.signOut(), 'sign out');
  check(!(await customer.client.auth.getSession()).data.session, 'Sign out clears the session');
  console.log('Passed ' + passed + ' real Auth, REST, Storage and Realtime checks.');
} finally {
  await Promise.all(clients.map(client => client.removeAllChannels()));
}
