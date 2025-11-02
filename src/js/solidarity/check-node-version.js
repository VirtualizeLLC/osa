#!/usr/bin/env node
'use strict'

const fs = require('fs')
const path = require('path')

function normalize(v) {
  if (!v) return ''
  return v.trim().replace(/^v/, '')
}

function getMajor(versionStr) {
  if (!versionStr) return ''
  const parts = versionStr.split('.')
  return parts[0]
}

const repoNodeFile = path.resolve(process.cwd(), '.node-version')

if (!fs.existsSync(repoNodeFile)) {
  console.error('.node-version file not found in repo root; skipping node-version check.')
  // Return success so solidarity doesn't fail when .node-version is intentionally absent
  process.exit(0)
}

const expectedRaw = fs.readFileSync(repoNodeFile, 'utf8')
const expected = normalize(expectedRaw)
const expectedMajor = getMajor(expected)

const installedRaw = process.version // e.g. "v18.12.1"
const installed = normalize(installedRaw)
const installedMajor = getMajor(installed)

if (!expectedMajor) {
  console.error('Could not parse .node-version; file is empty or malformed.')
  process.exit(1)
}

if (installedMajor === expectedMajor) {
  console.log(`OK: installed node ${installed} matches .node-version ${expectedRaw.trim()} (major ${expectedMajor})`)
  process.exit(0)
} else {
  console.error(`Mismatch: installed node ${installed} != .node-version ${expectedRaw.trim()}`)
  console.error(`Please install/use node ${expectedRaw.trim()} (e.g. nvm install ${expectedRaw.trim()} && nvm use ${expectedRaw.trim()})`)
  process.exit(2)
}
