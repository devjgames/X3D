// this is a sample of the basic functions included with JSGame
// to really do something useful more functions would need to be bound to JSGame
//
// by convention all function names will begin with X3D
//
// when a scene loads, setup is called on each node
// on each frame, update is called on each node
//
// to avoid memory leaks only built in objects are passed back and forth between swift and the js context
//

function setup() {
    X3DLog("Hello setup - " + X3DNodeName() + ", position = " + X3DNodePosition() + ", id = " + X3DNodeID())
    X3DActivateNode(X3DPlayerID())
    X3DLog("\tplayer position = " + X3DNodePosition())
}

function update() {
    if(X3DNodeName() == "Player") {
        //X3DLog("position = " + X3DNodePosition())
    }
}
