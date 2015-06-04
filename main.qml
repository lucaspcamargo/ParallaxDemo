import QtQuick 2.4
import QtSensors 5.3
import QtQuick.Window 2.2

Window {

    title: qsTr("pd")
    visible: true
    visibility: Window.FullScreen
    id: window

    property real pX: 0
    property real pY: 0

    Behavior on pX {
        NumberAnimation {duration: 30}
    }

    Behavior on pY {
        NumberAnimation {duration: 30
        }
    }

    RotationSensor
    {
        id: rotationSensor

        active: true
        alwaysOn: true

        property real compensationAngle: 50

        onReadingChanged: {

            var yTilt = Math.round((-reading.x + 90) * (40/180) - 40);

            var xTilt = Math.round((-reading.y + 90 - compensationAngle ) * (40/180) - 40);

            if (xTilt > 0) {
                xTilt = -xTilt;
            } else if (xTilt < -40) {
                xTilt = -(xTilt + 80);
            }

            pX = -yTilt - 20;
            pY = -xTilt - 20;

        }

    }




    Image
    {
        id: albedoSource
        anchors.fill: parent
        visible: false
        source: "res/rgb-0.png"
    }

    Image
    {
        id: depthSource
        anchors.fill: parent
        visible: false
        source: "res/z-0.png"
    }

    ShaderEffect
    {
        id: parallaxRenderer
        mesh: Qt.size(256,144)
        //Qt.size(Math.round(parent.width/coarseness), Math.round(parent.height/coarseness))

        anchors.fill: parent
        visible: testSurface.opacity != 1.0

        property int coarseness: 5

        property var albedo: albedoSource
        property var depth: depthSource

        property real dx: 20 * pX / width
        property real dy: 20 * pY / height

        scale: 1.2


        vertexShader: "
            uniform highp mat4 qt_Matrix;
            attribute highp vec4 qt_Vertex;
            attribute highp vec2 qt_MultiTexCoord0;
            varying highp vec2 coord;

            uniform highp float dx;
            uniform highp float dy;
            uniform sampler2D depth;

            void main() {
                coord = qt_MultiTexCoord0;
                gl_Position = qt_Matrix * qt_Vertex;

                lowp vec4 tex = texture2D(depth, coord);

                gl_Position.xy += vec2(tex.r) * vec2(dx, dy);
                gl_Position.z -= 0.05 * tex.r;
            }"
        fragmentShader: "
            varying highp vec2 coord;
            uniform sampler2D albedo;

            uniform lowp float qt_Opacity;
            void main() {
                lowp vec4 tex = texture2D(albedo, coord);
                gl_FragColor = tex * qt_Opacity;
            }"


    }

    property real d: width / 3

    Rectangle {

        id: testSurface

        anchors.fill: parent
        property int trail: 5
        opacity: 0

        color: "#222"

        Repeater{

            model: testSurface.trail

            Rectangle
            {
                color: "#000080"
                width: d
                height: d

                anchors.centerIn: parent

                anchors.horizontalCenterOffset: pX * 3 * (index+1)
                anchors.verticalCenterOffset: pY * 3 * (index+1)
                opacity: 1 - (index + 1) / testSurface.trail
            }
        }

        Rectangle
        {
            id: top

            color: "darkred"
            width: d
            height: d

            anchors.centerIn: parent
        }

        Rectangle
        {
            id: topShine

            color: "white"
            width: d
            height: d

            opacity: Math.min( 1, Math.sqrt(pX^2 + pY ^2) / 20 )
            Behavior on opacity { NumberAnimation {} }

            anchors.centerIn: parent
        }

        Text
        {
            anchors.centerIn: parent
            text: rotationSensor.reading.x.toFixed(3) + "\n" + rotationSensor.reading.y.toFixed(3) + "\n" + rotationSensor.reading.z.toFixed(3)
            font.family: "monospace"

            anchors.horizontalCenterOffset: -pX * 3
            anchors.verticalCenterOffset: -pY * 3
            color: "white"
        }
    }

    MouseArea
    {
        anchors.fill: parent
        onClicked: testSurface.opacity = (testSurface.opacity == 1? 0 : 1)
    }

    Rectangle
    {

        id: footer

        anchors.bottom: parent.bottom
        color: "#dd222222"

        height: parent.height/15
        width: parent.width

        Rectangle
        {
            anchors.bottom: parent.top
            color: "#0071C5"

            height: parent.height/15
            width: parent.width
        }

        Text
        {
            font.pixelSize: parent.height / 2
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: "Real Sense™ for Mobile Devices Demo: Parallax Rendering"
            color: "#ccc"
        }
    }

}
