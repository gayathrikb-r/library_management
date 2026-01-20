// app/javascript/application.js
import "@hotwired/turbo-rails"


import ApiClient from "./services/api_client"
window.ApiClient = ApiClient


import "controllers" 


import { application } from "controllers/application"
window.Stimulus = application