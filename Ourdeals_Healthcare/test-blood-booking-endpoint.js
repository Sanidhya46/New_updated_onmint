// Simple test endpoint to verify blood booking data
// Add this to your routes temporarily

import express from 'express';
const router = express.Router();

router.post('/test-blood-booking', (req, res) => {
  console.log('=== TEST ENDPOINT HIT ===');
  console.log('Headers:', req.headers);
  console.log('Body:', req.body);
  console.log('Body keys:', Object.keys(req.body));
  console.log('bloodGroup:', req.body.bloodGroup);
  console.log('unitsRequired:', req.body.unitsRequired);
  console.log('serviceType:', req.body.serviceType);
  console.log('provider:', req.body.provider);
  
  res.json({
    success: true,
    message: 'Test endpoint - data received',
    receivedData: req.body,
    bloodGroup: req.body.bloodGroup,
    unitsRequired: req.body.unitsRequired,
    types: {
      bloodGroup: typeof req.body.bloodGroup,
      unitsRequired: typeof req.body.unitsRequired
    }
  });
});

export default router;
