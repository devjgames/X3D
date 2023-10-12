//
//  AppDelegate.swift
//  X3DTest
//
//  Created by Douglas McNamara on 9/14/23.
//

import X3D

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    
    var gameEditor:GameEditor?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        do {
            var url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            
            url = url.appendingPathComponent("XCode/X3DTest/X3DTest/assets")
            
            try KeyFrameMeshAnimator.populateAssets(url: url)
            try ModelAnimator.populateAssets(url: url)
            
            gameEditor = try GameEditor(window: window, assetRoot: url, animatorBase: "X3DTest",
                                        animators: [
                                            "Target",
                                            "Light",
                                            "Model",
                                            "KFMesh",
                                            "Info",
                                            "Player",
                                            "Drip",
                                            "LMap"
                                        ]
            ) { jsGame in
                jsGame.addBasicFuncs()
            }
        } catch {
            Log.put(0, error)
        }
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

