#!/usr/bin/env node

import * as apn from 'apn';
import * as readlineSync from 'readline-sync';
import * as fs from 'fs';
import * as path from 'path';
import { randomUUID } from 'crypto';

interface PushConfig {
  deviceToken: string;
  bundleId: string;
  certPath: string;
  keyPath: string;
  environment: 'production' | 'sandbox';
}

interface SavedConfig {
  deviceToken?: string;
  bundleId?: string;
  certPath?: string;
  keyPath?: string;
  environment?: 'production' | 'sandbox';
  lastUsed?: number;
}

class VoIPPushTester {
  private config: PushConfig;
  private configPath: string;

  constructor() {
    this.configPath = path.join(__dirname, '..', '.last-config.json');
    this.config = this.collectUserInput();
  }

  private loadSavedConfig(): SavedConfig | null {
    try {
      if (fs.existsSync(this.configPath)) {
        const data = fs.readFileSync(this.configPath, 'utf8');
        return JSON.parse(data);
      }
    } catch (error) {
      console.log('⚠️  Could not load previous configuration');
    }
    return null;
  }

  private saveConfig(config: PushConfig): void {
    try {
      const savedConfig: SavedConfig = {
        deviceToken: config.deviceToken,
        bundleId: config.bundleId,
        certPath: config.certPath,
        keyPath: config.keyPath,
        environment: config.environment,
        lastUsed: Date.now()
      };
      fs.writeFileSync(this.configPath, JSON.stringify(savedConfig, null, 2));
    } catch (error) {
      console.log('⚠️  Could not save configuration for next time');
    }
  }

  private showQuickStartMenu(savedConfig: SavedConfig): 'use-saved' | 'update-selective' | 'start-fresh' {
    console.log('\n🔔 Telnyx VoIP Push Notification Tester');
    console.log('=========================================\n');
    
    console.log('📋 Previous configuration found:');
    console.log(`   Device Token: ${savedConfig.deviceToken?.substring(0, 8)}...${savedConfig.deviceToken?.substring(56)}`);
    console.log(`   Bundle ID: ${savedConfig.bundleId}`);
    console.log(`   Certificate: ${savedConfig.certPath ? path.basename(savedConfig.certPath) : 'N/A'}`);
    console.log(`   Private Key: ${savedConfig.keyPath ? path.basename(savedConfig.keyPath) : 'N/A'}`);
    console.log(`   Environment: ${savedConfig.environment}`);
    console.log(`   Last used: ${savedConfig.lastUsed ? new Date(savedConfig.lastUsed).toLocaleString() : 'Unknown'}\n`);

    const options = [
      'Use previous configuration',
      'Update some values',
      'Start fresh with new configuration'
    ];

    const choice = readlineSync.keyInSelect(options, 'What would you like to do? ');
    
    switch (choice) {
      case 0: return 'use-saved';
      case 1: return 'update-selective';
      case 2: return 'start-fresh';
      default: 
        console.log('❌ Operation cancelled');
        process.exit(0);
    }
  }

  private collectUserInput(): PushConfig {
    const savedConfig = this.loadSavedConfig();
    
    let deviceToken: string;
    let bundleId: string;
    let certPath: string;
    let keyPath: string;
    let environment: 'production' | 'sandbox';

    if (savedConfig) {
      const choice = this.showQuickStartMenu(savedConfig);
      
      if (choice === 'use-saved') {
        // Use all saved values with prompts for missing ones
        deviceToken = savedConfig.deviceToken || this.promptForDeviceToken();
        bundleId = savedConfig.bundleId || this.promptForBundleId();
        certPath = savedConfig.certPath || this.promptForCertPath();
        keyPath = savedConfig.keyPath || this.promptForKeyPath();
        environment = savedConfig.environment || this.promptForEnvironment();
      } else if (choice === 'update-selective') {
        // Allow selective updates
        console.log('\n📝 Update Configuration');
        console.log('Press Enter to keep current value, or type new value:\n');
        
        deviceToken = this.promptForDeviceToken(savedConfig.deviceToken);
        bundleId = this.promptForBundleId(savedConfig.bundleId);
        certPath = this.promptForCertPath(savedConfig.certPath);
        keyPath = this.promptForKeyPath(savedConfig.keyPath);
        environment = this.promptForEnvironment(savedConfig.environment);
      } else {
        // Start fresh
        console.log('\n🆕 New Configuration');
        console.log('===================\n');
        deviceToken = this.promptForDeviceToken();
        bundleId = this.promptForBundleId();
        certPath = this.promptForCertPath();
        keyPath = this.promptForKeyPath();
        environment = this.promptForEnvironment();
      }
    } else {
      // No saved config, start fresh
      console.log('\n🔔 Telnyx VoIP Push Notification Tester');
      console.log('=========================================\n');
      deviceToken = this.promptForDeviceToken();
      bundleId = this.promptForBundleId();
      certPath = this.promptForCertPath();
      keyPath = this.promptForKeyPath();
      environment = this.promptForEnvironment();
    }

    const finalConfig = {
      deviceToken,
      bundleId,
      certPath,
      keyPath,
      environment
    };

    // Save configuration for next time
    this.saveConfig(finalConfig);

    return finalConfig;
  }

  private promptForDeviceToken(defaultValue?: string): string {
    const prompt = defaultValue 
      ? `Device token [${defaultValue.substring(0, 8)}...${defaultValue.substring(56)}]: `
      : 'Enter the device token (64 hex characters): ';
    
    const input = readlineSync.question(prompt);
    const deviceToken = input.trim() || defaultValue;
    
    if (!deviceToken) {
      console.error('❌ Device token is required.');
      process.exit(1);
    }
    
    if (!this.validateDeviceToken(deviceToken)) {
      console.error('❌ Invalid device token format. Must be 64 hex characters.');
      process.exit(1);
    }
    
    return deviceToken;
  }

  private promptForBundleId(defaultValue?: string): string {
    const prompt = defaultValue 
      ? `Bundle ID [${defaultValue}]: `
      : 'Enter the bundle ID (e.g., com.yourcompany.app): ';
    
    const input = readlineSync.question(prompt);
    const bundleId = input.trim() || defaultValue;
    
    if (!bundleId) {
      console.error('❌ Bundle ID is required.');
      process.exit(1);
    }
    
    return bundleId;
  }

  private promptForCertPath(defaultValue?: string): string {
    const prompt = defaultValue 
      ? `Certificate path [${path.basename(defaultValue)}]: `
      : 'Enter the path to your cert.pem file: ';
    
    const input = readlineSync.question(prompt);
    const certPath = input.trim() || defaultValue;
    
    if (!certPath) {
      console.error('❌ Certificate path is required.');
      process.exit(1);
    }
    
    if (!fs.existsSync(certPath)) {
      console.error('❌ Certificate file (cert.pem) not found at specified path.');
      process.exit(1);
    }

    if (!this.validatePemFile(certPath, 'CERTIFICATE')) {
      console.error('❌ Invalid certificate file format. Must be a valid PEM certificate.');
      process.exit(1);
    }
    
    return certPath;
  }

  private promptForKeyPath(defaultValue?: string): string {
    const prompt = defaultValue 
      ? `Private key path [${path.basename(defaultValue)}]: `
      : 'Enter the path to your key.pem file: ';
    
    const input = readlineSync.question(prompt);
    const keyPath = input.trim() || defaultValue;
    
    if (!keyPath) {
      console.error('❌ Private key path is required.');
      process.exit(1);
    }
    
    if (!fs.existsSync(keyPath)) {
      console.error('❌ Private key file (key.pem) not found at specified path.');
      process.exit(1);
    }

    if (!this.validatePemFile(keyPath, 'PRIVATE KEY')) {
      console.error('❌ Invalid private key file format. Must be a valid PEM private key.');
      process.exit(1);
    }
    
    return keyPath;
  }

  private promptForEnvironment(defaultValue?: 'production' | 'sandbox'): 'production' | 'sandbox' {
    if (defaultValue) {
      const keepDefault = readlineSync.keyInYNStrict(`Keep environment as '${defaultValue}'? `);
      if (keepDefault) {
        return defaultValue;
      }
    }
    
    const envIndex = readlineSync.keyInSelect(['sandbox', 'production'], 'Select environment: ');
    return envIndex === 0 ? 'sandbox' : envIndex === 1 ? 'production' : 'sandbox';
  }

  private validateDeviceToken(token: string): boolean {
    return /^[a-fA-F0-9]{64}$/.test(token);
  }

  private validatePemFile(filePath: string, expectedType: string): boolean {
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const beginMarker = `-----BEGIN ${expectedType}-----`;
      const endMarker = `-----END ${expectedType}-----`;
      
      return content.includes(beginMarker) && content.includes(endMarker);
    } catch (error) {
      return false;
    }
  }

  private createAPNProvider(): apn.Provider {
    try {
      const options: apn.ProviderOptions = {
        cert: this.config.certPath,
        key: this.config.keyPath,
        production: this.config.environment === 'production'
      };

      return new apn.Provider(options);
    } catch (error) {
      console.error('❌ Failed to create APN provider:', error);
      console.error('   Make sure your certificate and key files are valid PEM format.');
      process.exit(1);
    }
  }

  private createNotification(): apn.Notification {
    const notification = new apn.Notification();
    
    // VoIP notifications don't use alerts, sounds, or badges
    notification.topic = this.config.bundleId + '.voip';
    notification.priority = 10; // High priority for VoIP
    notification.expiry = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

    // Default VoIP payload structure expected by Telnyx iOS SDK with proper UUIDs
    const metadata = {
      voice_sdk_id: randomUUID(),
      call_id: randomUUID(),
      caller_name: 'Test Caller',
      caller_number: '+1234567890'
    };

    // VoIP payload structure expected by TxClient.processVoIPNotification
    notification.payload = {
      metadata: metadata
    };

    return notification;
  }

  public async sendPush(): Promise<void> {
    console.log('\n📡 Configuring APN provider...');
    const provider = this.createAPNProvider();

    console.log('📋 Creating notification...');
    const notification = this.createNotification();

    console.log('📤 Sending VoIP push notification...');
    console.log('Device Token:', this.config.deviceToken);
    console.log('Bundle ID:', this.config.bundleId);
    console.log('Environment:', this.config.environment);
    console.log('Payload:', JSON.stringify(notification.payload, null, 2));

    try {
      const result = await provider.send(notification, this.config.deviceToken);
      
      if (result.sent.length > 0) {
        console.log('✅ Push notification sent successfully!');
        result.sent.forEach(device => {
          console.log(`   → Device: ${device.device}`);
        });
      }

      if (result.failed.length > 0) {
        console.log('❌ Failed to send to some devices:');
        result.failed.forEach(failure => {
          console.log(`   → Device: ${failure.device}`);
          console.log(`   → Status: ${failure.status}`);
          console.log(`   → Response: ${JSON.stringify(failure.response, null, 2)}`);
          
          // Additional error details if available
          if (failure.error) {
            console.log(`   → Error: ${JSON.stringify(failure.error, null, 2)}`);
          }
        });
      }
    } catch (error) {
      console.error('❌ Error sending push notification:', error);
    } finally {
      provider.shutdown();
    }
  }

  public displaySummary(): void {
    console.log('\n📊 Configuration Summary:');
    console.log('========================');
    console.log(`Device Token: ${this.config.deviceToken.substring(0, 8)}...${this.config.deviceToken.substring(56)}`);
    console.log(`Bundle ID: ${this.config.bundleId}`);
    console.log(`Certificate: ${path.basename(this.config.certPath)}`);
    console.log(`Private Key: ${path.basename(this.config.keyPath)}`);
    console.log(`Environment: ${this.config.environment}`);
    console.log('');
  }
}

// Main execution
async function main() {
  try {
    let tester = new VoIPPushTester();
    
    while (true) {
      tester.displaySummary();
      
      const proceed = readlineSync.keyInYNStrict('Send the VoIP push notification? ');
      if (proceed) {
        await tester.sendPush();
        console.log('\n🎉 Done! Check your iOS device for the incoming call.');
      } else {
        console.log('❌ Push notification cancelled.');
      }

      // Post-action menu
      console.log('\n🔄 What would you like to do next?');
      const nextActions = [
        'Send another push notification with same config',
        'Reconfigure settings and send new push',
        'Exit'
      ];

      const nextAction = readlineSync.keyInSelect(nextActions, 'Choose an option: ');
      
      switch (nextAction) {
        case 0:
          // Continue with same tester instance (will generate new UUIDs)
          continue;
        case 1:
          // Create new tester instance to reconfigure
          tester = new VoIPPushTester();
          continue;
        case 2:
          console.log('\n👋 Goodbye!');
          process.exit(0);
        default:
          console.log('\n👋 Goodbye!');
          process.exit(0);
      }
    }
  } catch (error) {
    console.error('💥 Unexpected error:', error);
    process.exit(1);
  }
}

// Run the program
if (require.main === module) {
  main();
}

export { VoIPPushTester, PushConfig };