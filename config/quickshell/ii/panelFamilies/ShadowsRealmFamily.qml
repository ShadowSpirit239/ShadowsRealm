import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.ii.cheatsheet
import qs.modules.ii.sidebarLeft

/**
 * ShadowsRealm panel family.
 *
 * The Caelestia shell owns the bar, launcher, dock, OSD, notifications,
 * overview, wallpaper, lock and the polkit agent. This family therefore loads
 * ONLY the end-4-derived pieces ShadowsRealm keeps: the AI sidebar
 * (SidebarLeft) and the keybind cheat sheet.
 */
Scope {
    PanelLoader { component: Cheatsheet {} }
    PanelLoader { component: SidebarLeft {} }
}
