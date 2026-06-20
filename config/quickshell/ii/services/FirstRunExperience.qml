pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string firstRunFilePath: `${Directories.state}/user/first_run.txt`
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property string firstRunNotifSummary: "Welcome to ShadowsRealm!"
    property string firstRunNotifBody: "Hit Super+/ any time for the keybind cheat sheet"
    property string defaultWallpaperPath: FileUtils.trimFileProtocol(`${Directories.assetsPath}/images/default_wallpaper.png`)
    property string welcomeQmlPath: FileUtils.trimFileProtocol(Quickshell.shellPath("welcome.qml"))

    function load() {
        firstRunFileView.reload()
    }

    function enableNextTime() {
        Quickshell.execDetached(["rm", "-f", root.firstRunFilePath])
    }
    function disableNextTime() {
        Quickshell.execDetached(["bash", "-c", `echo '${root.firstRunFileContent}' > '${root.firstRunFilePath}'`])
    }

    function handleFirstRun() {
        // ShadowsRealm: Caelestia owns the wallpaper, so we don't run end-4's
        // wallpaper switch here. Instead we greet the user and auto-open the
        // keybind cheat sheet so all commands are discoverable on first install.
        Quickshell.execDetached(["bash", "-c", `qs -p '${root.welcomeQmlPath}'`])
        Quickshell.execDetached(["bash", "-c", "sleep 2 && qs -c ii ipc call cheatsheet open"])
        Quickshell.execDetached(["notify-send", root.firstRunNotifSummary, root.firstRunNotifBody, "-a", "ShadowsRealm"])
    }

    FileView {
        id: firstRunFileView
        path: Qt.resolvedUrl(firstRunFilePath)
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                firstRunFileView.setText(root.firstRunFileContent)
                root.handleFirstRun()
            }
        }
    }
}
