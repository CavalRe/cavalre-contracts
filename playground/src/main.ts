import './style.css'
import { createMemoryClient } from 'tevm'
import { FloatCalculator } from '../contracts/FloatCalculator.s.sol'

// Types
interface FunctionDef {
  name: string
  inputs: { name: string; type: string; placeholder?: string }[]
  category: 'arithmetic' | 'comparisons' | 'transformations' | 'special' | 'utilities' | 'constants'
}

// Function definitions
const functions: FunctionDef[] = [
  // Arithmetic
  { name: 'add', inputs: [{ name: 'a', type: 'decimal', placeholder: '1.5' }, { name: 'b', type: 'decimal', placeholder: '2.5' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'arithmetic' },
  { name: 'subtract', inputs: [{ name: 'a', type: 'decimal', placeholder: '5.0' }, { name: 'b', type: 'decimal', placeholder: '2.0' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'arithmetic' },
  { name: 'multiply', inputs: [{ name: 'a', type: 'decimal', placeholder: '2.5' }, { name: 'b', type: 'decimal', placeholder: '4.0' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'arithmetic' },
  { name: 'divide', inputs: [{ name: 'a', type: 'decimal', placeholder: '10.0' }, { name: 'b', type: 'decimal', placeholder: '4.0' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'arithmetic' },
  { name: 'negate', inputs: [{ name: 'a', type: 'decimal', placeholder: '5.0' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'arithmetic' },

  // Comparisons
  { name: 'isEqual', inputs: [{ name: 'a', type: 'decimal', placeholder: '1.0' }, { name: 'b', type: 'decimal', placeholder: '1.0' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'comparisons' },
  { name: 'isGreaterThan', inputs: [{ name: 'a', type: 'decimal', placeholder: '2.0' }, { name: 'b', type: 'decimal', placeholder: '1.0' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'comparisons' },
  { name: 'isLessThan', inputs: [{ name: 'a', type: 'decimal', placeholder: '1.0' }, { name: 'b', type: 'decimal', placeholder: '2.0' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'comparisons' },
  { name: 'isGreaterOrEqual', inputs: [{ name: 'a', type: 'decimal', placeholder: '2.0' }, { name: 'b', type: 'decimal', placeholder: '2.0' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'comparisons' },
  { name: 'isLessOrEqual', inputs: [{ name: 'a', type: 'decimal', placeholder: '1.0' }, { name: 'b', type: 'decimal', placeholder: '2.0' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'comparisons' },

  // Transformations
  { name: 'absoluteValue', inputs: [{ name: 'a', type: 'decimal', placeholder: '-5.5' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'transformations' },
  { name: 'getIntegerPart', inputs: [{ name: 'a', type: 'decimal', placeholder: '3.14159' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'transformations' },
  { name: 'shift', inputs: [{ name: 'a', type: 'decimal', placeholder: '1.5' }, { name: 'decimals', type: 'uint256', placeholder: '18' }, { name: 'places', type: 'int256', placeholder: '2' }], category: 'transformations' },
  { name: 'roundTo', inputs: [{ name: 'a', type: 'decimal', placeholder: '3.14159' }, { name: 'decimals', type: 'uint256', placeholder: '18' }, { name: 'digits', type: 'uint256', placeholder: '3' }], category: 'transformations' },

  // Special Functions
  { name: 'exponential', inputs: [{ name: 'a', type: 'int256', placeholder: '1000000000000000000' }], category: 'special' },
  { name: 'naturalLog', inputs: [{ name: 'a', type: 'decimal', placeholder: '2.718281828' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'special' },
  { name: 'cubicSolve', inputs: [{ name: 'b', type: 'decimal', placeholder: '0' }, { name: 'c', type: 'decimal', placeholder: '-1' }, { name: 'd', type: 'decimal', placeholder: '0' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'special' },
  { name: 'fullMulDiv', inputs: [{ name: 'a', type: 'decimal', placeholder: '2.0' }, { name: 'b', type: 'decimal', placeholder: '3.0' }, { name: 'c', type: 'decimal', placeholder: '4.0' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'special' },

  // Utilities
  { name: 'toFloatString', inputs: [{ name: 'value', type: 'decimal', placeholder: '123.456' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'utilities' },
  { name: 'getComponents', inputs: [{ name: 'value', type: 'decimal', placeholder: '1.5' }, { name: 'decimals', type: 'uint256', placeholder: '18' }], category: 'utilities' },
  { name: 'fromComponents', inputs: [{ name: 'mantissa', type: 'int256', placeholder: '150000000000000000' }, { name: 'exponent', type: 'int256', placeholder: '-17' }], category: 'utilities' },
  { name: 'normalize', inputs: [{ name: 'mantissa', type: 'int256', placeholder: '1500' }, { name: 'exponent', type: 'int256', placeholder: '0' }], category: 'utilities' },

  // Constants
  { name: 'zero', inputs: [], category: 'constants' },
  { name: 'one', inputs: [], category: 'constants' },
  { name: 'two', inputs: [], category: 'constants' },
  { name: 'ten', inputs: [], category: 'constants' },
]

// Parse decimal string to bigint with given decimals
function parseDecimalString(value: string, decimals: number): bigint {
  const isNegative = value.startsWith('-')
  const absValue = isNegative ? value.slice(1) : value
  const [whole, frac = ''] = absValue.split('.')
  const fracPadded = frac.padEnd(decimals, '0').slice(0, decimals)
  const result = BigInt(whole + fracPadded)
  return isNegative ? -result : result
}

// App state
let client: Awaited<ReturnType<typeof createMemoryClient>> | null = null
let contractAddress: `0x${string}` | null = null
let currentTab = 'arithmetic'

// Initialize Tevm client and deploy contract
async function initializeClient() {
  const statusDot = document.querySelector('.status-dot')
  const statusText = document.querySelector('.status-text')

  statusDot?.classList.add('loading')
  if (statusText) statusText.textContent = 'Deploying contract...'

  try {
    client = createMemoryClient()
    contractAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3'
    await client.setCode({
      address: contractAddress,
      bytecode: FloatCalculator.deployedBytecode,
    })

    statusDot?.classList.remove('loading')
    if (statusText) statusText.textContent = `Contract deployed at ${contractAddress.slice(0, 10)}...${contractAddress.slice(-8)}`

    const addressEl = document.querySelector('.address')
    if (addressEl) addressEl.textContent = contractAddress
  } catch (error) {
    console.error('Failed to deploy contract:', error)
    statusDot?.classList.remove('loading')
    if (statusText) statusText.textContent = 'Failed to deploy contract'
  }
}

// Call contract function
async function callFunction(functionName: string, args: unknown[]): Promise<string> {
  if (!client || !contractAddress) {
    throw new Error('Client not initialized')
  }

  const result = await client.tevmContract({
    to: contractAddress,
    abi: FloatCalculator.abi,
    functionName,
    args,
  })

  if (result.errors && result.errors.length > 0) {
    throw new Error(result.errors[0].message || 'Contract call failed')
  }

  // Format result
  const data = result.data
  if (typeof data === 'boolean') {
    return data ? 'true' : 'false'
  }
  if (Array.isArray(data)) {
    return data.map(v => String(v)).join(', ')
  }
  return String(data)
}

// Create function card HTML
function createFunctionCard(fn: FunctionDef): string {
  const inputsHtml = fn.inputs.map(input => `
    <div class="input-group">
      <label class="input-label">
        ${input.name} <span class="type">(${input.type})</span>
      </label>
      <input
        type="text"
        class="input-field"
        data-fn="${fn.name}"
        data-input="${input.name}"
        data-type="${input.type}"
        placeholder="${input.placeholder || ''}"
      />
    </div>
  `).join('')

  return `
    <div class="function-card" data-fn="${fn.name}">
      <div class="function-header">
        <span class="chevron">▶</span>
        <span class="function-name">${fn.name}</span>
        <span class="function-badge pure">pure</span>
      </div>
      <div class="function-body">
        ${inputsHtml}
        <button class="query-btn" data-fn="${fn.name}">Query</button>
        <div class="result-container" style="display: none;">
          <div class="result-label">Result:</div>
          <div class="result-value"></div>
        </div>
      </div>
    </div>
  `
}

// Render UI
function render() {
  const app = document.querySelector<HTMLDivElement>('#app')!

  const categories = {
    arithmetic: functions.filter(f => f.category === 'arithmetic'),
    comparisons: functions.filter(f => f.category === 'comparisons'),
    transformations: functions.filter(f => f.category === 'transformations'),
    special: functions.filter(f => f.category === 'special'),
    utilities: functions.filter(f => f.category === 'utilities'),
    constants: functions.filter(f => f.category === 'constants'),
  }

  app.innerHTML = `
    <div class="header">
      <h1>
        FloatCalculator
        <span class="contract-badge">Contract</span>
      </h1>
      <div class="address">Deploying...</div>
    </div>

    <div class="status-bar">
      <div class="status-dot loading"></div>
      <span class="status-text">Initializing Tevm...</span>
    </div>

    <div class="tabs">
      <button class="tab ${currentTab === 'arithmetic' ? 'active' : ''}" data-tab="arithmetic">Arithmetic</button>
      <button class="tab ${currentTab === 'comparisons' ? 'active' : ''}" data-tab="comparisons">Comparisons</button>
      <button class="tab ${currentTab === 'transformations' ? 'active' : ''}" data-tab="transformations">Transforms</button>
      <button class="tab ${currentTab === 'special' ? 'active' : ''}" data-tab="special">Special</button>
      <button class="tab ${currentTab === 'utilities' ? 'active' : ''}" data-tab="utilities">Utilities</button>
      <button class="tab ${currentTab === 'constants' ? 'active' : ''}" data-tab="constants">Constants</button>
    </div>

    ${Object.entries(categories).map(([category, fns]) => `
      <div class="section ${category === currentTab ? 'active' : ''}" data-section="${category}">
        <div class="functions-container">
          ${fns.map(fn => createFunctionCard(fn)).join('')}
        </div>
      </div>
    `).join('')}
  `

  // Add event listeners
  setupEventListeners()
}

// Setup event listeners
function setupEventListeners() {
  // Tab switching
  document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', (e) => {
      const target = e.target as HTMLElement
      const tabName = target.dataset.tab
      if (tabName) {
        currentTab = tabName
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'))
        target.classList.add('active')
        document.querySelectorAll('.section').forEach(s => s.classList.remove('active'))
        document.querySelector(`.section[data-section="${tabName}"]`)?.classList.add('active')
      }
    })
  })

  // Function card expansion
  document.querySelectorAll('.function-header').forEach(header => {
    header.addEventListener('click', () => {
      const card = header.closest('.function-card')
      card?.classList.toggle('expanded')
    })
  })

  // Query buttons
  document.querySelectorAll('.query-btn').forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const target = e.target as HTMLButtonElement
      const fnName = target.dataset.fn
      if (!fnName) return

      const card = target.closest('.function-card')
      const resultContainer = card?.querySelector('.result-container') as HTMLElement
      const resultValue = card?.querySelector('.result-value') as HTMLElement

      // Get function definition
      const fnDef = functions.find(f => f.name === fnName)
      if (!fnDef) return

      // Collect input values
      const args: unknown[] = []
      for (const input of fnDef.inputs) {
        const inputEl = card?.querySelector(`input[data-input="${input.name}"]`) as HTMLInputElement
        const value = inputEl?.value || inputEl?.placeholder || '0'

        if (input.type === 'decimal') {
          // Get decimals value
          const decimalsInput = card?.querySelector('input[data-input="decimals"]') as HTMLInputElement
          const decimals = parseInt(decimalsInput?.value || decimalsInput?.placeholder || '18')
          args.push(parseDecimalString(value, decimals))
        } else if (input.type === 'int256' || input.type === 'uint256') {
          args.push(BigInt(value))
        } else {
          args.push(value)
        }
      }

      // Show loading
      resultContainer.style.display = 'block'
      resultValue.className = 'result-value loading'
      resultValue.textContent = 'Loading...'
      target.disabled = true

      try {
        const result = await callFunction(fnName, args)
        resultValue.className = 'result-value'
        resultValue.textContent = result
      } catch (error) {
        resultValue.className = 'result-value error'
        resultValue.textContent = error instanceof Error ? error.message : String(error)
      } finally {
        target.disabled = false
      }
    })
  })
}

// Initialize app
render()
initializeClient()
