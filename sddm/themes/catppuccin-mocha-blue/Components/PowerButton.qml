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
      height: height
      width: width
      color: "#11111B"
    }
    background: Rectangle {
      id: powerButtonBackground
      radius: 6
      color: "#B4BEFE"
    }
    states: [
      State {
        name: "hovered"
        when: powerButton.hovered
        PropertyChanges {
          target: powerButtonBackground
          color: "#CDD6F4"
        }
      }
    ]
    transitions: Transition {
      PropertyAnimation {
        properties: "color"
        duration: 300
      }
    }
    onClicked: sddm.powerOff()
  }
}
