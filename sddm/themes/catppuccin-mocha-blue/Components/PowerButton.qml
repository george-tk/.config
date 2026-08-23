import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
  implicitHeight: powerButton.height
  implicitWidth: powerButton.width
  Button {
    id: powerButton
    height: inputHeight
    width: inputHeight
    hoverEnabled: true
    icon {
      source: Qt.resolvedUrl("../icons/power.svg")
      height: height * 0.55
      width: width * 0.55
      color: "#CDD6F4"
    }
    background: Rectangle {
      id: powerButtonBackground
      radius: 0
      color: "#1E1E2E"
      border.width: 3
      border.color: "#313244"
    }
    states: [
      State {
        name: "hovered"
        when: powerButton.hovered
        PropertyChanges {
          target: powerButtonBackground
          color: "#313244"
          border.color: "#45475A"
        }
      }
    ]
    transitions: Transition {
      PropertyAnimation {
        properties: "color,border.color"
        duration: 200
      }
    }
    onClicked: sddm.powerOff()
  }
}
