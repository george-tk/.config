import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
  implicitHeight: rebootButton.height
  implicitWidth: rebootButton.width
  Button {
    id: rebootButton
    height: inputHeight
    width: inputHeight
    hoverEnabled: true
    icon {
      source: Qt.resolvedUrl("../icons/reboot.svg")
      height: height
      width: width
      color: "#11111B"
    }
    background: Rectangle {
      id: rebootButtonBackground
      radius: 6
      color: "#B4BEFE"
    }
    states: [
      State {
        name: "hovered"
        when: rebootButton.hovered
        PropertyChanges {
          target: rebootButtonBackground
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
    onClicked: sddm.reboot()
  }
}
