// CSS is handled by Tailwind CLI separately, not imported here

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
import {Socket, LongPoll} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Detect if we're on iOS
let isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream

// Pull-to-Refresh Hook for AI Recipe Generation
let Hooks = {}
Hooks.PullToRefresh = {
  mounted() {
    let touchStartY = 0
    let touchCurrentY = 0
    let pullDistance = 0
    let isPulling = false
    let threshold = 80 // pixels to pull before triggering

    const container = this.el
    const indicator = document.getElementById('pull-indicator')
    const pullIcon = indicator?.querySelector('.pull-icon')
    const pullText = indicator?.querySelector('.pull-text')
    const releaseText = indicator?.querySelector('.release-text')

    container.addEventListener('touchstart', (e) => {
      // Only enable pull-to-refresh when scrolled to top
      if (container.scrollTop === 0) {
        touchStartY = e.touches[0].clientY
        isPulling = true
      }
    }, { passive: true })

    container.addEventListener('touchmove', (e) => {
      if (!isPulling) return

      touchCurrentY = e.touches[0].clientY
      pullDistance = touchCurrentY - touchStartY

      // Only show indicator if pulling down
      if (pullDistance > 0 && indicator) {
        const translateY = Math.min(pullDistance, threshold + 40)
        indicator.style.transform = `translateY(${translateY}px)`
        indicator.style.opacity = Math.min(pullDistance / threshold, 1)

        // Change icon and text when threshold reached
        if (pullDistance >= threshold) {
          pullIcon?.style.setProperty('transform', 'rotate(180deg)')
          pullText?.classList.add('hidden')
          releaseText?.classList.remove('hidden')
        } else {
          pullIcon?.style.setProperty('transform', 'rotate(0deg)')
          pullText?.classList.remove('hidden')
          releaseText?.classList.add('hidden')
        }
      }
    }, { passive: true })

    container.addEventListener('touchend', (e) => {
      if (!isPulling) return

      if (pullDistance >= threshold && indicator) {
        // Trigger recipe generation
        this.pushEvent('generate_recipes', {})
      }

      // Reset
      if (indicator) {
        setTimeout(() => {
          indicator.style.transform = 'translateY(-100%)'
          indicator.style.opacity = '0'
          pullIcon?.style.setProperty('transform', 'rotate(0deg)')
          pullText?.classList.remove('hidden')
          releaseText?.classList.add('hidden')
        }, 300)
      }

      isPulling = false
      pullDistance = 0
    }, { passive: true })
  }
}

// Socket options
let socketOpts = {
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
  dom: {
    onBeforeElUpdated(from, to) {
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
}

// Force longpoll on iOS - WebSocket over Tailscale/VPN is unreliable on mobile Safari
if (isIOS) {
  console.log("iOS detected - using LongPoll transport")
  socketOpts.transport = LongPoll
}

let liveSocket = new LiveSocket("/live", Socket, socketOpts)

// Enable debug in development
liveSocket.enableDebug()

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => {
  topbar.hide()
  // Reinitialize haptic feedback after LiveView navigation
  if (window.HapticFeedback) {
    window.HapticFeedback.init()
  }
})

// Connect and show connection status
liveSocket.connect()

// Add connection status indicator for debugging
function updateConnectionStatus() {
  let indicator = document.getElementById('lv-connection-status')
  if (!indicator) {
    indicator = document.createElement('div')
    indicator.id = 'lv-connection-status'
    indicator.style.cssText = 'position:fixed;top:0;left:50%;transform:translateX(-50%);padding:4px 12px;border-radius:0 0 8px 8px;font-size:12px;z-index:9999;'
    document.body.appendChild(indicator)
  }

  if (liveSocket.isConnected()) {
    indicator.textContent = 'Connected'
    indicator.style.background = '#22c55e'
    indicator.style.color = 'white'
    setTimeout(() => { indicator.style.display = 'none' }, 2000)
  } else {
    indicator.textContent = 'Connecting...'
    indicator.style.background = '#eab308'
    indicator.style.color = 'black'
    indicator.style.display = 'block'
  }
}

// Check connection status periodically
setInterval(updateConnectionStatus, 1000)
updateConnectionStatus()

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

