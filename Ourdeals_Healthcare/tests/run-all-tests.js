#!/usr/bin/env node

/**
 * Complete API Test Suite
 * Tests all APIs for Patient, Admin, and All Vendors
 * 
 * Usage:
 *   node tests/run-all-tests.js
 * 
 * Make sure:
 * 1. Backend server is running (npm start)
 * 2. MongoDB is connected
 * 3. Sample images are placed in tests/sample-images/ folder
 */

import chalk from 'chalk';
import axios from 'axios';
import TestLogger from './utils/logger.js';
import runAuthTests from './01-auth-tests.js';
import runAdminTests from './02-admin-tests.js';
import runPatientTests from './03-patient-tests.js';
import runVendorTests from './04-vendor-tests.js';
import { config } from './test-config.js';

const mainLogger = new TestLogger();

async function checkServer() {
  try {
    // Try /api/v1/health endpoint
    const response = await axios.get('http://localhost:5000/api/v1/health', {
      timeout: 5000,
    });
    return response.status === 200;
  } catch (error) {
    // If v1 endpoint fails, try root
    try {
      const response = await axios.get('http://localhost:5000', {
        timeout: 5000,
      });
      // Server is running even if it returns 404 for root
      return true;
    } catch (err) {
      return false;
    }
  }
}

async function runAllTests() {
  console.log(chalk.bold.cyan('\n' + '═'.repeat(80)));
  console.log(chalk.bold.cyan('  OURDEALS HEALTHCARE - COMPLETE API TEST SUITE'));
  console.log(chalk.bold.cyan('═'.repeat(80) + '\n'));

  // Check if server is running
  console.log(chalk.cyan('🔍 Checking backend server...'));
  const serverRunning = await checkServer();
  
  if (!serverRunning) {
    console.log(chalk.red('\n❌ Backend server is NOT running!\n'));
    console.log(chalk.yellow('⚠  Please start the backend server first:'));
    console.log(chalk.white('   1. Open a new terminal'));
    console.log(chalk.white('   2. Navigate to: Ourdeals_Healthcare'));
    console.log(chalk.white('   3. Run: npm start'));
    console.log(chalk.white('   4. Wait for "Server running on port 5000"'));
    console.log(chalk.white('   5. Then run tests again\n'));
    process.exit(1);
  }

  console.log(chalk.green('✅ Backend server is running!\n'));

  console.log(chalk.yellow('⚠  Prerequisites:'));
  console.log(chalk.white('   1. Backend server must be running (npm start) ✓'));
  console.log(chalk.white('   2. MongoDB must be connected'));
  console.log(chalk.white('   3. Sample images should be in tests/sample-images/'));
  console.log(chalk.yellow('\n⏳ Starting tests in 3 seconds...\n'));

  await new Promise(resolve => setTimeout(resolve, 3000));

  try {
    // Phase 1: Authentication Tests
    console.log(chalk.bold.green('\n📋 PHASE 1: Authentication & Registration\n'));
    const client = await runAuthTests();
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Phase 2: Admin Tests
    console.log(chalk.bold.green('\n📋 PHASE 2: Admin Operations\n'));
    const adminData = await runAdminTests(client);
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Phase 3: Patient Tests
    console.log(chalk.bold.green('\n📋 PHASE 3: Patient Operations\n'));
    const patientData = await runPatientTests(client);
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Phase 4: Vendor Tests
    console.log(chalk.bold.green('\n📋 PHASE 4: Vendor Operations\n'));
    await runVendorTests(client, { ...adminData, ...patientData });

    // Final Summary
    console.log(chalk.bold.cyan('\n' + '═'.repeat(80)));
    console.log(chalk.bold.cyan('  TEST EXECUTION COMPLETED'));
    console.log(chalk.bold.cyan('═'.repeat(80)));

    mainLogger.summary();

    console.log(chalk.bold.green('✅ All tests completed successfully!\n'));
    process.exit(0);

  } catch (error) {
    console.error(chalk.bold.red('\n❌ Test execution failed:'));
    console.error(chalk.red(error.message));
    console.error(error.stack);
    process.exit(1);
  }
}

// Run tests
runAllTests();
