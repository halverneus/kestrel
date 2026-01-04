import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    property real hue: 0.0
    property real saturation: 1.0
    property real brightness: 1.0

    property color fullBrightnessColor: {
        var rgb = hsvToRgb(hue, saturation, 1.0)
        return Qt.rgba(rgb.r / 255, rgb.g / 255, rgb.b / 255, 1)
    }

    property string currentHexColor: {
        var rgb = hsvToRgb(hue, saturation, brightness)
        return rgbToHex(rgb.r, rgb.g, rgb.b)
    }

    function hsvToRgb(h, s, v) {
        var r, g, b
        var i = Math.floor(h * 6)
        var f = h * 6 - i
        var p = v * (1 - s)
        var q = v * (1 - f * s)
        var t = v * (1 - (1 - f) * s)

        switch (i % 6) {
            case 0: r = v; g = t; b = p; break
            case 1: r = q; g = v; b = p; break
            case 2: r = p; g = v; b = t; break
            case 3: r = p; g = q; b = v; break
            case 4: r = t; g = p; b = v; break
            case 5: r = v; g = p; b = q; break
        }

        return {
            r: Math.round(r * 255),
            g: Math.round(g * 255),
            b: Math.round(b * 255)
        }
    }

    function rgbToHex(r, g, b) {
        return ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1).toUpperCase()
    }

    onCurrentHexColorChanged: {
        updateTimer.restart()
    }

    Timer {
        id: updateTimer
        interval: 50
        onTriggered: {
            executable.exec("set-keyboard-light color " + currentHexColor)
        }
    }

    compactRepresentation: MouseArea {
        id: compactRoot

        implicitWidth: Kirigami.Units.iconSizes.medium
        implicitHeight: Kirigami.Units.iconSizes.medium

        onClicked: root.expanded = !root.expanded

        Kirigami.Icon {
            anchors.fill: parent
            source: "input-keyboard"
            color: "#" + currentHexColor
            isMask: true
        }
    }

    fullRepresentation: ColumnLayout {
        spacing: 10
        Layout.preferredWidth: 280
        Layout.preferredHeight: 320

        // Color wheel
        Item {
            id: wheelContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            Layout.alignment: Qt.AlignHCenter

            Canvas {
                id: colorWheel
                anchors.centerIn: parent
                width: 200
                height: 200

                property real wheelRadius: width / 2

                onPaint: {
                    var ctx = getContext("2d")
                    var centerX = width / 2
                    var centerY = height / 2
                    var radius = wheelRadius

                    ctx.clearRect(0, 0, width, height)

                    // Draw color wheel
                    for (var angle = 0; angle < 360; angle++) {
                        var startAngle = (angle - 1) * Math.PI / 180
                        var endAngle = (angle + 1) * Math.PI / 180

                        for (var sat = 0; sat < radius; sat += 2) {
                            var satRatio = sat / radius
                            var rgb = hsvToRgb(angle / 360, satRatio, root.brightness)
                            ctx.fillStyle = "rgb(" + rgb.r + "," + rgb.g + "," + rgb.b + ")"
                            ctx.beginPath()
                            ctx.arc(centerX, centerY, sat + 2, startAngle, endAngle)
                            ctx.arc(centerX, centerY, sat, endAngle, startAngle, true)
                            ctx.fill()
                        }
                    }
                }

                function hsvToRgb(h, s, v) {
                    return root.hsvToRgb(h, s, v)
                }

                MouseArea {
                    id: wheelMouse
                    anchors.fill: parent

                    function updateColor(mouseX, mouseY) {
                        var centerX = width / 2
                        var centerY = height / 2
                        var dx = mouseX - centerX
                        var dy = mouseY - centerY
                        var distance = Math.sqrt(dx * dx + dy * dy)
                        var radius = colorWheel.wheelRadius

                        if (distance <= radius) {
                            var angle = Math.atan2(dy, dx)
                            var hue = angle / (2 * Math.PI)
                            if (hue < 0) hue += 1
                            root.hue = hue
                            root.saturation = Math.min(distance / radius, 1.0)
                        }
                    }

                    onPressed: (mouse) => updateColor(mouse.x, mouse.y)
                    onPositionChanged: (mouse) => {
                        if (pressed) updateColor(mouse.x, mouse.y)
                    }
                }

                // Selection indicator
                Rectangle {
                    id: selector
                    width: 16
                    height: 16
                    radius: 8
                    border.color: root.brightness > 0.5 ? "black" : "white"
                    border.width: 2
                    color: "transparent"

                    x: colorWheel.width / 2 + Math.cos(root.hue * 2 * Math.PI) * (root.saturation * colorWheel.wheelRadius) - width / 2
                    y: colorWheel.height / 2 + Math.sin(root.hue * 2 * Math.PI) * (root.saturation * colorWheel.wheelRadius) - height / 2
                }
            }

            Connections {
                target: root
                function onBrightnessChanged() {
                    colorWheel.requestPaint()
                }
            }
        }

        // Brightness slider with gradient
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            Layout.leftMargin: 20
            Layout.rightMargin: 20

            Rectangle {
                id: brightnessTrack
                anchors.fill: parent
                anchors.margins: 5
                radius: 4
                border.color: "gray"
                border.width: 1

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "black" }
                    GradientStop { position: 1.0; color: root.fullBrightnessColor }
                }

                Rectangle {
                    id: brightnessHandle
                    width: 12
                    height: parent.height + 6
                    radius: 3
                    color: "white"
                    border.color: "gray"
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.brightness * (parent.width - width)
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: (mouse) => updateBrightness(mouse.x)
                    onPositionChanged: (mouse) => {
                        if (pressed) updateBrightness(mouse.x)
                    }

                    function updateBrightness(mouseX) {
                        var newBrightness = Math.max(0, Math.min(1, mouseX / width))
                        root.brightness = newBrightness
                        executable.exec("set-keyboard-light brightness " + Math.round(newBrightness * 255))
                    }
                }
            }
        }

        // Current color display
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20

            Rectangle {
                width: 40
                height: 30
                color: "#" + currentHexColor
                border.color: "gray"
                border.width: 1
                radius: 4
            }

            Label {
                text: "#" + currentHexColor
                font.family: "monospace"
                Layout.fillWidth: true
            }
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
        }
        function exec(cmd) {
            connectSource(cmd)
        }
    }
}
