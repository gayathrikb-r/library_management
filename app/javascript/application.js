// app/javascript/application.js
import "@hotwired/turbo-rails"

// 1. Import the ApiClient FIRST
// This ensures it's available before controllers try to use it
import ApiClient from "api/api_client"
window.ApiClient = ApiClient

// 2. Load the Stimulus application and controllers
import "controllers" 

// 3. (Optional) For debugging in the browser console
import { application } from "controllers/application"
window.Stimulus = application