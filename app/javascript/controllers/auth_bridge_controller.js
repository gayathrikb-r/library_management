import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.syncToken()
  }

  syncToken() {
    const tokenMeta = document.querySelector('meta[name="api-token"]')
    const serverToken = tokenMeta ? tokenMeta.content : null

    if (serverToken) {
      localStorage.setItem('auth_token', serverToken)
      console.log("Auth Bridge: Token synced from session.")
    } else {
      
    }
  }
}