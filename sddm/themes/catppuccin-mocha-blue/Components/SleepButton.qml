import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
  implicitHeight: sleepButton.height
  implicitWidth: sleepButton.width
  Button {
    id: sleepButton
    height: inputHeight
    width: inputHeight
    hoverEnabled: true
    icon {
      source: Qt.resolvedUrl("../icons/sleep.svg")
      height: height * 0.55
      width: width * 0.55
      color: "#CDD6F4"
    }
    background: Rectangle {
      id: sleepButtonBg
      radius: 0
      color: "#1E1E2E"
      border.width: 3
      border.color: "#313244"
    }
    states: [
      State {
        name: "hovered"
        when: sleepButton.hovered
        PropertyChanges {
          target: sleepButtonBg
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
    onClicked: sddm.suspend()
  }
}
