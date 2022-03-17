import QtQuick 2.12
import QtQuick.Window 2.12
import QtLocation 5.12
import QtQuick.Controls 2.12
import QtPositioning 5.12
import QtQml 2.12

Window {
    id: window
    width: 640
    height: 480
    visible: true
    title: qsTr("Google Maps test")


    Plugin{
        id: gmap
        name: "osm"
        PluginParameter { name: "osm.mapping.providersrepository.address"; value: Qt.resolvedUrl("./providers/map/") }
        PluginParameter { name: "osm.mapping.cache.directory"; value: "cache" }
        PluginParameter { name: "osm.mapping.cache.disk.size"; value: 0 }
    }

    Plugin{
        id: gsat
        name: "osm"
        PluginParameter { name: "osm.mapping.providersrepository.address"; value: Qt.resolvedUrl("./providers/satellite/") }
        PluginParameter { name: "osm.mapping.cache.directory"; value: "cache" }
        PluginParameter { name: "osm.mapping.cache.disk.size"; value: 0 }
    }

    Map{
        id: map1
        anchors.fill: layers
        plugin: gsat
        center: map2.center
        tilt: map2.tilt
        bearing: map2.bearing

        onCenterChanged: layers.setupAnimations(layers.myLocation)

        onZoomLevelChanged:{
            if(mouseArea1.swapped){
                layers.zoomLevel = zoomLevel
                map2.zoomLevel = zoomLevel - layers.zoomFactor
            }
        }

        MapQuickItem {
            id: marker1
            coordinate: layers.myLocation
            anchorPoint.x: myLocationCircle1.width/2
            anchorPoint.y: myLocationCircle1.height
            sourceItem: Rectangle{
                id: myLocationCircle1
                width: mouseArea1.swapped ? 20 : 10
                height: width
                radius: width/2
                color: "#5384ed"
                border.width: mouseArea1.swapped ? 2 : 1
                border.color: "white"
            }
        }

        Binding on anchors.fill{
            when: mouseArea1.clicked
            value: mouseArea1.swapped ? map1.parent : layers
        }

        Binding on z{
            when: mouseArea1.clicked
            value: mouseArea1.swapped ? 0 : 1
        }

        Binding on copyrightsVisible{
            when: mouseArea1.clicked
            value: mouseArea1.swapped
        }

    }


    Map{
        id: map2
        anchors.fill: parent
        plugin: gmap
        center: map1.center
        tilt: map1.tilt
        bearing: map1.bearing

        onZoomLevelChanged:{
            if(!mouseArea1.swapped){
                layers.zoomLevel = zoomLevel
                map1.zoomLevel = zoomLevel - layers.zoomFactor
            }
        }

        MapQuickItem {
            id: marker2
            coordinate: layers.myLocation
            anchorPoint.x: myLocationCircle2.width/2
            anchorPoint.y: myLocationCircle2.height
            sourceItem: Rectangle{
                id: myLocationCircle2
                width: !mouseArea1.swapped ? 20 : 10
                height: width
                radius: width/2
                color: "#5384ed"
                border.width: !mouseArea1.swapped ? 2 : 1
                border.color: "white"
            }
        }

        Binding on anchors.fill{
            when: mouseArea1.clicked
            value: !mouseArea1.swapped ? map2.parent : layers
        }

        Binding on z{
            when: mouseArea1.clicked
            value: !mouseArea1.swapped ? 0 : 1
        }

        Binding on copyrightsVisible{
            when: mouseArea1.clicked
            value: !mouseArea1.swapped
        }

    }

    Button{
        id: btn
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15
        anchors.rightMargin: 15
        text: "goto my location"
        onClicked: {
            if(!pananim.running && !zoominanim.running && !zoomoutanim.running){
                const zoom = layers.targetZoomLevel
                zoominanim.to = zoom
                zoomoutanim.start()
            }
        }
    }

    Item {
        id: layers
        width: 100
        height: width
        x: 15
        y: parent.height - 115
        z: 100
        property real zoomLevel: 0
        property real zoomFactor: 4
        property var myLocation: positionSrc.position.coordinate
        property int zoomAnimationDuration: 1000
        property int panAnimationDuration: 1000
        property real targetZoomLevel: 20

        PositionSource {
            id: positionSrc
            updateInterval: 1000
            active: true
            onPositionChanged: layers.setupAnimations(position.coordinate)
        }

        function stopAnims(){
            pananim.stop()
            zoominanim.stop()
            zoomoutanim.stop()
        }

        function setupAnimations(toCoordinate){
            if(!pananim.running && !zoominanim.running && !zoomoutanim.running){
                const map = mouseArea1.swapped ? map1 : map2
                const distance = Math.abs(map.center.distanceTo(toCoordinate))
                const logdistance = Math.max(Math.log(Math.abs(map.center.distanceTo(toCoordinate))), 0)
                layers.panAnimationDuration = 600 * Math.abs(Math.min(logdistance, map.zoomLevel))
                layers.zoomAnimationDuration = logdistance * 120 * Math.abs(Math.min(logdistance, Math.log(map.zoomLevel)))
                zoomoutanim.to = 20 - Math.abs(Math.min(logdistance, 20)) + Math.log(map.zoomLevel)
                zoomoutanim.to = zoomoutanim.to > map.zoomLevel ? map.zoomLevel : zoomoutanim.to
            }
        }


        MouseArea{
            id: mouseArea1
            anchors.fill: parent
            property bool swapped: false
            onClicked: {
                swapped = !swapped
                if(swapped){
                    map1.zoomLevel = Math.max(map2.zoomLevel, layers.zoomLevel)
                    map2.zoomLevel = Math.max(map1.zoomLevel, layers.zoomLevel) - layers.zoomFactor
                }
                else{
                    map2.zoomLevel = Math.max(map1.zoomLevel, layers.zoomLevel)
                    map1.zoomLevel = Math.max(map2.zoomLevel, layers.zoomLevel) - layers.zoomFactor
                }
            }
        }
        PropertyAnimation{
            id: pananim
            target: mouseArea1.swapped ? map1 : map2
            property: "center"
            to: mouseArea1.swapped ? marker1.coordinate : marker2.coordinate
            duration: layers.panAnimationDuration
            easing.type: Easing.InOutExpo
        }

        PropertyAnimation{
            id: zoomoutanim
            target: mouseArea1.swapped ? map1 : map2
            property: "zoomLevel"
            duration: layers.zoomAnimationDuration
            easing.type: Easing.OutExpo
            onStarted: pananim.start()
            onFinished: zoominanim.start()
        }

        PropertyAnimation{
            id: zoominanim
            target: mouseArea1.swapped ? map1 : map2
            property: "zoomLevel"
            duration: layers.zoomAnimationDuration
            easing.type: Easing.InExpo
        }
    }


}
