#pragma once
#include "esphome.h"
#include "esp_partition.h"
#include "nvs_flash.h"
#include "nvs.h"
#include <string.h>
#include <stdlib.h>
#include <map>
#include <string>
#include <vector>

#define TC_NVS_NS        "timecube"
#define TC_PART_LABEL    "tclog"
#define TC_NAME_LEN      16U
#define TC_ENTRY_SIZE    32U   // magic(1)+side(1)+datetime(4)+duration(4)+name(16)+reserved(6); divides TC_SECTOR_SIZE evenly
#define TC_MAGIC_VALID   0xA5
#define TC_SECTOR_SIZE   4096U
#define TC_CSV_MAX       16000U

struct __attribute__((packed)) TcLogEntry {
  uint8_t  magic;              // TC_MAGIC_VALID, or 0xFF on erased/empty flash
  uint8_t  side;                // 1-6
  uint32_t datetime;             // packed local date/time (see pack_datetime); 0 = clock wasn't synced yet
  uint32_t duration;            // seconds
  char     name[TC_NAME_LEN];   // activity name, truncated
  uint8_t  _reserved[6];
};  // 32 bytes

// Config Storage (in-memory)
std::map<int, std::string> activity_names = {
  {1, "Fokus"},
  {2, "Meeting"},
  {3, "Lernen"},
  {4, "Pause"},
  {5, "Admin"},
  {6, "Sonstiges"}
};

// Forward Declarations
void save_config();

// --- Kompaktes lokales Datum/Zeit-Packing -----------------------------------
// Vermeidet UTC/DST-Umrechnung: spiegelt 1:1 die lokalen Felder von
// id(sntp_time).now() (bereits per "timezone:" aufgeloest).
// Bit-Layout (32 bit total): [year-2020:7][month:4][day:5][hour:5][minute:6][second/2:5]
static uint32_t pack_datetime(int year, int month, int day, int hour, int minute, int second) {
  uint32_t yr = (year >= 2020 && year <= 2147) ? (uint32_t)(year - 2020) : 0;
  return (yr << 25) | (((uint32_t)month & 0xF) << 21) | (((uint32_t)day & 0x1F) << 16) |
         (((uint32_t)hour & 0x1F) << 11) | (((uint32_t)minute & 0x3F) << 5) | (((uint32_t)(second / 2)) & 0x1F);
}

static void unpack_datetime(uint32_t v, int &year, int &month, int &day, int &hour, int &minute, int &second) {
  second = (int)(v & 0x1F) * 2;
  minute = (int)((v >> 5) & 0x3F);
  hour   = (int)((v >> 11) & 0x1F);
  day    = (int)((v >> 16) & 0x1F);
  month  = (int)((v >> 21) & 0xF);
  year   = (int)((v >> 25) & 0x7F) + 2020;
}

// --- Flash-Partition Helfer ---

static const esp_partition_t* tc_partition() {
  static const esp_partition_t *p = nullptr;
  if (!p) {
    p = esp_partition_find_first(
      ESP_PARTITION_TYPE_DATA,
      (esp_partition_subtype_t)0x99,
      TC_PART_LABEL
    );
    if (!p) ESP_LOGE("timecube", "Partition '%s' nicht gefunden!", TC_PART_LABEL);
  }
  return p;
}

static uint32_t tc_max_entries() {
  const esp_partition_t *p = tc_partition();
  return p ? (p->size / TC_ENTRY_SIZE) : 0;
}

// --- Ring-Buffer-Position (in NVS persistiert, ueberlebt Stromverlust) -----
static uint32_t tc_log_head = 0;     // naechster freier Slot
static bool     tc_log_wrapped = false;

static void tc_load_head() {
  nvs_handle_t h;
  if (nvs_open(TC_NVS_NS, NVS_READONLY, &h) != ESP_OK) return;
  uint32_t head = 0; uint8_t wrapped = 0;
  nvs_get_u32(h, "log_head", &head);
  nvs_get_u8(h, "log_wrap", &wrapped);
  nvs_close(h);
  tc_log_head = head;
  tc_log_wrapped = (wrapped != 0);
}

static void tc_save_head() {
  nvs_handle_t h;
  if (nvs_open(TC_NVS_NS, NVS_READWRITE, &h) != ESP_OK) return;
  nvs_set_u32(h, "log_head", tc_log_head);
  nvs_set_u8(h, "log_wrap", tc_log_wrapped ? 1 : 0);
  nvs_commit(h);
  nvs_close(h);
}

// --- Init ---

void setup_littlefs() {
  tc_load_head();
  uint32_t max = tc_max_entries();
  uint32_t used = tc_log_wrapped ? max : tc_log_head;
  ESP_LOGI("timecube", "Log-Partition '%s': %u/%u Eintraege (wrapped=%d)", TC_PART_LABEL, used, max, tc_log_wrapped);
}

// --- NVS Config (Activity-Namen) ---

void save_config() {
  nvs_handle_t h;
  if (nvs_open(TC_NVS_NS, NVS_READWRITE, &h) != ESP_OK) return;
  for (auto &kv : activity_names) {
    char key[12];
    snprintf(key, sizeof(key), "name_%d", kv.first);
    nvs_set_str(h, key, kv.second.c_str());
  }
  nvs_commit(h);
  nvs_close(h);
  ESP_LOGI("timecube", "Config gespeichert");
}

void load_config() {
  nvs_handle_t h;
  if (nvs_open(TC_NVS_NS, NVS_READONLY, &h) != ESP_OK) {
    ESP_LOGW("timecube", "Kein Config, nutze Defaults");
    save_config();
    return;
  }
  for (int i = 1; i <= 6; i++) {
    char key[12]; size_t len = 64; char val[64] = {};
    snprintf(key, sizeof(key), "name_%d", i);
    if (nvs_get_str(h, key, val, &len) == ESP_OK) {
      activity_names[i] = val;
      ESP_LOGI("timecube", "Geladen: Seite %d = %s", i, val);
    }
  }
  nvs_close(h);
}

std::string get_activity_name(int side) {
  if (side == 0) return "Pause";  // Seite 0 = keine eindeutige Seite / Doppelklick
  return activity_names.count(side) ? activity_names[side] : "Unbekannt";
}

void set_activity_name(int side, const std::string& name) {
  if (side >= 1 && side <= 6) {
    activity_names[side] = name;
    save_config();
    ESP_LOGI("timecube", "Updated: Seite %d = %s", side, name.c_str());
  }
}

// --- Log (Ring-Buffer auf direkter Flash-Partition) ---

static void tc_write_entry(int side, uint32_t datetime, uint32_t duration) {
  const esp_partition_t *p = tc_partition();
  if (!p) return;
  uint32_t max = tc_max_entries();
  if (max == 0) return;

  uint32_t slot = tc_log_head;
  uint32_t offset = slot * TC_ENTRY_SIZE;

  // TC_ENTRY_SIZE (32) teilt TC_SECTOR_SIZE (4096) exakt -> jeder Sektor-Start
  // faellt exakt auf einen Eintrags-Offset, einfacher Erase-Check reicht aus.
  if (offset % TC_SECTOR_SIZE == 0)
    esp_partition_erase_range(p, offset, TC_SECTOR_SIZE);

  TcLogEntry entry = {};
  entry.magic    = TC_MAGIC_VALID;
  entry.side     = (uint8_t)side;
  entry.datetime = datetime;
  entry.duration = duration;
  strncpy(entry.name, get_activity_name(side).c_str(), sizeof(entry.name) - 1);

  esp_partition_write(p, offset, &entry, sizeof(entry));

  tc_log_head = (slot + 1) % max;
  if (tc_log_head == 0) tc_log_wrapped = true;
  tc_save_head();

  ESP_LOGI("timecube", "Logged [%u/%u]: Seite %d | %u s", slot + 1, max, side, duration);
}

// Seite 0 = Pause
void log_activity(int side, unsigned long duration) {
  if (side < 0 || side > 6 || duration == 0) return;
  auto t = id(sntp_time).now();
  uint32_t dt = t.is_valid() ? pack_datetime(t.year, t.month, t.day_of_month, t.hour, t.minute, t.second) : 0;
  tc_write_entry(side, dt, (uint32_t)duration);
}

// --- Checkpoint (minimiert Datenverlust bei Stromausfall/Schalter) ---

struct __attribute__((packed)) TcCheckpoint {
  uint8_t  side;
  uint32_t start_epoch;
  uint32_t last_seen_epoch;
  uint32_t last_seen_datetime;
};

void save_checkpoint(int side, unsigned long start_epoch) {
  if (side < 0 || side > 6 || start_epoch == 0) return;
  auto t = id(sntp_time).now();
  if (!t.is_valid()) return;

  TcCheckpoint ckpt;
  ckpt.side = (uint8_t)side;
  ckpt.start_epoch = (uint32_t)start_epoch;
  ckpt.last_seen_epoch = (uint32_t)t.timestamp;
  ckpt.last_seen_datetime = pack_datetime(t.year, t.month, t.day_of_month, t.hour, t.minute, t.second);

  nvs_handle_t h;
  if (nvs_open(TC_NVS_NS, NVS_READWRITE, &h) != ESP_OK) return;
  nvs_set_blob(h, "ckpt", &ckpt, sizeof(ckpt));
  nvs_commit(h);
  nvs_close(h);
}

static void clear_checkpoint() {
  nvs_handle_t h;
  if (nvs_open(TC_NVS_NS, NVS_READWRITE, &h) != ESP_OK) return;
  nvs_erase_key(h, "ckpt");
  nvs_commit(h);
  nvs_close(h);
}

// Wird beim ersten NTP-Sync nach dem Boot aufgerufen. Existiert ein Checkpoint
// einer Sitzung, die durch Stromverlust/Schalter nie regulaer beendet wurde,
// wird sie bis zum letzten Checkpoint-Zeitpunkt nachtraeglich geloggt statt
// komplett verloren zu gehen (Datenverlust begrenzt auf das Checkpoint-Intervall).
void recover_checkpoint() {
  nvs_handle_t h;
  if (nvs_open(TC_NVS_NS, NVS_READONLY, &h) != ESP_OK) return;
  TcCheckpoint ckpt = {};
  size_t len = sizeof(ckpt);
  bool have = nvs_get_blob(h, "ckpt", &ckpt, &len) == ESP_OK && len == sizeof(ckpt);
  nvs_close(h);
  if (!have) return;

  if (ckpt.side <= 6 && ckpt.last_seen_epoch > ckpt.start_epoch) {
    uint32_t duration = ckpt.last_seen_epoch - ckpt.start_epoch;
    // Zeitlimit gilt auch fuer wiederhergestellte Sitzungen (z.B. Akku ueber Nacht leer)
    uint32_t max_sec = (uint32_t)(id(max_tracking_hours).state * 3600);
    if (max_sec > 0 && duration > max_sec) duration = max_sec;
    if (duration > 0 && duration < 172800UL) {  // Sanity-Check: < 48h
      tc_write_entry(ckpt.side, ckpt.last_seen_datetime, duration);
      ESP_LOGW("timecube", "Wiederhergestellt nach Stromverlust: Seite %d, %u s", ckpt.side, duration);
    }
  }
  clear_checkpoint();
}

// CSV Export: neueste Eintraege zuerst sammeln (bis TC_CSV_MAX Bytes), dann
// chronologisch ausgeben. Bei vollem Log wuerden sonst immer nur die
// aeltesten Eintraege angezeigt und das Dashboard wirkt "eingefroren".
std::string get_csv_content() {
  const esp_partition_t *p = tc_partition();
  uint32_t max = tc_max_entries();
  if (!p || max == 0) return "Keine Daten";

  uint32_t total = tc_log_wrapped ? max : tc_log_head;
  if (total == 0) return "Keine Daten";

  std::vector<std::string> lines;
  size_t total_bytes = 0;

  for (uint32_t i = 0; i < total; i++) {
    uint32_t slot = (tc_log_head + max - 1 - i) % max;
    TcLogEntry entry;
    esp_partition_read(p, slot * TC_ENTRY_SIZE, &entry, sizeof(entry));
    if (entry.magic != TC_MAGIC_VALID) continue;

    char name_buf[TC_NAME_LEN + 1] = {};
    memcpy(name_buf, entry.name, TC_NAME_LEN);
    name_buf[TC_NAME_LEN] = '\0';

    char ts_buf[24];
    if (entry.datetime == 0) {
      strcpy(ts_buf, "unsynced");
    } else {
      int yr, mo, dy, hh, mi, se;
      unpack_datetime(entry.datetime, yr, mo, dy, hh, mi, se);
      snprintf(ts_buf, sizeof(ts_buf), "%04d-%02d-%02dT%02d:%02d:%02d", yr, mo, dy, hh, mi, se);
    }

    char line[96];
    int n = snprintf(line, sizeof(line), "%s,%d,%s,%u\n", ts_buf, (int)entry.side, name_buf, (unsigned)entry.duration);
    if (n <= 0) continue;

    if (total_bytes + (size_t)n > TC_CSV_MAX) break;
    lines.emplace_back(line);
    total_bytes += (size_t)n;
  }

  if (lines.empty()) return "Keine Daten";

  std::string result;
  result.reserve(total_bytes);
  for (auto it = lines.rbegin(); it != lines.rend(); ++it) result += *it;
  return result;
}

int get_log_count() {
  uint32_t max = tc_max_entries();
  return (int)(tc_log_wrapped ? max : tc_log_head);
}

void clear_log() {
  const esp_partition_t *p = tc_partition();
  if (!p) return;
  esp_partition_erase_range(p, 0, p->size);
  tc_log_head = 0;
  tc_log_wrapped = false;
  tc_save_head();
  clear_checkpoint();
  ESP_LOGI("timecube", "Log geloescht");
}
