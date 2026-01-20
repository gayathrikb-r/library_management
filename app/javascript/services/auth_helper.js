const AuthHelper = {
  getAuthHeaders() {
    const headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }


    let token = localStorage.getItem('auth_token')

    if (!token) {
      const metaTag = document.querySelector('meta[name="api-token"]')
      if (metaTag && metaTag.content) {
        token = metaTag.content
    
        localStorage.setItem('auth_token', token)
      }
    }

    if (token) {
      headers['Authorization'] = `Bearer ${token}`
    }

   
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      headers['X-CSRF-Token'] = csrfToken
    }

    return headers
  },

  handleUnauthorized() {
    
    localStorage.removeItem('auth_token')
    
  
    window.location.href = '/login'
  }
}

export default AuthHelper