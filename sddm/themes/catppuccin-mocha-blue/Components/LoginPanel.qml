import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import "../assets"

Item {
  property var user: userField.text
  property var password: passwordField.text
  property var session: sessionPanel.session
  property var inputHeight: 50
  property var inputWidth: 300
  Rectangle {
    id: loginBackground
    anchors {
      verticalCenter: parent.verticalCenter
      horizontalCenter: parent.horizontalCenter
    }
    height: inputHeight * ( config.UserIcon == "true" ? 11.2 : 5.3 )
    width: inputWidth * 1.2
    radius: 0
    border.width: 3
    border.color: "#313244"
    visible: config.LoginBackground == "true" ? true : false
    color: "#181825"
  }
  Column {
    spacing: 16
    z: 5
    width: inputWidth
    anchors {
      verticalCenter: parent.verticalCenter
      horizontalCenter: parent.horizontalCenter
    }
    UserField {
      id: userField
      height: inputHeight
      width: parent.width
      visible: true
    }
    PasswordField {
      id: passwordField
      height: inputHeight
      width: parent.width
      onAccepted: loginButton.clicked()
    }
    Row {
      spacing: 12
      anchors.horizontalCenter: parent.horizontalCenter
      SessionPanel {
        id: sessionPanel
      }
      SleepButton {
        id: sleepButton
      }
      RebootButton {
        id: rebootButton
      }
      PowerButton {
        id: powerButton
      }
    }
    Button {
      id: loginButton
      height: 0
      width: 0
      visible: false
      enabled: user != "" && password != "" ? true : false
      onClicked: {
        sddm.login(user, password, session)
      }
    }
  }
  Connections {
    target: sddm

    function onLoginFailed() {
      passwordField.text = ""
      passwordField.focus = true
    }
  }
}
