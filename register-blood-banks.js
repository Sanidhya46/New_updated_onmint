const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/onmint')
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

// Define schemas
const userSchema = new mongoose.Schema({
  firstName: String,
  lastName: String,
  email: String,
  password: String,
  phone: String,
  role: String,
  isVerified: { type: Boolean, default: true },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

const bloodBankSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  bankName: String,
  licenseNumber: String,
  address: String,
  city: String,
  state: String,
  pincode: String,
  emergencyContact: String,
  location: {
    type: { type: String, default: 'Point' },
    coordinates: [Number]
  },
  bloodStock: [{
    bloodGroup: String,
    unitsAvailable: Number,
    pricePerUnit: Number
  }],
  isVerified: { type: Boolean, default: true },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

bloodBankSchema.index({ location: '2dsphere' });

const User = mongoose.model('User', userSchema);
const BloodBank = mongoose.model('BloodBank', bloodBankSchema);

async function registerBloodBanks() {
  try {
    // Blood Bank 1
    const hashedPassword1 = await bcrypt.hash('bloodbank123', 10);
    const user1 = await User.create({
      firstName: 'LifeSaver',
      lastName: 'Blood Bank',
      email: 'lifesaver@bloodbank.com',
      password: hashedPassword1,
      phone: '9876543210',
      role: 'bloodbank',
      isVerified: true,
      isActive: true
    });

    await BloodBank.create({
      user: user1._id,
      bankName: 'LifeSaver Blood Bank',
      licenseNumber: 'BB-2024-001',
      address: '123 Medical Street, Downtown',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400001',
      emergencyContact: '9876543210',
      location: {
        type: 'Point',
        coordinates: [72.8777, 19.0760] // Mumbai coordinates
      },
      bloodStock: [
        { bloodGroup: 'A+', unitsAvailable: 50, pricePerUnit: 500 },
        { bloodGroup: 'A-', unitsAvailable: 25, pricePerUnit: 550 },
        { bloodGroup: 'B+', unitsAvailable: 40, pricePerUnit: 500 },
        { bloodGroup: 'B-', unitsAvailable: 20, pricePerUnit: 550 },
        { bloodGroup: 'AB+', unitsAvailable: 15, pricePerUnit: 600 },
        { bloodGroup: 'AB-', unitsAvailable: 10, pricePerUnit: 650 },
        { bloodGroup: 'O+', unitsAvailable: 60, pricePerUnit: 500 },
        { bloodGroup: 'O-', unitsAvailable: 30, pricePerUnit: 600 }
      ],
      isVerified: true,
      isActive: true
    });

    console.log('✅ Created LifeSaver Blood Bank');

    // Blood Bank 2
    const hashedPassword2 = await bcrypt.hash('bloodbank123', 10);
    const user2 = await User.create({
      firstName: 'Dr. Shobhit',
      lastName: 'Bloodbank',
      email: 'shobhit@bloodbank.com',
      password: hashedPassword2,
      phone: '9876543211',
      role: 'bloodbank',
      isVerified: true,
      isActive: true
    });

    await BloodBank.create({
      user: user2._id,
      bankName: 'Dr. Shobhit Bloodbank',
      licenseNumber: 'BB-2024-002',
      address: '456 Health Avenue, Central',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400002',
      emergencyContact: '9876543211',
      location: {
        type: 'Point',
        coordinates: [72.8800, 19.0800]
      },
      bloodStock: [
        { bloodGroup: 'A+', unitsAvailable: 45, pricePerUnit: 500 },
        { bloodGroup: 'A-', unitsAvailable: 20, pricePerUnit: 550 },
        { bloodGroup: 'B+', unitsAvailable: 35, pricePerUnit: 500 },
        { bloodGroup: 'B-', unitsAvailable: 18, pricePerUnit: 550 },
        { bloodGroup: 'AB+', unitsAvailable: 12, pricePerUnit: 600 },
        { bloodGroup: 'AB-', unitsAvailable: 8, pricePerUnit: 650 },
        { bloodGroup: 'O+', unitsAvailable: 55, pricePerUnit: 500 },
        { bloodGroup: 'O-', unitsAvailable: 25, pricePerUnit: 600 }
      ],
      isVerified: true,
      isActive: true
    });

    console.log('✅ Created Dr. Shobhit Bloodbank');

    // Blood Bank 3
    const hashedPassword3 = await bcrypt.hash('bloodbank123', 10);
    const user3 = await User.create({
      firstName: 'NewVessels',
      lastName: 'Bloodbank',
      email: 'newvessels@bloodbank.com',
      password: hashedPassword3,
      phone: '9876543212',
      role: 'bloodbank',
      isVerified: true,
      isActive: true
    });

    await BloodBank.create({
      user: user3._id,
      bankName: 'Dr. Newvessels Bloodbank',
      licenseNumber: 'BB-2024-003',
      address: '789 Care Road, Suburb',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400003',
      emergencyContact: '9876543212',
      location: {
        type: 'Point',
        coordinates: [72.8850, 19.0850]
      },
      bloodStock: [
        { bloodGroup: 'A+', unitsAvailable: 40, pricePerUnit: 500 },
        { bloodGroup: 'A-', unitsAvailable: 22, pricePerUnit: 550 },
        { bloodGroup: 'B+', unitsAvailable: 38, pricePerUnit: 500 },
        { bloodGroup: 'B-', unitsAvailable: 15, pricePerUnit: 550 },
        { bloodGroup: 'AB+', unitsAvailable: 10, pricePerUnit: 600 },
        { bloodGroup: 'AB-', unitsAvailable: 7, pricePerUnit: 650 },
        { bloodGroup: 'O+', unitsAvailable: 50, pricePerUnit: 500 },
        { bloodGroup: 'O-', unitsAvailable: 28, pricePerUnit: 600 }
      ],
      isVerified: true,
      isActive: true
    });

    console.log('✅ Created Dr. Newvessels Bloodbank');

    console.log('\n✅ Successfully registered 3 blood banks with pricing!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error registering blood banks:', error);
    process.exit(1);
  }
}

registerBloodBanks();
