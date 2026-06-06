// Test Logger Utility
import chalk from 'chalk';

class TestLogger {
  constructor() {
    this.results = {
      total: 0,
      passed: 0,
      failed: 0,
      skipped: 0,
    };
    this.currentSuite = null;
  }

  suite(name) {
    this.currentSuite = name;
    console.log('\n' + chalk.bold.blue('═'.repeat(80)));
    console.log(chalk.bold.blue(`  TEST SUITE: ${name}`));
    console.log(chalk.bold.blue('═'.repeat(80)));
  }

  test(name) {
    console.log(chalk.gray(`\n  → Testing: ${name}`));
  }

  pass(message) {
    this.results.total++;
    this.results.passed++;
    console.log(chalk.green(`    ✓ ${message}`));
  }

  fail(message, error = null) {
    this.results.total++;
    this.results.failed++;
    console.log(chalk.red(`    ✗ ${message}`));
    if (error) {
      console.log(chalk.red(`      Error: ${JSON.stringify(error, null, 2)}`));
    }
  }

  skip(message) {
    this.results.total++;
    this.results.skipped++;
    console.log(chalk.yellow(`    ⊘ ${message}`));
  }

  info(message) {
    console.log(chalk.cyan(`    ℹ ${message}`));
  }

  warn(message) {
    console.log(chalk.yellow(`    ⚠ ${message}`));
  }

  data(label, data) {
    console.log(chalk.gray(`    ${label}:`), JSON.stringify(data, null, 2));
  }

  summary() {
    console.log('\n' + chalk.bold.magenta('═'.repeat(80)));
    console.log(chalk.bold.magenta('  TEST SUMMARY'));
    console.log(chalk.bold.magenta('═'.repeat(80)));
    console.log(chalk.white(`  Total Tests:   ${this.results.total}`));
    console.log(chalk.green(`  Passed:        ${this.results.passed}`));
    console.log(chalk.red(`  Failed:        ${this.results.failed}`));
    console.log(chalk.yellow(`  Skipped:       ${this.results.skipped}`));
    
    const passRate = this.results.total > 0 
      ? ((this.results.passed / this.results.total) * 100).toFixed(2)
      : 0;
    
    console.log(chalk.bold.white(`  Pass Rate:     ${passRate}%`));
    console.log(chalk.bold.magenta('═'.repeat(80) + '\n'));

    return this.results;
  }

  getResults() {
    return this.results;
  }
}

export default TestLogger;
