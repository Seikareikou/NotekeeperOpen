import QtQuick 1.1
// import "." 1.0
import com.nokia.meego 1.1
import "Utils.js" as Utils
import "EditBubble.js" as Popup
import "SelectionHandles.js" as Private

Item {
    id: contents

    // Styling for the Label
    property Style platformStyle: SelectionHandlesStyle{}

    //Deprecated, TODO Remove this some day
    property alias style: contents.platformStyle

    property Item textInput: null

    property variant selectionStartRect: textInput ? textInput.positionToRectangle( textInput.selectionStart ) : Qt.rect(0,0,0,0);
    property variant selectionEndRect: textInput ? textInput.positionToRectangle( textInput.selectionEnd ) : Qt.rect(0,0,0,0);

    property variant selectionStartPoint: Qt.point(0,0)
    property variant selectionEndPoint: Qt.point(0,0)

    property alias leftSelectionHandle: leftSelectionImage
    property alias rightSelectionHandle: rightSelectionImage

    property alias privateRect: rect
    property bool privateIgnoreClose: false

    onSelectionStartRectChanged: {
        Private.adjustPosition(contents);
    }
    onSelectionEndRectChanged: {
        Private.adjustPosition(contents);
    }

    Item {
        id: rect
        objectName: "selectionHandles"
        // fake baseline since the baseline of a font is not accessible in QML (except for anchors which doesn't work well here):
        property int fontBaseLine: textInput ? textInput.font.pixelSize * 0.16 : 0

        z: 1030 // Have the small selection handles above the big copy-paste bubble

        // Function to calculate whether the handle positions are out of the view area:

        function outOfView( rootX, rootY, offset ) {
            var point = contents.mapToItem( textInput, rootX, rootY );
            return (point.x - offset) < 0 || ( textInput != null  && (point.x - offset) > textInput.width );
        }

        Image {
            id: leftSelectionImage
            objectName: "leftSelectionImage"
              property variant dragStart: Qt.point(0,0); // required for selection across multiple lines
              property int offset: -width/2;
              property int animationDuration: leftSelectionMouseArea.pressed ? 350 : 0
              x: selectionStartPoint.x + offset;
              y: selectionStartPoint.y + contents.selectionStartRect.height - 10 - rect.fontBaseLine; // vertical offset: 4 pixels
              visible: y > Utils.statusBarCoveredHeight( contents );
              source: platformStyle.leftSelectionHandle
              property bool pressed: leftSelectionMouseArea.pressed;
              property bool outOfView: rect.outOfView(x, y, offset);
              onXChanged: outOfView = rect.outOfView(x, y, offset)

              MouseArea {
                  id: leftSelectionMouseArea
                  anchors.fill: parent
                  onPressed: {
                      if (Popup.isOpened(textInput)) {
                          Popup.close(textInput);
                      }
                      leftSelectionImage.dragStart = Qt.point( mouse.x, mouse.y );
                  }
                  onPositionChanged: {
                      var pixelpos = mapToItem( textInput, mouse.x, mouse.y );
                      var ydelta = pixelpos.y - leftSelectionImage.dragStart.y;  // Determine the line distance
                      if ( ydelta < 0 ) ydelta = 0;  // Avoid jumpy text selection
                      var pos = textInput.positionAt(pixelpos.x, ydelta);
                      var h = textInput.selectionEnd;
                      privateIgnoreClose = true;    // Avoid closing the handles while setting the cursor position
                      if (pos >= h) {
                          textInput.cursorPosition = h; // proper autoscrolling
                          pos = h - 1;  // Ensure at minimum one character between selection handles
                      }
                      textInput.select(h,pos); // Select by character
                      privateIgnoreClose = false;
                  }
                  onReleased: {
                      Popup.open(textInput,textInput.positionToRectangle(textInput.cursorPosition));
                  }
              }

              states: [
                  State {
                      name: "normal"
                      when: !leftSelectionImage.outOfView && !leftSelectionImage.pressed && !rightSelectionImage.pressed
                      PropertyChanges { target: leftSelectionImage; opacity: 1.0 }
                  },
                  State {
                      name: "pressed"
                      when: !leftSelectionImage.outOfView && leftSelectionImage.pressed
                      PropertyChanges { target: leftSelectionImage; opacity: 0.0 }
                  },
                  State {
                      name: "otherpressed"
                      when: !leftSelectionImage.outOfView && rightSelectionImage.pressed
                      PropertyChanges { target: leftSelectionImage; opacity: 0.7 }
                  },
                  State {
                      name: "outofview"
                      when: leftSelectionImage.outOfView
                      PropertyChanges { target: leftSelectionImage; opacity: 0.0 }
                  }
              ]

              transitions: [
                  Transition {
                      from: "pressed"; to: "normal"
                      NumberAnimation {target: leftSelectionImage; property: "opacity";
                                    easing.type: Easing.InOutQuad;
                                    from: 0.0; to: 1.0; duration: 350}
                  },
                  Transition {
                      from: "normal"; to: "pressed"
                      NumberAnimation {target: leftSelectionImage; property: "opacity";
                                    easing.type: Easing.InOutQuad;
                                    from: 1.0; to: 0.0; duration: 350}
                  },
                  Transition {
                      from: "otherpressed"; to: "normal"
                      NumberAnimation {target: leftSelectionImage; property: "opacity";
                                    easing.type: Easing.InOutQuad;
                                    from: 0.7; to: 1.0; duration: 350}
                  },
                  Transition {
                      from: "normal"; to: "otherpressed"
                      NumberAnimation {target: leftSelectionImage; property: "opacity";
                                    easing.type: Easing.InOutQuad;
                                    from: 1.0; to: 0.7; duration: 350}
                  }
              ]
        }

        Image {
            id: rightSelectionImage
            objectName: "rightSelectionImage"
              property variant dragStart: Qt.point(0,0); // required for selection across multiple lines
              property int offset: -width/2;
              property int animationDuration: rightSelectionMouseArea.pressed ? 350 : 0
              x: selectionEndPoint.x + offset;
              y: selectionEndPoint.y + contents.selectionEndRect.height - 10 - rect.fontBaseLine; // vertical offset: 4 pixels
              visible: y > Utils.statusBarCoveredHeight( contents );
              source: platformStyle.rightSelectionHandle;
              property bool pressed: rightSelectionMouseArea.pressed;
              property bool outOfView: rect.outOfView(x, y, offset);
              onXChanged: outOfView = rect.outOfView(x, y, offset);

              MouseArea {
                  id: rightSelectionMouseArea
                  anchors.fill: parent
                  onPressed: {
                      if (Popup.isOpened(textInput)) {
                          Popup.close(textInput);
                      }
                      rightSelectionImage.dragStart = Qt.point( mouse.x, mouse.y );
                  }
                  onPositionChanged: {
                      var pixelpos = mapToItem( textInput, mouse.x, mouse.y );
                      var ydelta = pixelpos.y - rightSelectionImage.dragStart.y;  // Determine the line distance
                      if ( ydelta < 0 ) ydelta = 0;  // Avoid jumpy text selection
                      var pos = textInput.positionAt(pixelpos.x, ydelta);
                      var h = textInput.selectionStart;
                      privateIgnoreClose = true;    // Avoid closing the handles while setting the cursor position
                      if (pos <= h) {
                          textInput.cursorPosition = h; // proper autoscrolling
                          pos = h + 1;  // Ensure at minimum one character between selection handles
                      }
                      textInput.select(h,pos); // Select by character
                      privateIgnoreClose = false;
                 }
                 onReleased: {
                      // trim to word selection
                      Popup.open(textInput,textInput.positionToRectangle(textInput.cursorPosition));
                 }
             }

              states: [
                  State {
                      name: "normal"
                      when:  !rightSelectionImage.outOfView && !leftSelectionImage.pressed && !rightSelectionImage.pressed
                      PropertyChanges { target: rightSelectionImage; opacity: 1.0 }
                  },
                  State {
                      name: "pressed"
                      when:  !rightSelectionImage.outOfView && rightSelectionImage.pressed
                      PropertyChanges { target: rightSelectionImage; opacity: 0.0 }
                  },
                  State {
                      name: "otherpressed"
                      when: !rightSelectionImage.outOfView && leftSelectionImage.pressed
                      PropertyChanges { target: rightSelectionImage; opacity: 0.7 }
                  },
                  State {
                      name: "outofview"
                      when: rightSelectionImage.outOfView
                      PropertyChanges { target: rightSelectionImage; opacity: 0.0 }
                  }
              ]

              transitions: [
                  Transition {
                      from: "pressed"; to: "normal"
                      NumberAnimation {target: rightSelectionImage; property: "opacity";
                                    easing.type: Easing.InOutQuad;
                                    from: 0.0; to: 1.0; duration: 350}
                  },
                  Transition {
                      from: "normal"; to: "pressed"
                      NumberAnimation {target: rightSelectionImage; property: "opacity";
                                    easing.type: Easing.InOutQuad;
                                    from: 1.0; to: 0.0; duration: 350}
                  },
                  Transition {
                      from: "otherpressed"; to: "normal"
                      NumberAnimation {target: rightSelectionImage; property: "opacity";
                                    easing.type: Easing.InOutQuad;
                                    from: 0.7; to: 1.0; duration: 350}
                  },
                  Transition {
                      from: "normal"; to: "otherpressed"
                      NumberAnimation {target: rightSelectionImage; property: "opacity";
                                    easing.type: Easing.InOutQuad;
                                    from: 1.0; to: 0.7; duration: 350}
                  }
              ]
        }
    }

    Connections {
        target: Utils.findFlickable(textInput)
        onContentXChanged: Private.adjustPosition(contents)
        onContentYChanged: Private.adjustPosition(contents)
    }

    Connections {
        target: screen
        onCurrentOrientationChanged: Private.adjustPosition(contents)
    }

    function findWindowRoot() {
        var item = Utils.findRootItem(contents, "windowRoot");
        if (item.objectName != "windowRoot")
            item = Utils.findRootItem(contents, "pageStackWindow");
        return item;
    }

    Connections {
       target: findWindowRoot();
       ignoreUnknownSignals: true
       onOrientationChangeFinished: {
           Private.adjustPosition(contents)
       }
    }

    state: "closed"

    states: [
        State {
            name: "opened"
            ParentChange { target: rect; parent: Utils.findRootItem(textInput); }
            PropertyChanges { target: rect; visible: true; }
        },
        State {
            name: "closed"
            ParentChange { target: rect; parent: contents; }
            PropertyChanges { target: rect; visible: false; }
        }
    ]

    transitions: [
        Transition {
            from: "closed"; to: "opened"
            NumberAnimation {target: rect; property: "opacity";
                          easing.type: Easing.InOutQuad;
                          from: 0.0; to: 1.0; duration: 350}
        },
        Transition {
            from: "opened"; to: "closed"
            NumberAnimation {target: rect; property: "opacity";
                          easing.type: Easing.InOutQuad;
                          from: 1.0; to: 0.0; duration: 350}
        }
    ]
}
