// Test Configuration
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const config = {
  baseURL: process.env.API_URL || 'http://localhost:5000/api/v1',
  
  // Sample images paths
  images: {
    profile: path.join(__dirname, 'sample-images', 'profile.jpg'),
    medicine: path.join(__dirname, 'sample-images', 'medicine.jpg'),
    document: path.join(__dirname, 'sample-images', 'document.pdf'),
    license: path.join(__dirname, 'sample-images', 'license.jpg'),
    ambulance: path.join(__dirname, 'sample-images', 'ambulance.jpg'),
    labReport: path.join(__dirname, 'sample-images', 'lab-report.jpg'),
  },
  
  // Test users credentials
  users: {
    admin: {
      email: 'admin@test.com',
      password: 'Admin@123',
      firstName: 'Admin',
      lastName: 'User',
      phone: '9876543210',
    },
    patient: {
      email: 'patient@test.com',
      password: 'Patient@123',
      firstName: 'Test',
      lastName: 'Patient',
      phone: '9876543211',
    },
    doctor: {
      email: 'doctor@test.com',
      password: 'Doctor@123',
      firstName: 'Dr. John',
      lastName: 'Doe',
      phone: '9876543212',
      specialization: 'General Physician',
      experience: 5,
      consultationFee: 500,
      licenseNumber: 'DOC123456',
    },
    nurse: {
      email: 'nurse@test.com',
      password: 'Nurse@123',
      firstName: 'Mary',
      lastName: 'Smith',
      phone: '9876543213',
      specialization: 'ICU',
      experience: 3,
      hourlyRate: 200,
      licenseNumber: 'NUR123456',
    },
    pharmacist: {
      email: 'pharmacist@test.com',
      password: 'Pharma@123',
      firstName: 'Pharmacy',
      lastName: 'Owner',
      phone: '9876543214',
      pharmacyName: 'Test Pharmacy',
      licenseNumber: 'PHAR123456',
    },
    ambulance: {
      email: 'ambulance@test.com',
      password: 'Ambulance@123',
      firstName: 'Ambulance',
      lastName: 'Driver',
      phone: '9876543215',
      driverName: 'John Driver',
      vehicleNumber: 'DL01AB1234',
      vehicleType: 'Basic',
      licenseNumber: 'AMB123456',
      driverLicense: 'DL123456789', // Added required field
    },
    pathology: {
      email: 'pathology@test.com',
      password: 'Pathology@123',
      firstName: 'Lab',
      lastName: 'Owner',
      phone: '9876543216',
      labName: 'Test Pathology Lab',
      licenseNumber: 'PATH123456',
    },
    bloodbank: {
      email: 'bloodbank@test.com',
      password: 'BloodBank@123',
      firstName: 'Blood',
      lastName: 'Bank',
      phone: '9876543217',
      bankName: 'Test Blood Bank',
      licenseNumber: 'BB123456',
      emergencyContact: '9876543218', // Added required field
    },
  },
  
  // Common location for testing
  location: {
    latitude: 28.6139,
    longitude: 77.2090,
    address: 'New Delhi, India',
    city: 'New Delhi',
    state: 'Delhi',
    pincode: '110001',
  },
  
  // Test data
  testData: {
    medicine: {
      name: 'Test Medicine',
      genericName: 'Generic Test',
      manufacturer: 'Test Pharma',
      category: 'Tablet',
      price: 100,
      stock: 50,
      dosageForm: 'Tablet',
      strength: '500mg',
      packaging: '10 tablets',
      description: 'Test medicine for API testing',
    },
    booking: {
      scheduledTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // Tomorrow
      notes: 'Test booking',
    },
  },
};

export default config;
