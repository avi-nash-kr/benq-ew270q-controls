import QtQuick
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "benq-ew270q-controls"

  readonly property string displayNumber: String(setting("display", 1))

  property bool popupOpen: false
  property int brightness: 0
  property int volume: 0
  property int colorPreset: -1
  property string statusError: ""
  property bool setQueued: false
  property int queuedFeature: 0
  property int queuedValue: 0

  function parseValue(output) {
    var text = String(output || "")
    var match = text.match(/current value\s*=\s*(\d+)/i)
    if (!match) match = text.match(/Volume level:\s*(\d+)/i)
    return match ? Number(match[1]) : -1
  }

  function refresh() {
    if (!brightnessProc.running && !setProc.running) brightnessProc.running = true
    if (!volumeProc.running && !setProc.running) volumeProc.running = true
    if (!colorProc.running && !setProc.running) colorProc.running = true
  }

  function setValue(feature, value) {
    if (setProc.running) {
      queuedFeature = feature
      queuedValue = value
      setQueued = true
      return
    }

    setProc.command = ["ddcutil", "--display", root.displayNumber, "setvcp", String(feature), String(value)]
    setProc.running = true
  }

  function runQueuedSet() {
    if (!setQueued) return
    var feature = queuedFeature
    var value = queuedValue
    setQueued = false
    setValue(feature, value)
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 5000
    repeat: true
    running: root.popupOpen
    onTriggered: root.refresh()
  }

  Process {
    id: brightnessProc
    command: ["ddcutil", "--display", root.displayNumber, "getvcp", "10"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var value = root.parseValue(text)
        if (value >= 0) root.brightness = value
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.statusError = "Could not read monitor brightness."
    }
  }

  Process {
    id: volumeProc
    command: ["ddcutil", "--display", root.displayNumber, "getvcp", "62"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var value = root.parseValue(text)
        if (value >= 0) root.volume = value
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.statusError = "Could not read monitor volume."
    }
  }

  Process {
    id: colorProc
    command: ["ddcutil", "--display", root.displayNumber, "getvcp", "14"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var match = String(text || "").match(/:\s.*\(0x([0-9a-f]+)\),\s*Tolerance/i)
        if (match) root.colorPreset = parseInt(match[1], 16)
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.statusError = "Could not read monitor color mode."
    }
  }

  Process {
    id: setProc
    stderr: StdioCollector { id: setError; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        var detail = String(setError.text || "").trim()
        root.statusError = detail !== "" ? detail : "Monitor setting could not be changed."
      } else {
        root.statusError = ""
      }
      root.runQueuedSet()
      if (!root.setQueued) root.refresh()
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf108"
    fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
    fontSize: Style.font.icon
    horizontalMargin: 7.5
    tooltipText: "BenQ EW270Q controls"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.MiddleButton) root.refresh()
      else root.popupOpen = !root.popupOpen
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(310))
    contentHeight: popup.fittedContentHeight(contentColumn.implicitHeight)

    Column {
      id: contentColumn
      anchors.fill: parent
      spacing: Style.space(12)

      Text {
        text: "BenQ EW270Q"
        color: root.bar ? root.bar.foreground : "#ffffff"
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.subtitle
        font.bold: true
      }

      Column {
        width: parent.width
        spacing: Style.space(4)

        Item {
          width: parent.width
          height: Math.max(sectionLabel.implicitHeight, sectionValue.implicitHeight)
          Text {
            id: sectionLabel
            text: "Brightness"
            color: root.bar ? root.bar.foreground : "#ffffff"
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            anchors.left: parent.left
          }
          Text {
            id: sectionValue
            anchors.right: parent.right
            text: Math.round(brightnessSlider.dragging ? brightnessSlider.liveValue : root.brightness) + "%"
            color: root.bar ? root.bar.foreground : "#ffffff"
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
          }
        }

        PanelSlider {
          id: brightnessSlider
          width: parent.width
          bar: root.bar
          minimum: 0
          maximum: 100
          step: 1
          integer: true
          value: root.brightness
          onReleased: function(value) { root.setValue(10, Math.round(value)) }
        }
      }

      Column {
        width: parent.width
        spacing: Style.space(4)

        Item {
          width: parent.width
          height: Math.max(volumeLabel.implicitHeight, volumeValue.implicitHeight)
          Text {
            id: volumeLabel
            text: "Monitor volume"
            color: root.bar ? root.bar.foreground : "#ffffff"
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            anchors.left: parent.left
          }
          Text {
            id: volumeValue
            anchors.right: parent.right
            text: Math.round(volumeSlider.dragging ? volumeSlider.liveValue : root.volume) + "%"
            color: root.bar ? root.bar.foreground : "#ffffff"
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
          }
        }

        PanelSlider {
          id: volumeSlider
          width: parent.width
          bar: root.bar
          minimum: 0
          maximum: 100
          step: 1
          integer: true
          value: root.volume
          onReleased: function(value) { root.setValue(62, Math.round(value)) }
        }
      }

      Column {
        width: parent.width
        spacing: Style.space(5)

        Text {
          text: "Color temperature"
          color: root.bar ? root.bar.foreground : "#ffffff"
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }

        Row {
          width: parent.width
          spacing: Style.space(4)

          Button {
            text: "5000 K"
            active: root.colorPreset === 4
            onClicked: root.setValue(14, 4)
          }
          Button {
            text: "6500 K"
            active: root.colorPreset === 5
            onClicked: root.setValue(14, 5)
          }
          Button {
            text: "9300 K"
            active: root.colorPreset === 8
            onClicked: root.setValue(14, 8)
          }
          Button {
            text: "User 1"
            active: root.colorPreset === 11
            onClicked: root.setValue(14, 11)
          }
        }
      }

      Text {
        visible: root.statusError !== ""
        width: parent.width
        text: root.statusError
        color: root.bar ? root.bar.urgent : "#ff5555"
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.Wrap
      }
    }
  }
}
