import AuthHelper from './auth_helper'

const ApiClient = {
  async get(url) {
    const response = await fetch(url, {
      headers: AuthHelper.getAuthHeaders()
    })
    return this.handleResponse(response)
  },

  async post(url, data) {
    const response = await fetch(url, {
      method: 'POST',
      headers: AuthHelper.getAuthHeaders(),
      body: JSON.stringify(data)
    })
    return this.handleResponse(response)
  },

  async patch(url, data) {
    const response = await fetch(url, {
      method: 'PATCH',
      headers: AuthHelper.getAuthHeaders(),
      body: JSON.stringify(data)
    })
    return this.handleResponse(response)
  },

  async delete(url) {
    const response = await fetch(url, {
      method: 'DELETE',
      headers: AuthHelper.getAuthHeaders()
    })
    return this.handleResponse(response)
  },

  async handleResponse(response) {

    if (response.status === 401) {
      AuthHelper.handleUnauthorized()
      throw new Error('Unauthorized - redirecting to login')
    }


    if (response.status === 204) {
      return null
    }

    if (!response.ok) {
      
      try {
        const errorData = await response.json()
        const errorMessage = errorData.error || errorData.message || `Error ${response.status}`
        throw new Error(errorMessage)
      } catch (e) {

        throw new Error(`Request failed: ${response.statusText}`)
      }
    }

    return response.json()
  }
}

export default ApiClient