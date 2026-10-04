const API_BASE_URL = 'http://localhost:5000/api';

const getToken = () => localStorage.getItem('zyeta_token');

const request = async (endpoint, options = {}) => {
  const token = getToken();
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers
  };

  const config = {
    ...options,
    headers
  };

  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, config);
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.message || 'API request failed');
    }
    return data;
  } catch (error) {
    console.error(`API Error on ${endpoint}:`, error);
    throw error;
  }
};

export const api = {
  // Auth
  login: (credentials) => request('/auth/login', { method: 'POST', body: JSON.stringify(credentials) }),
  getMe: () => request('/auth/me'),
  getUsers: () => request('/auth/users'),
  createUser: (userData) => request('/auth/users', { method: 'POST', body: JSON.stringify(userData) }),

  // Dashboard
  getDashboardStats: () => request('/dashboard/stats'),

  // Employees
  getEmployees: (params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/employees${query ? '?' + query : ''}`);
  },
  getEmployeeById: (id) => request(`/employees/${id}`),
  createEmployee: (data) => request('/employees', { method: 'POST', body: JSON.stringify(data) }),
  updateEmployee: (id, data) => request(`/employees/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  deleteEmployee: (id) => request(`/employees/${id}`, { method: 'DELETE' }),

  // Vendors
  getVendors: () => request('/vendors'),
  getVendorById: (id) => request(`/vendors/${id}`),
  createVendor: (data) => request('/vendors', { method: 'POST', body: JSON.stringify(data) }),
  updateVendor: (id, data) => request(`/vendors/${id}`, { method: 'PUT', body: JSON.stringify(data) }),

  // Gate Operations
  verifyQR: (qrData) => request('/gate/verify-qr', { method: 'POST', body: JSON.stringify({ qr_data: qrData }) }),
  recordGateMovement: (data) => request('/gate/movement', { method: 'POST', body: JSON.stringify(data) }),
  getCurrentlyInside: () => request('/gate/inside'),
  getGateTransactions: (params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/gate/transactions${query ? '?' + query : ''}`);
  },

  // Attendance
  getAttendance: (params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/attendance${query ? '?' + query : ''}`);
  },
  getAttendanceSummary: () => request('/attendance/summary'),
  markManualAttendance: (data) => request('/attendance/manual', { method: 'POST', body: JSON.stringify(data) }),

  // Permits
  getPermits: (params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/permits${query ? '?' + query : ''}`);
  },
  getPermitById: (id) => request(`/permits/${id}`),
  createPermit: (data) => request('/permits', { method: 'POST', body: JSON.stringify(data) }),
  approvePermit: (id) => request(`/permits/${id}/approve`, { method: 'PUT' }),
  rejectPermit: (id, reason) => request(`/permits/${id}/reject`, { method: 'PUT', body: JSON.stringify({ reason }) }),
  verifyPermitGate: (id) => request(`/permits/${id}/verify-gate`, { method: 'PUT' }),

  // Materials
  getMaterials: (params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/materials${query ? '?' + query : ''}`);
  },
  createMaterialEntry: (data) => request('/materials/entry', { method: 'POST', body: JSON.stringify(data) }),
  updateMaterialReturn: (id, data) => request(`/materials/${id}/return`, { method: 'PUT', body: JSON.stringify(data) }),

  // Visitors
  getVisitors: (params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/visitors${query ? '?' + query : ''}`);
  },
  registerVisitor: (data) => request('/visitors/register', { method: 'POST', body: JSON.stringify(data) }),
  checkoutVisitor: (id) => request(`/visitors/${id}/checkout`, { method: 'PUT' }),

  // Vehicles
  getVehicles: (params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/vehicles${query ? '?' + query : ''}`);
  },
  createVehicle: (data) => request('/vehicles', { method: 'POST', body: JSON.stringify(data) }),

  // Reports & Audit
  getReportData: (params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/reports/data${query ? '?' + query : ''}`);
  },
  getAuditLogs: (params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/audit/logs${query ? '?' + query : ''}`);
  },

  // Notifications
  getNotifications: () => request('/notifications'),
  markNotificationRead: (id) => request(`/notifications/${id}/read`, { method: 'PUT' }),
  markAllNotificationsRead: () => request('/notifications/read-all', { method: 'PUT' }),

  // Safety Punches (Red / Yellow / Green)
  getSafetyPunches: (params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/safety/punches${query ? '?' + query : ''}`);
  },
  createSafetyPunch: (data) => request('/safety/punches', { method: 'POST', body: JSON.stringify(data) }),
  deleteSafetyPunch: (id) => request(`/safety/punches/${id}`, { method: 'DELETE' })
};
