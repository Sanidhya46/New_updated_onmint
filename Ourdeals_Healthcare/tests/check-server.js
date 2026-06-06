#!/usr/bin/env node

/**
 * Check if backend server is running before running tests
 */

import axios from 'axios';
import chalk from 'chalk';

const API_URL = process.env.API_URL || 'http://localhost:5000/api';

async function checkServer() {
  console.log(chalk.cyan('🔍 Checking if backend server is running...'));
  console.log(chalk.gray(`   API URL: ${API_URL}\n`));

  try {
    // Try to connect to the server
    const response = await axios.get(`${API_URL.replace('/api', '')}/health`, {
      timeout: 5000,
    });

    if (response.status === 200) {
      console.log(chalk.green('✅ Backend server is running!'));
      console.log(chalk.gray(`   Status: ${response.status}`));
      console.log(chalk.gray(`   Response: ${JSON.stringify(response.data)}\n`));
      return true;
    }
  } catch (error) {
    if (error.code === 'ECONNREFUSED') {
      console.log(chalk.red('❌ Backend server is NOT running!'));
      console.log(chalk.yellow('\n⚠  Please start the backend server first:'));
      console.log(chalk.white('   1. Open a new terminal'));
      console.log(chalk.white('   2. Navigate to: Ourdeals_Healthcare'));
      console.log(chalk.white('   3. Run: npm start'));
      console.log(chalk.white('   4. Wait for "Server running on port 5000"'));
      console.log(chalk.white('   5. Then run tests again\n'));
    } else if (error.code === 'ETIMEDOUT') {
      console.log(chalk.red('❌ Server connection timeout!'));
      console.log(chalk.yellow('   Server may be starting up or slow to respond\n'));
    } else {
      console.log(chalk.red('❌ Error connecting to server:'));
      console.log(chalk.red(`   ${error.message}\n`));
    }
    return false;
  }
}

// Run check
checkServer().then(isRunning => {
  process.exit(isRunning ? 0 : 1);
});
