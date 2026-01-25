// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import "../css/app.css"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Detect if we're on iOS
let isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream

let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  // Use longpoll on iOS as fallback if websocket fails
  transport: isIOS ? undefined : undefined,
  dom: {
    onBeforeElUpdated(from, to) {
      // Preserve Alpine.js state
      if (from._x_dataStack) {
        window.Alpine?.clone(from, to)
      }
    }
  },
  metadata: {
    click: (e, el) => {
      return {
        clientX: e.clientX,
        clientY: e.clientY,
        altKey: e.altKey,
        ctrlKey: e.ctrlKey,
        metaKey: e.metaKey,
        shiftKey: e.shiftKey
      }
    }
  }
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// Connect with reconnect handling for mobile
liveSocket.connect()

// Handle visibility change (iOS Safari suspends websockets when tab is backgrounded)
document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible") {
    // Reconnect when tab becomes visible
    if (!liveSocket.isConnected()) {
      liveSocket.connect()
    }
  }
})

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

