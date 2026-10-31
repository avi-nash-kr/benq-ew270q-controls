# BenQ EW270Q Controls for Omarchy

A Quickshell bar widget for Omarchy that controls the BenQ EW270Q monitor over
DDC/CI. Click the monitor icon to adjust brightness, monitor speaker volume,
and color temperature presets.

This is an independent community plugin and is not affiliated with BenQ.

## Requirements

- Omarchy with its Quickshell shell and plugin support
- `ddcutil`
- A DDC/CI-enabled monitor connection; enable DDC/CI in the monitor's OSD if
  necessary

The widget uses VCP features 10 (brightness), 62 (speaker volume), and 14
(color preset). Monitor support for a feature can vary by model and firmware.

## Install

Install `ddcutil` using your distribution's package manager, then run:

```bash
omarchy plugin add https://github.com/avi-nash-kr/benq-ew270q-controls --enable
```

The plugin is placed in the right section of the bar by default. If the
EW270Q is not DDC display 1 on your system, set the plugin's `display` value
in its bar layout entry. For example:

```json
{ "id": "benq-ew270q-controls", "display": 2 }
```

You can find the display number with:

```bash
ddcutil detect --brief
```

## License

MIT. See [LICENSE](LICENSE).
