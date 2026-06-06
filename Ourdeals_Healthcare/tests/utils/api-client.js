// API Client Utility for Testing
import axios from 'axios';
import FormData from 'form-data';
import fs from 'fs';
import { config } from '../test-config.js';

class APIClient {
  constructor() {
    this.baseURL = config.baseURL;
    this.tokens = {};
  }

  // Helper to make requests
  async request(method, endpoint, data = null, token = null, isFormData = false) {
    const url = `${this.baseURL}${endpoint}`;
    const headers = {};

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    if (isFormData) {
      headers['Content-Type'] = 'multipart/form-data';
    }

    try {
      const response = await axios({
        method,
        url,
        data,
        headers,
        timeout: 10000, // 10 second timeout
      });
      return { success: true, data: response.data };
    } catch (error) {
      // Better error handling
      if (error.code === 'ECONNREFUSED') {
        return {
          success: false,
          error: 'Backend server is not running. Please start the server with "npm start"',
          status: 0,
        };
      }
      if (error.code === 'ETIMEDOUT' || error.code === 'ECONNABORTED') {
        return {
          success: false,
          error: 'Request timeout. Server may be slow or not responding',
          status: 0,
        };
      }
      return {
        success: false,
        error: error.response?.data || error.message,
        status: error.response?.status,
      };
    }
  }

  // Auth methods
  async register(userData, role = 'patient') {
    const payload = {
      ...userData,
      role,
      location: {
        type: 'Point',
        coordinates: [config.location.longitude, config.location.latitude],
      },
      city: config.location.city,
      state: config.location.state,
      pincode: config.location.pincode,
    };

    return this.request('POST', '/auth/register', payload);
  }

  async login(email, password) {
    const result = await this.request('POST', '/auth/login', { email, password });
    if (result.success && result.data.data?.accessToken) {
      this.tokens[email] = result.data.data.accessToken;
    }
    return result;
  }

  async logout(token) {
    return this.request('POST', '/auth/logout', {}, token);
  }

  // Patient APIs
  async getNearbyServices(token, serviceType = null) {
    const params = new URLSearchParams({
      latitude: config.location.latitude,
      longitude: config.location.longitude,
    });
    if (serviceType) params.append('serviceType', serviceType);
    return this.request('GET', `/patient/nearby?${params}`, null, token);
  }

  async createBooking(token, bookingData) {
    return this.request('POST', '/patient/bookings', bookingData, token);
  }

  async getBookings(token) {
    return this.request('GET', '/patient/bookings', null, token);
  }

  async triggerEmergency(token, type = 'doctor') {
    const data = {
      location: {
        type: 'Point',
        coordinates: [config.location.longitude, config.location.latitude],
      },
      address: config.location.address,
      notes: `Emergency ${type} request`,
      type,
    };
    return this.request('POST', '/patient/emergency', data, token);
  }

  async searchMedicines(token, search = '') {
    return this.request('GET', `/patient/search/medicines?search=${search}`, null, token);
  }

  async getMedicineById(token, medicineId) {
    return this.request('GET', `/patient/medicines/${medicineId}`, null, token);
  }

  // Admin APIs
  async getAllUsers(token, role = null) {
    const params = role ? `?role=${role}` : '';
    return this.request('GET', `/admin/users${params}`, null, token);
  }

  async approveUser(token, userId) {
    return this.request('PUT', `/admin/users/${userId}/approve`, {}, token);
  }

  async rejectUser(token, userId, reason = 'Test rejection') {
    return this.request('PUT', `/admin/users/${userId}/reject`, { reason }, token);
  }

  async createMedicine(token, medicineData, imagePath = null) {
    if (imagePath && fs.existsSync(imagePath)) {
      const formData = new FormData();
      Object.keys(medicineData).forEach(key => {
        formData.append(key, medicineData[key]);
      });
      formData.append('images', fs.createReadStream(imagePath));
      return this.request('POST', '/admin/medicines', formData, token, true);
    }
    return this.request('POST', '/admin/medicines', medicineData, token);
  }

  async getAllMedicines(token) {
    return this.request('GET', '/admin/medicines', null, token);
  }

  async updateMedicine(token, medicineId, medicineData) {
    return this.request('PUT', `/admin/medicines/${medicineId}`, medicineData, token);
  }

  async deleteMedicine(token, medicineId) {
    return this.request('DELETE', `/admin/medicines/${medicineId}`, null, token);
  }

  async getDashboardStats(token) {
    return this.request('GET', '/admin/dashboard/stats', null, token);
  }

  // Doctor APIs
  async getDoctorAppointments(token) {
    return this.request('GET', '/doctor/appointments', null, token);
  }

  async acceptBooking(token, bookingId) {
    return this.request('PUT', `/doctor/bookings/${bookingId}/accept`, {}, token);
  }

  async completeBooking(token, bookingId) {
    return this.request('PUT', `/doctor/bookings/${bookingId}/complete`, {}, token);
  }

  async createPrescription(token, prescriptionData) {
    return this.request('POST', '/doctor/prescriptions', prescriptionData, token);
  }

  // Nurse APIs
  async getNurseBookings(token) {
    return this.request('GET', '/nurse/bookings', null, token);
  }

  async updateNurseAvailability(token, availability) {
    return this.request('PUT', '/nurse/availability', { availability }, token);
  }

  // Pharmacist APIs
  async getPharmacistOrders(token) {
    return this.request('GET', '/pharmacist/orders', null, token);
  }

  async acceptOrder(token, orderId) {
    return this.request('PUT', `/pharmacist/orders/${orderId}/accept`, {}, token);
  }

  async updateOrderStatus(token, orderId, status) {
    return this.request('PUT', `/pharmacist/orders/${orderId}/status`, { status }, token);
  }

  // Ambulance APIs
  async getAmbulanceRides(token) {
    return this.request('GET', '/ambulance/rides', null, token);
  }

  async acceptRide(token, rideId) {
    return this.request('PUT', `/ambulance/rides/${rideId}/accept`, {}, token);
  }

  async updateRideStatus(token, rideId, status) {
    return this.request('PUT', `/ambulance/rides/${rideId}/status`, { status }, token);
  }

  async updateAmbulanceLocation(token, latitude, longitude) {
    return this.request('PUT', '/ambulance/location', { latitude, longitude }, token);
  }

  // Pathology APIs
  async getPathologyBookings(token) {
    return this.request('GET', '/pathology/bookings', null, token);
  }

  async uploadLabReport(token, bookingId, reportPath) {
    if (!fs.existsSync(reportPath)) {
      return { success: false, error: 'Report file not found' };
    }
    const formData = new FormData();
    formData.append('report', fs.createReadStream(reportPath));
    return this.request('POST', `/pathology/bookings/${bookingId}/report`, formData, token, true);
  }

  // Blood Bank APIs
  async getBloodBankRequests(token) {
    return this.request('GET', '/bloodbank/requests', null, token);
  }

  async updateBloodStock(token, bloodStock) {
    return this.request('PUT', '/bloodbank/stock', { bloodStock }, token);
  }

  // Document APIs
  async uploadDocument(token, documentType, filePath) {
    if (!fs.existsSync(filePath)) {
      return { success: false, error: 'Document file not found' };
    }
    const formData = new FormData();
    formData.append('document', fs.createReadStream(filePath));
    formData.append('documentType', documentType);
    return this.request('POST', '/documents/upload', formData, token, true);
  }

  // Rating APIs
  async addRating(token, bookingId, rating, review = '') {
    return this.request('POST', '/patient/ratings', {
      booking: bookingId,
      rating,
      review,
    }, token);
  }

  // Get token for user
  getToken(email) {
    return this.tokens[email];
  }
}

export default APIClient;
