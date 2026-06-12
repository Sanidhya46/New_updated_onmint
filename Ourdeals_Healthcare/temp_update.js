const mongoose = require('mongoose');
mongoose.connect('mongodb://localhost:27017/ourdeals_healthcare').then(async () => {
  const RealTimeBooking = require('./src/models/RealTimeBooking.model.js');
  await RealTimeBooking.updateMany({}, { $set: { report: '/uploads/report/dummy.pdf' } });
  console.log('updated');
  process.exit(0);
});
