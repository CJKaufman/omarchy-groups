import QtQuick
import Quickshell
import "before/LayoutModel.js" as BeforeLayout
import "after/LayoutModel.js" as AfterLayout
import "before/GroupIcons.js" as BeforeIcons
import "after/GroupIcons.js" as AfterIcons
ShellRoot {
  function elapsed(fn, count) {
    for (var warm = 0; warm < 100; warm++) fn()
    var start = Date.now()
    for (var i = 0; i < count; i++) fn()
    return Date.now() - start
  }
  Timer {
    interval: 1; running: true
    onTriggered: {
      for (var n of [24, 120]) {
        var entries = [], rows = []
        for(var i=0; i<n; i++) {
          var entry = {id:"w."+i, setting:{options:[1,2,3]}}
          entries.push(entry); rows.push({instanceKey:i,entryJson:JSON.stringify(entry)})
        }
        var model = {count:n,get:function(i){return rows[i]}}
        console.log("MODEL", n, "x5000 before/after ms:",
          elapsed(function(){BeforeLayout.syncEntries(model,entries)},5000),
          elapsed(function(){AfterLayout.syncEntries(model,entries)},5000))
      }
      console.log("SEARCH x1000 before/after ms:",
        elapsed(function(){BeforeIcons.search("wireless signal")},1000),
        elapsed(function(){AfterIcons.search("wireless signal")},1000))
      Qt.quit()
    }
  }
}
