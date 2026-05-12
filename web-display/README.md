# ControlDesk Web Display

This folder contains a standalone HTML5 display prototype for ControlDesk. It represents an onboard marine or industrial monitor that could be shown on a vessel display, diagnostic panel, or local engineering terminal.

The Lazarus/Object Pascal project remains the main desktop engineering and configuration tool. This web display mirrors its concept, demo devices, diagnostic values, status model, packet format, and log behavior without mixing HTML, CSS, or JavaScript into the Lazarus source files.

## Files

- `index.html` - static dashboard markup.
- `styles.css` - dark industrial display styling and responsive layout.
- `app.js` - mock device data, diagnostics simulation, packet builder, UI rendering, interactions, and logging.

## Run

Open `index.html` directly in a modern browser. No server, build tool, package manager, CDN, or external dependency is required.

## Current Behavior

- Shows a vessel system overview for Bridge, Alarm System, Engine Room, Power System, and Communication Bus.
- Lists simulated ControlDesk devices such as AHD-570, LCU, alarm display, engine controller, voltage monitor, and communication gateway.
- Updates diagnostics every 1.5 seconds using local JavaScript timers.
- Builds simulated protocol packets in this format:

```text
$DEV,<DEVICE_ID>,TEMP,<temperature>,RPM,<rpm>,VOLT,<voltage>,CURR,<current>,SIGNAL,<signal_quality>,ERR,<error_count>#
```

- Logs RX/TX activity, warnings, errors, ACK messages, and selected-device changes.
- Supports selecting devices, pausing or resuming the simulation, clearing logs, and manually simulating warning/error states.

## Limitations

- This is a static local prototype only.
- It does not fetch external scripts, connect to sockets, read local files, store credentials, or talk to real devices.
- Diagnostics are generated in browser memory and are not synchronized with the Lazarus desktop application.
- Packet parsing is not implemented in this first web-display version; only packet generation is simulated.
