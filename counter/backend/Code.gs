/**
 * Pillow Blower Counter - Google Apps Script backend.
 *
 * Bound to the Google Sheet that stores the data. Deploy as a Web App
 * (execute as me, access: anyone). The CYD devices POST events here; the
 * same URL serves the wall dashboard (GET) and the device config
 * (GET ?action=config).
 *
 * One-time setup: paste this + Dashboard.html into the sheet's script
 * editor, set API_KEY, run setup() once (creates the tabs), deploy.
 */

var API_KEY = 'change-me';          // must match firmware config.h
var LIVE_STALE_S = 180;             // no heartbeat for this long => "offline"
var EVENT_TAIL_ROWS = 6000;         // how much of the Events tab the dashboard scans
var DAYS_ON_DASHBOARD = 7;

var TAB = { events: 'Events', batches: 'Batches', live: 'Live', config: 'Config' };
var EVENT_COLS = ['server_time', 'device_time', 'station', 'operator', 'pillow_type',
                  'event', 'delta', 'count', 'defects', 'batch_id', 'seq'];
var BATCH_COLS = ['batch_id', 'station', 'operator', 'pillow_type', 'started', 'finished',
                  'pillows', 'defects', 'minutes', 'per_hour'];
var LIVE_COLS  = ['station', 'station_name', 'updated', 'running', 'operator', 'pillow_type',
                  'count', 'defects', 'batch_id', 'started', 'seconds', 'seq'];

// ------------------------------------------------------------------ setup
function setup() {
  var ss = SpreadsheetApp.getActive();
  ensureTab_(ss, TAB.events, EVENT_COLS);
  ensureTab_(ss, TAB.batches, BATCH_COLS);
  ensureTab_(ss, TAB.live, LIVE_COLS);
  var cfg = ss.getSheetByName(TAB.config);
  if (!cfg) {
    cfg = ss.insertSheet(TAB.config);
    cfg.getRange('A1:G1').setValues([['operators', 'pillow_types', 'station_id', 'station_name', '',
                                      'daily_target', 'suggested_types']]).setFontWeight('bold');
    cfg.getRange('A2:B5').setValues([
      ['Alex', 'Standard'], ['Sam', 'King'], ['Jordan', 'Body'], ['Casey', 'Travel']]);
    cfg.getRange('C2:D4').setValues([['blower-1', 'Blower 1'], ['blower-2', 'Blower 2'], ['blower-3', 'Blower 3']]);
    cfg.getRange('F2').setValue(400);
    cfg.setFrozenRows(1);
  }
  var def = ss.getSheets()[0];
  if (def.getName() === 'Sheet1' && def.getLastRow() === 0) ss.deleteSheet(def);
}

function ensureTab_(ss, name, cols) {
  var sh = ss.getSheetByName(name);
  if (!sh) sh = ss.insertSheet(name);
  if (sh.getLastRow() === 0) {
    sh.getRange(1, 1, 1, cols.length).setValues([cols]).setFontWeight('bold');
    sh.setFrozenRows(1);
  }
  return sh;
}

// ---------------------------------------------------------------- config
function readConfig_() {
  var sh = SpreadsheetApp.getActive().getSheetByName(TAB.config);
  var out = { operators: [], types: [], stations: {}, target: 0, suggested: [] };
  if (!sh) return out;
  var rows = sh.getDataRange().getValues();
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0] !== '') out.operators.push(String(rows[i][0]));
    if (rows[i][1] !== '') out.types.push(String(rows[i][1]));
    if (rows[i][2] !== '') out.stations[String(rows[i][2])] = String(rows[i][3] || rows[i][2]);
    if (rows[i][6] !== undefined && rows[i][6] !== '') out.suggested.push(String(rows[i][6]));
  }
  out.target = Number(rows[1] && rows[1][5]) || 0;
  // "Make next" guidance: types listed in suggested_types (column G, most
  // urgent first) go to the front of the picker on every device. Fill
  // column G by hand or from a script that reads sales / inventory data.
  var rest = out.types.filter(function (t) { return out.suggested.indexOf(t) < 0; });
  out.types = out.suggested.filter(function (t) { return out.types.indexOf(t) >= 0; }).concat(rest);
  return out;
}

// ------------------------------------------------------------------ HTTP
function doGet(e) {
  var p = (e && e.parameter) || {};
  if (p.action === 'config') {
    if (p.key !== API_KEY) return json_({ ok: false, error: 'bad key' });
    var c = readConfig_();
    return json_({ ok: true, operators: c.operators, types: c.types,
                   name: c.stations[p.station] || p.station || '' });
  }
  if (p.action === 'dashboard') return json_(getDashboardData());
  return HtmlService.createHtmlOutputFromFile('Dashboard')
    .setTitle('Pillow Floor')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function doPost(e) {
  var body;
  try { body = JSON.parse(e.postData.contents); }
  catch (err) { return json_({ ok: false, error: 'bad json' }); }
  if (body.key !== API_KEY) return json_({ ok: false, error: 'bad key' });
  if (!body.station) return json_({ ok: false, error: 'no station' });

  var lock = LockService.getScriptLock();
  lock.waitLock(20000);
  try {
    var n = ingest_(body);
    return json_({ ok: true, accepted: n });
  } finally {
    lock.releaseLock();
  }
}

function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}

// ---------------------------------------------------------------- ingest
function ingest_(body) {
  var ss = SpreadsheetApp.getActive();
  var events = ensureTab_(ss, TAB.events, EVENT_COLS);
  var live = ensureTab_(ss, TAB.live, LIVE_COLS);
  var now = new Date();
  var station = String(body.station);
  var name = String(body.name || station);
  var up = Number(body.up) || 0;

  // De-duplicate on (station, seq): the device re-sends if it missed our 200.
  var liveRow = findRow_(live, 1, station);
  var lastSeq = liveRow ? Number(live.getRange(liveRow, 12).getValue()) || 0 : 0;

  var rows = [];
  var last = null;
  (body.events || []).forEach(function (ev) {
    var seq = Number(ev.seq) || 0;
    var reset = seq < lastSeq - 1000;          // device re-flashed / NVS wiped
    if (seq <= lastSeq && !reset) return;
    lastSeq = seq;
    var deviceTime = ev.ts ? new Date(Number(ev.ts) * 1000)
                   : (up >= ev.up ? new Date(now.getTime() - (up - Number(ev.up))) : now);
    var delta = ev.ev === 'add' ? 1 : ev.ev === 'sub' ? -1 : 0;
    rows.push([now, deviceTime, station, ev.op || '', ev.type || '', ev.ev, delta,
               Number(ev.count) || 0, Number(ev.defects) || 0, ev.batch || '', seq]);
    if (ev.ev === 'batch_end') upsertBatch_(ss, station, ev, deviceTime);
    last = ev;
  });
  if (rows.length) events.getRange(events.getLastRow() + 1, 1, rows.length, EVENT_COLS.length).setValues(rows);

  // Live state: prefer the explicit heartbeat, else derive from the last event.
  var lv = body.live || (last && {
    running: last.ev !== 'batch_end', op: last.op, type: last.type, count: last.count,
    defects: last.defects, batch: last.batch, started: last.started || 0, seconds: 0, seq: last.seq });
  if (lv) {
    var started = Number(lv.started) ? new Date(Number(lv.started) * 1000) : '';
    var vals = [[station, name, now, !!lv.running, lv.op || '', lv.type || '', Number(lv.count) || 0,
                 Number(lv.defects) || 0, lv.batch || '', started, Number(lv.seconds) || 0, lastSeq]];
    if (!liveRow) liveRow = live.getLastRow() + 1;
    live.getRange(liveRow, 1, 1, LIVE_COLS.length).setValues(vals);
  }
  return rows.length;
}

function upsertBatch_(ss, station, ev, finished) {
  var sh = ensureTab_(ss, TAB.batches, BATCH_COLS);
  var started = Number(ev.started) ? new Date(Number(ev.started) * 1000)
              : new Date(finished.getTime() - (Number(ev.seconds) || 0) * 1000);
  var minutes = Math.round((Number(ev.seconds) || 0) / 60);
  var pillows = Number(ev.count) || 0;
  var perHour = minutes > 0 ? Math.round(pillows / (minutes / 60) * 10) / 10 : '';
  var row = [ev.batch, station, ev.op || '', ev.type || '', started, finished, pillows,
             Number(ev.defects) || 0, minutes, perHour];
  var r = findRow_(sh, 1, ev.batch);
  sh.getRange(r || sh.getLastRow() + 1, 1, 1, BATCH_COLS.length).setValues([row]);
}

function findRow_(sh, col, value) {
  var last = sh.getLastRow();
  if (last < 2) return 0;
  var vals = sh.getRange(2, col, last - 1, 1).getValues();
  for (var i = 0; i < vals.length; i++) if (String(vals[i][0]) === String(value)) return i + 2;
  return 0;
}

// ------------------------------------------------------------- dashboard
// Called by Dashboard.html via google.script.run, and by ?action=dashboard.
function getDashboardData() {
  var ss = SpreadsheetApp.getActive();
  var tz = ss.getSpreadsheetTimeZone();
  var cfg = readConfig_();
  var now = new Date();
  var today = Utilities.formatDate(now, tz, 'yyyy-MM-dd');

  // ---- day keys for the trend
  var days = [];
  for (var d = DAYS_ON_DASHBOARD - 1; d >= 0; d--) {
    var dt = new Date(now.getTime() - d * 86400000);
    days.push({ key: Utilities.formatDate(dt, tz, 'yyyy-MM-dd'),
                label: Utilities.formatDate(dt, tz, 'EEE'), pillows: 0, defects: 0 });
  }
  var dayIdx = {}; days.forEach(function (x, i) { dayIdx[x.key] = i; });

  // ---- scan the tail of Events
  var ev = ss.getSheetByName(TAB.events);
  var byOp = {}, byType = {}, byStation = {}, hours = [];
  for (var h = 0; h < 24; h++) hours.push(0);
  var defectsToday = 0, pillowsToday = 0;
  if (ev && ev.getLastRow() > 1) {
    var first = Math.max(2, ev.getLastRow() - EVENT_TAIL_ROWS + 1);
    var rows = ev.getRange(first, 1, ev.getLastRow() - first + 1, EVENT_COLS.length).getValues();
    rows.forEach(function (r) {
      var t = r[1] instanceof Date ? r[1] : r[0];
      if (!(t instanceof Date)) return;
      var key = Utilities.formatDate(t, tz, 'yyyy-MM-dd');
      var di = dayIdx[key];
      if (di === undefined) return;
      var delta = Number(r[6]) || 0;
      var isDefect = r[5] === 'defect';
      days[di].pillows += delta;
      if (isDefect) days[di].defects++;
      if (key !== today) return;
      pillowsToday += delta;
      if (isDefect) defectsToday++;
      var op = String(r[3] || '?'), ty = String(r[4] || '?'), stn = String(r[2]);
      byOp[op] = (byOp[op] || 0) + delta;
      byType[ty] = (byType[ty] || 0) + delta;
      byStation[stn] = (byStation[stn] || 0) + delta;
      hours[Number(Utilities.formatDate(t, tz, 'H'))] += delta;
    });
  }

  // ---- live station cards (one per configured station, plus any unknown ones)
  var stations = [];
  var seen = {};
  var lv = ss.getSheetByName(TAB.live);
  if (lv && lv.getLastRow() > 1) {
    lv.getRange(2, 1, lv.getLastRow() - 1, LIVE_COLS.length).getValues().forEach(function (r) {
      var id = String(r[0]);
      seen[id] = true;
      var ageS = r[2] instanceof Date ? Math.round((now - r[2]) / 1000) : 1e9;
      var startedMs = r[9] instanceof Date ? r[9].getTime() : 0;
      var running = r[3] === true;
      var seconds = running ? (startedMs ? Math.round((now - startedMs) / 1000) : Number(r[10]) || 0) : 0;
      stations.push({
        id: id, name: cfg.stations[id] || String(r[1] || id),
        status: ageS > LIVE_STALE_S ? 'offline' : (running ? 'running' : 'idle'),
        ageS: ageS, operator: String(r[4] || ''), type: String(r[5] || ''),
        count: Number(r[6]) || 0, defects: Number(r[7]) || 0, seconds: seconds,
        perHour: seconds > 120 ? Math.round((Number(r[6]) || 0) / (seconds / 3600)) : null,
        today: byStation[id] || 0 });
    });
  }
  Object.keys(cfg.stations).forEach(function (id) {
    if (!seen[id]) stations.push({ id: id, name: cfg.stations[id], status: 'offline', ageS: null,
      operator: '', type: '', count: 0, defects: 0, seconds: 0, perHour: null, today: byStation[id] || 0 });
  });
  stations.sort(function (a, b) { return a.name < b.name ? -1 : 1; });

  // ---- recent + today's batches
  var batches = [], batchesToday = 0;
  var bt = ss.getSheetByName(TAB.batches);
  if (bt && bt.getLastRow() > 1) {
    var first2 = Math.max(2, bt.getLastRow() - 200 + 1);
    var brows = bt.getRange(first2, 1, bt.getLastRow() - first2 + 1, BATCH_COLS.length).getValues();
    brows.forEach(function (r) {
      var fin = r[5] instanceof Date ? r[5] : null;
      if (fin && Utilities.formatDate(fin, tz, 'yyyy-MM-dd') === today) batchesToday++;
      batches.push({ id: String(r[0]), station: cfg.stations[String(r[1])] || String(r[1]), operator: String(r[2]),
        type: String(r[3]), finished: fin ? fin.getTime() : null, pillows: Number(r[6]) || 0,
        defects: Number(r[7]) || 0, minutes: Number(r[8]) || 0, perHour: r[9] === '' ? null : Number(r[9]) });
    });
    batches = batches.slice(-8).reverse();
  }

  var toList = function (m) {
    return Object.keys(m).map(function (k) { return { name: k, pillows: m[k] }; })
      .sort(function (a, b) { return b.pillows - a.pillows; });
  };
  return {
    ok: true, generated: now.getTime(), timezone: tz, today: today, target: cfg.target,
    totals: { pillows: pillowsToday, defects: defectsToday, batches: batchesToday,
              running: stations.filter(function (s) { return s.status === 'running'; }).length },
    stations: stations, operators: toList(byOp), types: toList(byType), hours: hours,
    days: days, batches: batches
  };
}

// ----------------------------------------------------------- maintenance
// Optional: run monthly from a time-driven trigger to keep Events fast.
function archiveOldEvents() {
  var ss = SpreadsheetApp.getActive();
  var ev = ss.getSheetByName(TAB.events);
  if (!ev || ev.getLastRow() < 2) return;
  var cutoff = new Date(Date.now() - 60 * 86400000);
  var vals = ev.getRange(2, 1, ev.getLastRow() - 1, EVENT_COLS.length).getValues();
  var keep = [], old = [];
  vals.forEach(function (r) { (r[0] instanceof Date && r[0] < cutoff ? old : keep).push(r); });
  if (!old.length) return;
  var arch = ensureTab_(ss, 'Events_Archive', EVENT_COLS);
  arch.getRange(arch.getLastRow() + 1, 1, old.length, EVENT_COLS.length).setValues(old);
  ev.getRange(2, 1, vals.length, EVENT_COLS.length).clearContent();
  if (keep.length) ev.getRange(2, 1, keep.length, EVENT_COLS.length).setValues(keep);
}
