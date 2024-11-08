<script>
  import { onMount, onDestroy } from "svelte";
  import { scaleLinear, scaleTime } from "d3-scale";
  import { line } from "d3-shape";
  import { select } from "d3-selection";
  import { timeFormat } from "d3-time-format";
  import { extent, max } from "d3-array";

  let metrics = null;
  let history = [];
  let haproxyHistory = [];
  let error = null;
  let interval;

  const COLORS = {
    ALIVE: "#00C49F",
    SUSPECT: "#FFBB28",
    DEAD: "#FF8042",
  };

  async function fetchMetrics() {
    try {
      const response = await fetch("/api/metrics");
      const data = await response.json();
      metrics = data;

      // Update system metrics history
      history = [
        ...history,
        {
          timestamp: new Date(data.timestamp),
          cpu: data.cpu_usage,
          memory: data.memory_usage / 1024 / 1024,
          wsClients: data.websocket_clients,
          configKeys: data.config_keys,
        },
      ].slice(-20);

      // Update HAProxy metrics history
      haproxyHistory = [
        ...haproxyHistory,
        {
          timestamp: new Date(data.timestamp),
          currentConns: data.haproxy?.current_conns || 0,
          totalRequests: data.haproxy?.total_requests || 0,
          bytesIn: data.haproxy?.bytes_in || 0,
          bytesOut: data.haproxy?.bytes_out || 0,
        },
      ].slice(-20);
    } catch (err) {
      error = "Failed to fetch metrics";
      console.error("Fetch error:", err);
    }
  }

  onMount(() => {
    fetchMetrics();
    interval = setInterval(fetchMetrics, 5000);
  });

  onDestroy(() => {
    if (interval) clearInterval(interval);
  });

  function createLineChart(data) {
    if (!data || data.length === 0) return "";

    const width = 600;
    const height = 300;
    const margin = { top: 20, right: 30, bottom: 30, left: 40 };

    const x = scaleTime()
      .domain(extent(data, (d) => d.timestamp))
      .range([margin.left, width - margin.right]);

    const y = scaleLinear()
      .domain([0, max(data, (d) => Math.max(d.cpu, d.memory / 10))])
      .nice()
      .range([height - margin.bottom, margin.top]);

    const cpuLine = line()
      .x((d) => x(d.timestamp))
      .y((d) => y(d.cpu));

    const memoryLine = line()
      .x((d) => x(d.timestamp))
      .y((d) => y(d.memory / 10));

    const xTicks = x.ticks(5);
    const yTicks = y.ticks(6);

    return `
    <svg viewBox="0 0 ${width} ${height}">
      <g class="grid">
        ${yTicks
          .map(
            (tick) => `
          <line 
            x1="${margin.left}" 
            x2="${width - margin.right}"
            y1="${y(tick)}"
            y2="${y(tick)}"
          ></line>
        `,
          )
          .join("")}
      </g>
      
      <g class="axis x-axis" transform="translate(0,${height - margin.bottom})">
        <path d="M${margin.left},0H${width - margin.right}"></path>
        ${xTicks
          .map(
            (tick) => `
          <g transform="translate(${x(tick)},0)">
            <line y2="6"></line>
            <text y="9" dy="0.71em" text-anchor="middle" font-size="14" fill="#9CA3AF">
              ${timeFormat("%H:%M:%S")(tick)}
            </text>
          </g>
        `,
          )
          .join("")}
      </g>
      
      <g class="axis y-axis" transform="translate(${margin.left},0)">
        <path d="M0,${margin.top}V${height - margin.bottom}"></path>
        ${yTicks
          .map(
            (tick) => `
          <g transform="translate(0,${y(tick)})">
            <line x2="-6"></line>
            <text x="-9" dy="0.32em" text-anchor="end" font-size="14" fill="#9CA3AF">
              ${tick}
            </text>
          </g>
        `,
          )
          .join("")}
      </g>
      
      <path class="line cpu-line" d="${cpuLine(data)}" stroke="#60A5FA"/>
      <path class="line memory-line" d="${memoryLine(data)}" stroke="#34D399"/>
    </svg>
  `;
  }

  function createHAProxyChart(data) {
    if (!data || data.length === 0) return "";

    const width = 600;
    const height = 300;
    const margin = { top: 20, right: 30, bottom: 30, left: 40 };

    const x = scaleTime()
      .domain(extent(data, (d) => d.timestamp))
      .range([margin.left, width - margin.right]);

    const y = scaleLinear()
      .domain([0, max(data, (d) => d.currentConns)])
      .nice()
      .range([height - margin.bottom, margin.top]);

    const connLine = line()
      .x((d) => x(d.timestamp))
      .y((d) => y(d.currentConns));

    const xTicks = x.ticks(5);
    const yTicks = y.ticks(6);

    return `
    <svg viewBox="0 0 ${width} ${height}">
      <g class="grid">
        ${yTicks
          .map(
            (tick) => `
          <line 
            x1="${margin.left}" 
            x2="${width - margin.right}"
            y1="${y(tick)}"
            y2="${y(tick)}"
          ></line>
        `,
          )
          .join("")}
      </g>
      
      <g class="axis x-axis" transform="translate(0,${height - margin.bottom})">
        <path d="M${margin.left},0H${width - margin.right}"></path>
        ${xTicks
          .map(
            (tick) => `
          <g transform="translate(${x(tick)},0)">
            <line y2="6"></line>
            <text y="9" dy="0.71em" text-anchor="middle" font-size="8" fill="#9CA3AF">
              ${timeFormat("%H:%M:%S")(tick)}
            </text>
          </g>
        `,
          )
          .join("")}
      </g>
      
      <g class="axis y-axis" transform="translate(${margin.left},0)">
        <path d="M0,${margin.top}V${height - margin.bottom}"></path>
        ${yTicks
          .map(
            (tick) => `
          <g transform="translate(0,${y(tick)})">
            <line x2="-6"></line>
            <text x="-9" dy="0.32em" text-anchor="end" font-size="8" fill="#9CA3AF">
              ${tick}
            </text>
          </g>
        `,
          )
          .join("")}
      </g>
      
      <path class="line haproxy-line" d="${connLine(data)}"/>
    </svg>
  `;
  }
</script>

<main class="container">
  {#if error}
    <div class="error">
      <p>{error}</p>
    </div>
  {/if}

  {#if metrics}
    <!-- Three-column grid for metric cards -->
    <div class="metrics-grid">
      <!-- Column 1 -->
      <div class="card">
        <h3>Cluster Health</h3>
        <div class="metric">
          <span class="value">{metrics.cluster.cluster_health.toFixed(1)}%</span
          >
          <span class="label">{metrics.cluster.member_count} Total Nodes</span>
        </div>
      </div>

      <div class="card">
        <h3>Config Keys</h3>
        <div class="metric">
          <span class="value">{metrics.config_keys}</span>
          <span class="label">Active Configuration Keys</span>
        </div>
      </div>

      <!-- Column 2 -->
      <div class="card">
        <h3>HAProxy Connections</h3>
        <div class="metric">
          <span class="value">{metrics.haproxy?.current_conns || 0}</span>
          <span class="label">Current Connections</span>
        </div>
      </div>

      <div class="card">
        <h3>Total Requests</h3>
        <div class="metric">
          <span class="value"
            >{metrics.haproxy?.total_requests?.toLocaleString() || 0}</span
          >
          <span class="label">HAProxy Requests</span>
        </div>
      </div>

      <!-- Column 3 -->
      <!-- System Metrics Chart -->
      <div class="card">
        <h3>System Metrics History</h3>
        {@html createLineChart(history)}
      </div>

      <!-- HAProxy Chart -->
      <div class="card">
        <h3>HAProxy Connections History</h3>
        {@html createHAProxyChart(haproxyHistory)}
      </div>
    </div>

    <!-- Cluster Status below the grid -->
    <div class="card cluster-status">
      <h3>Cluster Status</h3>
      <div class="node-status">
        {#each metrics.cluster.members as member}
          <div class="node" style="background-color: {COLORS[member.state]}">
            <span class="node-name">{member.name}</span>
            <span class="node-state">{member.state}</span>
          </div>
        {/each}
      </div>
    </div>
  {:else}
    <div class="loading">Loading metrics...</div>
  {/if}
</main>

<style>
  :global(body) {
    background-color: #111827;
    color: #f3f4f6;
  }

  .container {
    padding: 1rem;
    max-width: 1400px;
    margin: 0 auto;
  }

  .metrics-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    grid-template-rows: auto auto;
    gap: 1rem;
    margin-bottom: 1rem;
  }

  .card {
    background: #1f2937;
    border-radius: 8px;
    padding: 1rem;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
    border: 1px solid #374151;
  }

  .metric {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  h3 {
    color: #d1d5db;
    margin-bottom: 1rem;
    font-size: 1.1rem;
  }

  .value {
    font-size: 2rem;
    font-weight: bold;
    color: #f3f4f6;
  }

  .label {
    color: #9ca3af;
    font-size: 0.875rem;
  }

  .cluster-status {
    margin-top: 1rem;
  }

  .node-status {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 0.5rem;
    padding: 1rem;
  }

  .node {
    padding: 1rem;
    border-radius: 4px;
    color: white;
    display: flex;
    flex-direction: column;
    align-items: center;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  }

  .node-name {
    font-weight: bold;
  }

  .error {
    background: #7f1d1d;
    color: #fca5a5;
    padding: 1rem;
    border-radius: 4px;
    margin-bottom: 1rem;
  }

  .loading {
    text-align: center;
    padding: 2rem;
    color: #9ca3af;
  }

  :global(.line) {
    fill: none;
    stroke-width: 1.5;
  }

  :global(.axis line) {
    stroke: #374151;
  }

  :global(.axis path) {
    stroke: #4b5563;
  }

  :global(.grid line) {
    stroke: #374151;
    stroke-opacity: 0.2;
  }

  :global(.haproxy-line) {
    stroke: #f97316;
    stroke-width: 1.5;
  }

  @media (max-width: 1200px) {
    .metrics-grid {
      grid-template-columns: 1fr;
    }
  }
</style>
