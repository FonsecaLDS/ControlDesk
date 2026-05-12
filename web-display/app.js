"use strict";

const STATUS = {
  ONLINE: "ONLINE",
  WARNING: "WARNING",
  ERROR: "ERROR",
  OFFLINE: "OFFLINE"
};

const state = {
  selectedDeviceId: "AHD_570",
  simulationPaused: false,
  connectionState: "SIMULATING",
  tickCount: 0,
  diagnosticsByDevice: {},
  logLines: []
};

const devices = [
  {
    id: "AHD_570",
    name: "Display Panel AHD-570",
    type: "Display Panel",
    location: "Bridge",
    protocol: "NMEA-0183",
    address: "BRG-01",
    status: STATUS.ONLINE,
    firmware: "2.4.7",
    model: "AHD-570",
    notes: "Primary bridge monitoring display with multi-page alarm overview.",
    errorCount: 0
  },
  {
    id: "LCU_210",
    name: "Control Unit LCU",
    type: "Logic Control Unit",
    location: "Bridge",
    protocol: "Modbus RTU",
    address: "BRG-02",
    status: STATUS.ONLINE,
    firmware: "1.9.3",
    model: "LCU-210",
    notes: "Local control unit for navigation and lighting relay groups.",
    errorCount: 1
  },
  {
    id: "ALM_DISP",
    name: "Alarm Display",
    type: "Alarm Annunciator",
    location: "Alarm System",
    protocol: "CANopen",
    address: "ALM-01",
    status: STATUS.WARNING,
    firmware: "3.1.2",
    model: "AAD-320",
    notes: "Dedicated alarm display, warning state caused by simulated packet loss.",
    errorCount: 2
  },
  {
    id: "SNS_MOD",
    name: "Sensor Module",
    type: "Remote I/O",
    location: "Alarm System",
    protocol: "CANopen",
    address: "ALM-02",
    status: STATUS.ONLINE,
    firmware: "2.0.5",
    model: "RSM-88",
    notes: "Remote sensor acquisition module for alarm contact inputs.",
    errorCount: 0
  },
  {
    id: "ENG_CTRL",
    name: "Engine Controller",
    type: "Engine Controller",
    location: "Engine Room",
    protocol: "J1939",
    address: "ENG-01",
    status: STATUS.ONLINE,
    firmware: "5.8.1",
    model: "ECU-M450",
    notes: "Simulated propulsion controller publishing RPM and current load.",
    errorCount: 0
  },
  {
    id: "TMP_SENS",
    name: "Temperature Sensor",
    type: "Sensor",
    location: "Engine Room",
    protocol: "1-Wire Gateway",
    address: "ENG-02",
    status: STATUS.WARNING,
    firmware: "1.2.0",
    model: "TS-40",
    notes: "High ambient temperature warning used for diagnostic demonstration.",
    errorCount: 3
  },
  {
    id: "VLT_MON",
    name: "Voltage Monitor",
    type: "Power Monitor",
    location: "Power System",
    protocol: "Modbus TCP",
    address: "PWR-01",
    status: STATUS.OFFLINE,
    firmware: "4.0.4",
    model: "VM-120",
    notes: "Offline monitor included to demonstrate state handling and reporting.",
    errorCount: 5
  },
  {
    id: "COM_GW",
    name: "Communication Gateway",
    type: "Gateway",
    location: "Communication Bus",
    protocol: "TCP/UDP SIM",
    address: "BUS-01",
    status: STATUS.ONLINE,
    firmware: "2.8.1",
    model: "RIF-200",
    notes: "Local simulation gateway for text protocol packet monitoring.",
    errorCount: 0
  }
];

const systems = [
  "Bridge",
  "Alarm System",
  "Engine Room",
  "Power System",
  "Communication Bus"
];

const elements = {};

function cacheElements() {
  elements.clock = document.getElementById("clock");
  elements.connectionBadge = document.getElementById("connectionBadge");
  elements.overviewCards = document.getElementById("overviewCards");
  elements.deviceTableBody = document.getElementById("deviceTableBody");
  elements.diagnosticGrid = document.getElementById("diagnosticGrid");
  elements.diagnosticDeviceName = document.getElementById("diagnosticDeviceName");
  elements.selectedDeviceLabel = document.getElementById("selectedDeviceLabel");
  elements.alarmList = document.getElementById("alarmList");
  elements.alarmSummary = document.getElementById("alarmSummary");
  elements.logConsole = document.getElementById("logConsole");
  elements.packetPreview = document.getElementById("packetPreview");
  elements.pauseButton = document.getElementById("pauseButton");
  elements.warningButton = document.getElementById("warningButton");
  elements.clearLogsButton = document.getElementById("clearLogsButton");
}

function initializeState() {
  const now = new Date();
  devices.forEach((device, index) => {
    device.lastSeen = new Date(now.getTime() - index * 22000);
    state.diagnosticsByDevice[device.id] = createInitialDiagnostics(device);
  });
}

function createInitialDiagnostics(device) {
  const engineOffset = device.location === "Engine Room" ? 10 : 0;
  return {
    temperature: round1(46 + engineOffset + Math.random() * 12),
    rpm: device.id === "ENG_CTRL" ? 1450 : 650 + Math.floor(Math.random() * 520),
    voltage: round1(device.status === STATUS.OFFLINE ? 0 : 12.2 + Math.random() * 1.2),
    current: round1(device.status === STATUS.OFFLINE ? 0 : 4 + Math.random() * 8),
    signalQuality: clamp(90 - device.errorCount * 5 + randomInt(-4, 5), 0, 100),
    packetLoss: round1(device.status === STATUS.OFFLINE ? 100 : Math.random() * 3),
    errorCount: device.errorCount,
    alarmState: device.status === STATUS.WARNING ? "Acknowledged" : "Normal",
    lastPacketTime: new Date(device.lastSeen || Date.now())
  };
}

function updateClock() {
  elements.clock.textContent = formatTime(new Date());
}

function simulationTick() {
  updateClock();
  if (state.simulationPaused) {
    return;
  }

  state.tickCount += 1;
  devices.forEach(updateDeviceDiagnostics);
  processSelectedDevicePacket();
  renderAll();
}

function updateDeviceDiagnostics(device) {
  const diagnostics = state.diagnosticsByDevice[device.id];
  if (device.status === STATUS.OFFLINE) {
    diagnostics.signalQuality = clamp(diagnostics.signalQuality + randomInt(-1, 1), 0, 18);
    diagnostics.packetLoss = round1(clamp(diagnostics.packetLoss + randomRange(-1.4, 1.4), 88, 100));
    diagnostics.voltage = 0;
    diagnostics.current = 0;
    diagnostics.rpm = 0;
    diagnostics.alarmState = "Active";
    return;
  }

  const tempBase = device.location === "Engine Room" ? 58 : 44;
  diagnostics.temperature = round1(tempBase + randomRange(0, 22));
  diagnostics.rpm = device.id === "ENG_CTRL" ? randomInt(900, 2550) : randomInt(620, 1380);
  diagnostics.voltage = round1(clamp(randomRange(11.7, 14.4), 10.2, 15.2));
  diagnostics.current = round1(randomRange(3.8, device.location === "Engine Room" ? 22 : 13));
  diagnostics.signalQuality = clamp(74 + randomInt(0, 27) - device.errorCount * 2, 24, 100);
  diagnostics.packetLoss = round1(clamp(randomRange(0, 8.2) + device.errorCount * 0.25, 0, 16));

  if (diagnostics.packetLoss > 7 || diagnostics.temperature > 74) {
    diagnostics.errorCount += Math.random() > 0.7 ? 1 : 0;
    device.errorCount = diagnostics.errorCount;
  }

  diagnostics.alarmState = getAlarmState(device, diagnostics);
  diagnostics.lastPacketTime = new Date();
  device.lastSeen = diagnostics.lastPacketTime;
  device.status = deriveDeviceStatus(device, diagnostics);
}

function processSelectedDevicePacket() {
  const device = getSelectedDevice();
  const diagnostics = state.diagnosticsByDevice[device.id];
  const packet = buildDevicePacket(device.id, diagnostics);
  elements.packetPreview.textContent = packet;
  log("RX", packet);
  log("TX", "ACK");

  if (diagnostics.packetLoss > 6.5) {
    log("WARN", "Packet loss above threshold");
  }

  if (state.tickCount % 11 === 0) {
    log("ERROR", "Device timeout simulated");
  }
}

function buildDevicePacket(deviceId, diagnostics) {
  return `$DEV,${deviceId},TEMP,${diagnostics.temperature.toFixed(1)},RPM,${diagnostics.rpm},VOLT,${diagnostics.voltage.toFixed(1)},CURR,${diagnostics.current.toFixed(1)},SIGNAL,${diagnostics.signalQuality},ERR,${diagnostics.errorCount}#`;
}

function getAlarmState(device, diagnostics) {
  if (device.status === STATUS.ERROR || diagnostics.packetLoss > 9 || diagnostics.voltage < 11) {
    return "Active";
  }

  if (device.status === STATUS.WARNING || diagnostics.packetLoss > 6.5 || diagnostics.temperature > 68) {
    return "Acknowledged";
  }

  return "Normal";
}

function deriveDeviceStatus(device, diagnostics) {
  if (device.status === STATUS.ERROR || device.status === STATUS.OFFLINE) {
    return device.status;
  }

  if (diagnostics.packetLoss > 8 || diagnostics.temperature > 72 || diagnostics.voltage < 11.4) {
    return STATUS.WARNING;
  }

  return STATUS.ONLINE;
}

function renderAll() {
  renderConnectionState();
  renderOverview();
  renderDeviceTable();
  renderDiagnostics();
  renderAlarms();
  renderLogs();
}

function renderConnectionState() {
  elements.connectionBadge.textContent = state.connectionState;
  elements.connectionBadge.className = `status-badge ${state.simulationPaused ? "status-warning" : "status-online"}`;
  elements.pauseButton.textContent = state.simulationPaused ? "Resume Simulation" : "Pause Simulation";
}

function renderOverview() {
  elements.overviewCards.innerHTML = systems.map((systemName) => {
    const systemDevices = devices.filter((device) => device.location === systemName);
    const status = getSystemStatus(systemDevices);
    const lastUpdate = getLatestUpdate(systemDevices);
    return `
      <article class="overview-card">
        <h3>${systemName}</h3>
        <dl>
          <dt>Status</dt>
          <dd><span class="device-status ${statusClass(status)}">${status}</span></dd>
          <dt>Devices</dt>
          <dd>${systemDevices.length}</dd>
          <dt>Last update</dt>
          <dd>${lastUpdate}</dd>
        </dl>
      </article>
    `;
  }).join("");
}

function renderDeviceTable() {
  elements.deviceTableBody.innerHTML = devices.map((device) => {
    const diagnostics = state.diagnosticsByDevice[device.id];
    const selected = device.id === state.selectedDeviceId ? "selected" : "";
    return `
      <tr class="${selected}" data-device-id="${device.id}">
        <td>${device.id}</td>
        <td>${device.name}</td>
        <td>${device.location}</td>
        <td>${device.protocol}</td>
        <td>${device.address}</td>
        <td><span class="device-status ${statusClass(device.status)}">${device.status}</span></td>
        <td>${signalMeter(diagnostics.signalQuality)}</td>
        <td>${formatTime(device.lastSeen)}</td>
      </tr>
    `;
  }).join("");
}

function renderDiagnostics() {
  const device = getSelectedDevice();
  const diagnostics = state.diagnosticsByDevice[device.id];
  elements.diagnosticDeviceName.textContent = device.name;
  elements.selectedDeviceLabel.textContent = `Selected: ${device.id}`;

  const cards = [
    ["Temperature", `${diagnostics.temperature.toFixed(1)} C`],
    ["RPM", diagnostics.rpm.toString()],
    ["Voltage", `${diagnostics.voltage.toFixed(1)} V`],
    ["Current", `${diagnostics.current.toFixed(1)} A`],
    ["Signal Quality", `${diagnostics.signalQuality} %`],
    ["Packet Loss", `${diagnostics.packetLoss.toFixed(1)} %`],
    ["Error Count", diagnostics.errorCount.toString()],
    ["Alarm State", diagnostics.alarmState]
  ];

  elements.diagnosticGrid.innerHTML = cards.map(([label, value]) => `
    <article class="diagnostic-card">
      <dl>
        <dt>${label}</dt>
        <dd>${device.id}</dd>
      </dl>
      <div class="value">${value}</div>
    </article>
  `).join("");
}

function renderAlarms() {
  const alarms = buildAlarmList();
  elements.alarmSummary.textContent = `${alarms.length} active`;
  elements.alarmList.innerHTML = alarms.length
    ? alarms.map((alarm) => `
      <div class="alarm-item ${alarm.level === "ERROR" ? "error" : ""}">
        <strong>${alarm.title}</strong>
        <span>${alarm.deviceId} / ${alarm.detail}</span>
      </div>
    `).join("")
    : `<div class="alarm-item"><strong>No active alarms</strong><span>All monitored values within simulated limits</span></div>`;
}

function buildAlarmList() {
  const selectedDevice = getSelectedDevice();
  const diagnostics = state.diagnosticsByDevice[selectedDevice.id];
  const alarms = [];

  if (diagnostics.packetLoss > 6.5) {
    alarms.push({
      level: "WARN",
      title: "Packet loss warning",
      deviceId: selectedDevice.id,
      detail: `${diagnostics.packetLoss.toFixed(1)} percent loss`
    });
  }

  if (diagnostics.temperature > 68) {
    alarms.push({
      level: "WARN",
      title: "High temperature warning",
      deviceId: selectedDevice.id,
      detail: `${diagnostics.temperature.toFixed(1)} C`
    });
  }

  if (selectedDevice.status === STATUS.ERROR || selectedDevice.status === STATUS.OFFLINE) {
    alarms.push({
      level: "ERROR",
      title: "Device timeout simulation",
      deviceId: selectedDevice.id,
      detail: selectedDevice.status
    });
  }

  if (diagnostics.voltage > 0 && diagnostics.voltage < 11.8) {
    alarms.push({
      level: "WARN",
      title: "Low voltage warning",
      deviceId: selectedDevice.id,
      detail: `${diagnostics.voltage.toFixed(1)} V`
    });
  }

  return alarms;
}

function renderLogs() {
  elements.logConsole.innerHTML = state.logLines.map((entry) => {
    return `<span class="log-${entry.level.toLowerCase()}">${entry.text}</span>`;
  }).join("\n");
  elements.logConsole.scrollTop = elements.logConsole.scrollHeight;
}

function bindEvents() {
  elements.deviceTableBody.addEventListener("click", (event) => {
    const row = event.target.closest("tr[data-device-id]");
    if (!row) {
      return;
    }

    state.selectedDeviceId = row.dataset.deviceId;
    log("INFO", `Selected device ${state.selectedDeviceId}`);
    processSelectedDevicePacket();
    renderAll();
  });

  elements.pauseButton.addEventListener("click", () => {
    state.simulationPaused = !state.simulationPaused;
    state.connectionState = state.simulationPaused ? "PAUSED" : "SIMULATING";
    log("INFO", state.simulationPaused ? "Simulation paused" : "Simulation resumed");
    renderAll();
  });

  elements.clearLogsButton.addEventListener("click", () => {
    state.logLines = [];
    log("INFO", "Logs cleared");
    renderLogs();
  });

  elements.warningButton.addEventListener("click", () => {
    const device = getSelectedDevice();
    const diagnostics = state.diagnosticsByDevice[device.id];
    device.status = device.status === STATUS.ERROR ? STATUS.WARNING : STATUS.ERROR;
    diagnostics.errorCount += 1;
    diagnostics.packetLoss = device.status === STATUS.ERROR ? 12.5 : 7.8;
    diagnostics.alarmState = "Active";
    log(device.status === STATUS.ERROR ? "ERROR" : "WARN", `Manual state simulation for ${device.id}`);
    renderAll();
  });
}

function getSystemStatus(systemDevices) {
  if (systemDevices.some((device) => device.status === STATUS.ERROR)) {
    return STATUS.ERROR;
  }
  if (systemDevices.some((device) => device.status === STATUS.WARNING)) {
    return STATUS.WARNING;
  }
  if (systemDevices.length === 0 || systemDevices.every((device) => device.status === STATUS.OFFLINE)) {
    return STATUS.OFFLINE;
  }
  return STATUS.ONLINE;
}

function getLatestUpdate(systemDevices) {
  const timestamps = systemDevices
    .map((device) => device.lastSeen)
    .filter(Boolean)
    .map((date) => date.getTime());

  if (!timestamps.length) {
    return "--:--:--";
  }

  return formatTime(new Date(Math.max(...timestamps)));
}

function getSelectedDevice() {
  return devices.find((device) => device.id === state.selectedDeviceId) || devices[0];
}

function signalMeter(value) {
  return `
    <div class="signal-bar">
      <span>${value}%</span>
      <span class="signal-track"><span class="signal-fill" style="width: ${value}%"></span></span>
    </div>
  `;
}

function statusClass(status) {
  return `status-${status.toLowerCase()}`;
}

function log(level, message) {
  const paddedLevel = level.padEnd(5, " ");
  state.logLines.push({
    level: level.toLowerCase(),
    text: `[${formatTime(new Date())}] ${paddedLevel} ${message}`
  });

  if (state.logLines.length > 180) {
    state.logLines.shift();
  }
}

function formatTime(date) {
  if (!(date instanceof Date) || Number.isNaN(date.getTime())) {
    return "--:--:--";
  }

  return date.toLocaleTimeString("en-GB", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit"
  });
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function round1(value) {
  return Math.round(value * 10) / 10;
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomRange(min, max) {
  return Math.random() * (max - min) + min;
}

function bootstrap() {
  cacheElements();
  initializeState();
  bindEvents();
  updateClock();
  log("INFO", "Web display initialized");
  log("INFO", "Local simulation active; no network socket opened");
  processSelectedDevicePacket();
  renderAll();
  setInterval(simulationTick, 1500);
  setInterval(updateClock, 1000);
}

document.addEventListener("DOMContentLoaded", bootstrap);
