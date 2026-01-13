const ApiClient = {
  async get(url) {
    const response = await fetch(`/api/v1${url}`, {
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    });
    return this.handleResponse(response);
  },

  async post(url, data) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content;
    const response = await fetch(`/api/v1${url}`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': token
      },
      body: JSON.stringify(data)
    });
    return this.handleResponse(response);
  },

  async handleResponse(response) {
    if (!response.ok) {
      // This catches 500 errors and helps you debug
      const errorText = await response.text();
      console.error("Server Error Output:", errorText);
      throw new Error(`Network response was not ok: ${response.status}`);
    }
    return response.json();
  }
};

export default ApiClient;