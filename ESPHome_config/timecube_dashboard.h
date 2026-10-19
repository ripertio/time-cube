#pragma once
#include "esphome.h"
#include "esphome/components/web_server_base/web_server_base.h"

// Mirror of /Users/ripert/code/timecube/index.html - keep both in sync when editing.
static const char TIMECUBE_DASHBOARD_HTML[] = R"TCDASH(
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Time Cube</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #0f0f11;
      color: #e0e0e0;
      min-height: 100vh;
      padding: 2rem 1rem;
    }

    h1 { font-size: 1.6rem; font-weight: 700; letter-spacing: -0.5px; }
    h2 { font-size: 1.1rem; font-weight: 600; color: #aaa; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 1rem; }
    h3 { font-size: 1rem; font-weight: 600; margin-bottom: 0.5rem; }

    .container { max-width: 1100px; margin: 0 auto; }

    /* --- Header --- */
    header { display: flex; align-items: center; gap: 0.6rem; margin-bottom: 1rem; flex-wrap: wrap; }
    header h1 { flex: 1; min-width: 200px; }
    .btn {
      padding: 0.55rem 1.1rem; border-radius: 8px; border: none;
      font-size: 0.9rem; font-weight: 600; cursor: pointer; transition: opacity 0.15s;
      text-decoration: none; display: inline-block;
    }
    .btn:hover { opacity: 0.85; }
    .btn-primary { background: #6c63ff; color: #fff; }
    .btn-ghost { background: #1a1a20; color: #888; border: 1px solid #333; }

    .meta { font-size: 0.8rem; color: #555; margin-bottom: 2rem; min-height: 1.2em; }
    .meta span { color: #888; }

    /* --- Error --- */
    .error-box {
      background: #2a1a1a; border: 1px solid #5c2020; border-radius: 8px;
      padding: 0.9rem 1.1rem; margin-bottom: 1.5rem; color: #e07070;
      font-size: 0.9rem; display: none;
    }

    /* --- Cards --- */
    .section { margin-bottom: 3rem; }
    .card-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; margin-bottom: 1.5rem; }
    .card {
      background: #1a1a20; border: 1px solid #252530; border-radius: 12px;
      padding: 1.1rem 1.2rem;
    }
    .card .label { font-size: 0.75rem; color: #666; text-transform: uppercase; letter-spacing: 0.8px; margin-bottom: 0.3rem; }
    .card .value { font-size: 1.5rem; font-weight: 700; }
    .card .sub { font-size: 0.8rem; color: #777; margin-top: 0.2rem; }

    /* --- Charts --- */
    .charts-row {
      display: grid; grid-template-columns: 320px 1fr; gap: 1.5rem; align-items: start;
    }
    @media (max-width: 720px) { .charts-row { grid-template-columns: 1fr; } }

    .chart-box {
      background: #1a1a20; border: 1px solid #252530; border-radius: 12px;
      padding: 1.2rem;
    }
    .chart-box canvas { max-height: 300px; }

    /* --- Month tabs --- */
    .month-tabs { display: flex; gap: 0.4rem; flex-wrap: wrap; margin-bottom: 1.5rem; }
    .month-tab {
      padding: 0.4rem 0.9rem; border-radius: 6px; border: 1px solid #2a2a35;
      background: #1a1a20; color: #888; font-size: 0.85rem; cursor: pointer; transition: all 0.15s;
    }
    .month-tab:hover { border-color: #6c63ff; color: #ddd; }
    .month-tab.active { background: #6c63ff; border-color: #6c63ff; color: #fff; font-weight: 600; }

    /* --- Legend table --- */
    .legend-table { width: 100%; border-collapse: collapse; font-size: 0.85rem; margin-top: 0.75rem; }
    .legend-table td { padding: 0.35rem 0.5rem; }
    .legend-table td:last-child { text-align: right; color: #aaa; }
    .dot { display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 0.5rem; vertical-align: middle; }

    /* --- Empty state --- */
    .empty { color: #444; font-size: 0.9rem; padding: 2rem 0; text-align: center; display: none; }

    #main-content { display: none; }
  </style>
</head>
<body>
<div class="container">

  <header>
    <h1>⏱ Time Cube Analytics</h1>
    <button class="btn btn-primary" onclick="loadData()">↻ Refresh</button>
    <button class="btn btn-ghost" id="btn-download" style="display:none" onclick="downloadCSV()">⬇ Download CSV</button>
    <a class="btn btn-ghost" href="/">⚙ Configure</a>
  </header>

  <div class="meta" id="meta-line">Loading…</div>
  <div class="error-box" id="error-box"></div>

  <!-- Main content (hidden until data loaded) -->
  <div id="main-content">

    <!-- Overall Section -->
    <div class="section">
      <h2>Overall</h2>
      <div class="card-grid" id="overall-stats"></div>
      <div class="charts-row">
        <div class="chart-box">
          <h3>Time by Activity</h3>
          <canvas id="overall-pie"></canvas>
          <table class="legend-table" id="overall-legend"></table>
        </div>
        <div class="chart-box">
          <h3>Daily Total (all time)</h3>
          <canvas id="overall-bar"></canvas>
        </div>
      </div>
    </div>

    <!-- Monthly Section -->
    <div class="section">
      <h2>Monthly Breakdown</h2>
      <div class="month-tabs" id="month-tabs"></div>
      <div class="card-grid" id="month-stats"></div>
      <div class="charts-row">
        <div class="chart-box">
          <h3>Activity Share</h3>
          <canvas id="month-pie"></canvas>
          <table class="legend-table" id="month-legend"></table>
        </div>
        <div class="chart-box">
          <h3>Daily Breakdown</h3>
          <canvas id="month-bar"></canvas>
        </div>
      </div>
    </div>

  </div>
</div>

<script>
// ─── Constants ────────────────────────────────────────────────────────────────
// Served from the same host/port as the API (ESPHome's web_server), so this is
// a same-origin request - a relative path works regardless of hostname/IP used.
const CSV_URL = '/text_sensor/csv_export';

const PALETTE = [
  '#6c63ff','#ff6584','#43d9ad','#f7b731','#a55eea',
  '#fd9644','#26de81','#4bcffa','#fc5c65','#45aaf2',
];

// ─── Chart instances ───────────────────────────────────────────────────────────
const charts = {};

function destroyChart(id) {
  if (charts[id]) { charts[id].destroy(); delete charts[id]; }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
function fmtDuration(secs) {
  if (secs < 60) return `${secs}s`;
  const h = Math.floor(secs / 3600);
  const m = Math.floor((secs % 3600) / 60);
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
}

function fmtDate(d) {
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

function fmtMonth(ym) { // "2026-06" → "Jun 2026"
  const [y, m] = ym.split('-');
  return new Date(+y, +m - 1).toLocaleDateString(undefined, { month: 'long', year: 'numeric' });
}

function color(i) { return PALETTE[i % PALETTE.length]; }

// ─── CSV Parsing ──────────────────────────────────────────────────────────────
function parseCSV(text) {
  const lines = text.trim().split(/\r?\n/).filter(l => l.trim());
  // Skip header if present
  const start = lines[0].toLowerCase().startsWith('timestamp') ? 1 : 0;
  return lines.slice(start).map(line => {
    const parts = line.split(',');
    if (parts.length < 4) return null;
    const ts = new Date(parts[0].trim());
    if (isNaN(ts)) return null; // also drops "unsynced" rows logged before the clock had NTP time
    return {
      timestamp: ts,
      seite: parseInt(parts[1].trim()),
      aktivitaet: parts[2].trim(),
      dauer_sek: parseInt(parts[3].trim()) || 0,
    };
  }).filter(Boolean);
}

// ─── Aggregation ──────────────────────────────────────────────────────────────
function byActivity(rows) {
  const acc = {};
  rows.forEach(r => { acc[r.aktivitaet] = (acc[r.aktivitaet] || 0) + r.dauer_sek; });
  return acc;
}

function byDay(rows) {
  const acc = {};
  rows.forEach(r => {
    const d = r.timestamp.toISOString().slice(0, 10);
    if (!acc[d]) acc[d] = {};
    acc[d][r.aktivitaet] = (acc[d][r.aktivitaet] || 0) + r.dauer_sek;
  });
  return acc;
}

function byMonth(rows) {
  const acc = {};
  rows.forEach(r => {
    const m = r.timestamp.toISOString().slice(0, 7);
    if (!acc[m]) acc[m] = [];
    acc[m].push(r);
  });
  return acc;
}

function uniqueActivities(rows) {
  return [...new Set(rows.map(r => r.aktivitaet))].sort();
}

// ─── Render helpers ───────────────────────────────────────────────────────────
function renderStats(el, cards) {
  el.innerHTML = cards.map(c => `
    <div class="card">
      <div class="label">${c.label}</div>
      <div class="value">${c.value}</div>
      ${c.sub ? `<div class="sub">${c.sub}</div>` : ''}
    </div>`).join('');
}

function renderPie(canvasId, legendId, actMap) {
  destroyChart(canvasId);
  const labels = Object.keys(actMap);
  const data   = Object.values(actMap);
  const colors = labels.map((_, i) => color(i));

  charts[canvasId] = new Chart(document.getElementById(canvasId), {
    type: 'doughnut',
    data: { labels, datasets: [{ data, backgroundColor: colors, borderWidth: 2, borderColor: '#1a1a20' }] },
    options: {
      plugins: { legend: { display: false } },
      cutout: '60%',
    }
  });

  const total = data.reduce((a, b) => a + b, 0);
  document.getElementById(legendId).innerHTML = labels.map((l, i) => `
    <tr>
      <td><span class="dot" style="background:${colors[i]}"></span>${l}</td>
      <td>${fmtDuration(actMap[l])} (${Math.round(actMap[l] / total * 100)}%)</td>
    </tr>`).join('');
}

function renderStackedBar(canvasId, dayMap, activities, allRows) {
  destroyChart(canvasId);
  const days = Object.keys(dayMap).sort();
  const actColors = {};
  activities.forEach((a, i) => actColors[a] = color(i));

  const datasets = activities.map(act => ({
    label: act,
    data: days.map(d => Math.round((dayMap[d][act] || 0) / 60)), // minutes
    backgroundColor: actColors[act],
    borderRadius: 3,
    borderSkipped: false,
  }));

  charts[canvasId] = new Chart(document.getElementById(canvasId), {
    type: 'bar',
    data: {
      labels: days.map(d => fmtDate(new Date(d + 'T12:00:00'))),
      datasets,
    },
    options: {
      responsive: true,
      scales: {
        x: { stacked: true, ticks: { color: '#666' }, grid: { color: '#222' } },
        y: { stacked: true, ticks: { color: '#666', callback: v => v + 'm' }, grid: { color: '#222' } },
      },
      plugins: {
        legend: { display: activities.length > 1, labels: { color: '#aaa', boxWidth: 12 } },
        tooltip: { callbacks: { label: ctx => ` ${ctx.dataset.label}: ${fmtDuration(ctx.raw * 60)}` } },
      },
    }
  });
}

// ─── Overall section ──────────────────────────────────────────────────────────
function renderOverall(rows) {
  const actMap   = byActivity(rows);
  const dayMap   = byDay(rows);
  const total    = rows.reduce((a, r) => a + r.dauer_sek, 0);
  const acts     = uniqueActivities(rows);
  const days     = Object.keys(dayMap);
  const topAct   = Object.entries(actMap).sort((a, b) => b[1] - a[1])[0];

  renderStats(document.getElementById('overall-stats'), [
    { label: 'Total Tracked', value: fmtDuration(total) },
    { label: 'Activities', value: acts.length },
    { label: 'Days Tracked', value: days.length },
    { label: 'Top Activity', value: topAct[0], sub: fmtDuration(topAct[1]) },
    { label: 'Avg / Day', value: fmtDuration(Math.round(total / days.length)) },
  ]);

  renderPie('overall-pie', 'overall-legend', actMap);
  renderStackedBar('overall-bar', dayMap, acts, rows);
}

// ─── Monthly section ──────────────────────────────────────────────────────────
let allRows = [];

function renderMonth(month) {
  document.querySelectorAll('.month-tab').forEach(t =>
    t.classList.toggle('active', t.dataset.month === month)
  );
  const rows   = byMonth(allRows)[month] || [];
  const actMap = byActivity(rows);
  const dayMap = byDay(rows);
  const total  = rows.reduce((a, r) => a + r.dauer_sek, 0);
  const acts   = uniqueActivities(rows);
  const days   = Object.keys(dayMap);

  renderStats(document.getElementById('month-stats'), [
    { label: 'Total', value: fmtDuration(total) },
    { label: 'Active Days', value: days.length },
    { label: 'Sessions', value: rows.length },
    { label: 'Avg / Day', value: days.length ? fmtDuration(Math.round(total / days.length)) : '—' },
  ]);

  renderPie('month-pie', 'month-legend', actMap);
  renderStackedBar('month-bar', dayMap, acts, rows);
}

function renderMonthTabs(months) {
  const tabs = document.getElementById('month-tabs');
  tabs.innerHTML = months.map(m => `
    <button class="month-tab" data-month="${m}" onclick="renderMonth('${m}')">${fmtMonth(m)}</button>
  `).join('');
}

// ─── Data loading ─────────────────────────────────────────────────────────────
function showError(msg) {
  const el = document.getElementById('error-box');
  el.style.display = msg ? 'block' : 'none';
  el.textContent = msg || '';
}

function showMeta(fetchedAt, count) {
  const ago = Math.round((Date.now() - fetchedAt) / 1000 / 60);
  const agoStr = ago < 1 ? 'just now' : ago < 60 ? `${ago}m ago` : `${Math.round(ago/60)}h ago`;
  document.getElementById('meta-line').innerHTML =
    `<span>${count} entries</span> &nbsp;·&nbsp; Last fetched: <span>${agoStr}</span>`;
}

async function fetchAndParse(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status} ${res.statusText}`);
  const text = await res.text();
  let csvText;
  try {
    const json = JSON.parse(text);
    // ESPHome text_sensor API returns { "value": "csv\\ncsv\\n...", ... }
    csvText = (json.value ?? json.state ?? text).replace(/\\n/g, '\n');
  } catch {
    csvText = text;
  }
  return parseCSV(csvText);
}

async function loadData() {
  showError('');
  try {
    const rows = await fetchAndParse(CSV_URL);
    if (!rows.length) { showError('No data yet — flip the cube to log your first activity.'); return; }
    processRows(rows, Date.now());
  } catch (e) {
    showError(`Failed to load from the cube: ${e.message}`);
  }
}

function processRows(rows, fetchedAt) {
  allRows = rows;
  showMeta(fetchedAt, rows.length);

  const months = Object.keys(byMonth(rows)).sort();
  renderMonthTabs(months);
  renderOverall(rows);
  renderMonth(months[months.length - 1]); // show latest month by default

  document.getElementById('main-content').style.display = 'block';
  document.getElementById('btn-download').style.display = '';
}

function downloadCSV() {
  if (!allRows.length) return;
  const header = 'timestamp,seite,aktivitaet,dauer_sek';
  const lines = allRows.map(r => [
    r.timestamp.toISOString().slice(0, 19).replace('T', 'T'),
    r.seite,
    r.aktivitaet,
    r.dauer_sek
  ].join(','));
  const blob = new Blob([header + '\n' + lines.join('\n')], { type: 'text/csv' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `timecube_${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(a.href);
}

// ─── Init ─────────────────────────────────────────────────────────────────────
window.addEventListener('DOMContentLoaded', loadData);
</script>
</body>
</html>
)TCDASH";

// Registriert /analytics als zusaetzlichen Pfad auf dem bereits laufenden
// ESPHome web_server (Port 80) - kein zweiter Server/Port noetig.
class TimecubeDashboardHandler : public AsyncWebHandler {
 public:
  bool canHandle(AsyncWebServerRequest *request) override {
    return request->method() == HTTP_GET && request->url() == "/analytics";
  }
  void handleRequest(AsyncWebServerRequest *request) override {
    request->send(200, "text/html", TIMECUBE_DASHBOARD_HTML);
  }
};

void register_dashboard_handler() {
  id(base_web_server).add_handler(new TimecubeDashboardHandler());
  ESP_LOGI("timecube", "Dashboard registriert unter /analytics");
}
