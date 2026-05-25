// Fix consultation type mismatch for existing booking
import { connectDB } from './src/config/database.js';
import { Booking } from './src/models/Booking.model.js';
import { Doctor } from './src/models/Doctor.model.js';

const fixConsultationType = async () => {
  try {
    await connectDB();
    console.log('Connected to database');

    // Find the problematic booking
    const bookingId = '6a0feba41d20b1d5c9f69631';
    const booking = await Booking.findById(bookingId).populate('provider');
    
    if (!booking) {
      console.log('Booking not found');
      return;
    }

    console.log('Current booking details:');
    console.log('- Booking ID:', booking._id);
    console.log('- Current consultation type:', booking.consultationType);
    console.log('- Doctor consultation types:', booking.provider.consultationTypes);
    console.log('- Doctor name:', booking.provider.firstName, booking.provider.lastName);

    // Check if doctor supports video-call
    if (booking.provider.consultationTypes && booking.provider.consultationTypes.includes('video-call')) {
      // Update booking to video-call since doctor supports it
      booking.consultationType = 'video-call';
      
      // Remove location since it's not needed for video calls
      booking.location = undefined;
      
      await booking.save();
      
      console.log('✅ Fixed! Updated booking consultation type to:', booking.consultationType);
      console.log('✅ Removed location field for video consultation');
    } else {
      console.log('❌ Doctor does not support video-call consultations');
    }

    process.exit(0);
  } catch (error) {
    console.error('Error fixing consultation type:', error);
    process.exit(1);
  }
};

fixConsultationType();