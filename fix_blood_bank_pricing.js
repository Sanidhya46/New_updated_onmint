// Script to add pricing to all blood banks
// Run this with: node fix_blood_bank_pricing.js

import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/healthcare';

const defaultPricing = {
  'A+': 500,
  'A-': 600,
  'B+': 500,
  'B-': 600,
  'AB+': 700,
  'AB-': 800,
  'O+': 450,
  'O-': 750,
};

async function fixBloodBankPricing() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    const User = mongoose.model('User');

    // Find all blood banks
    const bloodBanks = await User.find({ role: 'bloodbank' });
    console.log(`Found ${bloodBanks.length} blood banks`);

    let updatedCount = 0;
    let alreadyHadPricing = 0;

    for (const bloodBank of bloodBanks) {
      let needsUpdate = false;
      
      if (!bloodBank.bloodStock || bloodBank.bloodStock.length === 0) {
        console.log(`Blood bank ${bloodBank.bankName || bloodBank.firstName} has no blood stock. Skipping.`);
        continue;
      }

      // Check each blood group
      for (const stock of bloodBank.bloodStock) {
        if (!stock.pricePerUnit || stock.pricePerUnit === 0) {
          needsUpdate = true;
          const defaultPrice = defaultPricing[stock.bloodGroup] || 500;
          stock.pricePerUnit = defaultPrice;
          console.log(`  Setting ${stock.bloodGroup} price to ₹${defaultPrice}`);
        }
      }

      if (needsUpdate) {
        await bloodBank.save();
        updatedCount++;
        console.log(`✓ Updated ${bloodBank.bankName || bloodBank.firstName}`);
      } else {
        alreadyHadPricing++;
        console.log(`✓ ${bloodBank.bankName || bloodBank.firstName} already has pricing`);
      }
    }

    console.log('\n=== SUMMARY ===');
    console.log(`Total blood banks: ${bloodBanks.length}`);
    console.log(`Updated with pricing: ${updatedCount}`);
    console.log(`Already had pricing: ${alreadyHadPricing}`);
    console.log('\n✅ All blood banks now have pricing!');

    // Verify by showing one blood bank
    const sampleBloodBank = await User.findOne({ role: 'bloodbank' });
    if (sampleBloodBank) {
      console.log('\n=== SAMPLE BLOOD BANK ===');
      console.log(`Name: ${sampleBloodBank.bankName || sampleBloodBank.firstName}`);
      console.log('Blood Stock:');
      sampleBloodBank.bloodStock.forEach(stock => {
        console.log(`  ${stock.bloodGroup}: ${stock.unitsAvailable} units @ ₹${stock.pricePerUnit}/unit`);
      });
    }

    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

fixBloodBankPricing();
