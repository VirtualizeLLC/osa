const { execSync } = require('child_process')

const execOptions = { stdio: 'inherit', encoding: 'utf-8' }
const timestamp = new Date().getTime()

/**
 * Increments the app version with a patch
 */
if (process.env.HAS_PUBLISH) {
  execSync('npm version patch', execOptions)
}

const { version, appName } = require('../package.json')
const builtAppName = `${appName}-${version}-${timestamp}`

/**
 * Get allowed devices from environment variable or use empty set for all devices
 * 
 * Environment Variable: ALLOWED_DEVICES
 * Format: Comma-separated list of device identifiers
 * Example: 'ALLOWED_DEVICES=usb:12345,product:device1,emulator:5554'
 * 
 * If not set, all connected devices will be used
 */
const getAllowedDevices = () => {
  if (process.env.ALLOWED_DEVICES) {
    return new Set(
      process.env.ALLOWED_DEVICES.split(',').map(id => id.trim())
    )
  }
  return null // null means use all devices
}

/**
 * Filter ADB devices by allowed list
 * @param {string[]} allDevices - All connected device IDs
 * @param {Set|null} allowedDevices - Allowed device IDs or null to use all
 * @returns {string[]} Filtered device IDs
 */
const filterDevices = (allDevices, allowedDevices) => {
  if (allowedDevices === null) {
    return allDevices
  }
  return allDevices.filter(id => allowedDevices.has(id))
}

/**
 * Get ADB devices - optionally filtered by ALLOWED_DEVICES environment variable
 * 
 * Example device naming patterns:
 * - USB devices: 'usb:SERIALNUMBER' (e.g., 'usb:337969152X')
 * - Product devices: 'product:MODELCODE' (e.g., 'product:pixel6')
 * - Emulators: 'emulator:PORT' (e.g., 'emulator:5554')
 */
const getAdbDevices = () => {
  const allowedDevices = getAllowedDevices()
  
  const devices = execSync('adb devices -l', {
    stdio: 'pipe',
    encoding: 'utf8',
  })
  
  const allDeviceIds = devices
    .split('\n')
    .slice(1)
    .map(line => line.split('device ').map(v => v.split(' ')[0])[1])
    .filter(item => !!item)
  
  return filterDevices(allDeviceIds, allowedDevices)
}

const pushApkToDevices = () => {
  const deviceIds = getAdbDevices()
  deviceIds.forEach(id => {
    execSync(
      `adb -s ${id} push ./android/app/build/outputs/apk/release/app-release.apk /storage/emulated/0/Downloads/${builtAppName}.apk`,
      execOptions,
    )
  })
}

const installApkToDevices = () => {
  const deviceIds = getAdbDevices()
  console.log(deviceIds)
  deviceIds.forEach(id => {
    execSync(
      `adb -s ${id} install ./android/app/build/outputs/apk/release/app-release.apk`,
      execOptions,
    )
  })
}

// Bash alternative
// for SERIAL in $(adb devices | grep -v List | cut -f 1);
// do adb -s $SERIAL install -r /path/to/product.apk;
// done

process.env.HAS_INSTALL_APK && pushApkToDevices()
process.env.HAS_INSTALL && installApkToDevices()

// execSync(
//   `adb -s product:gts7lwifixx push ./android/app/build/outputs/apk/release/app-release.apk /storage/emulated/0/Downloads/${appName}.apk`,
//   execOptions,
// )
