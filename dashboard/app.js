/**
 * Logistics Dashboard Application Logic
 * Fetches data, calculates metrics, and renders Chart.js visualizations
 */

// ─── Constants & Styling ─────────────────────────────────────────────────────
const DATA_URL = '../data/logistics_orders.csv';

// Premium Color Palette matching Porter.in Light Theme
const COLORS = {
    primary: '#0041F5',
    primaryLight: 'rgba(0, 65, 245, 0.1)',
    success: '#10b981',
    successLight: 'rgba(16, 185, 129, 0.2)',
    warning: '#f59e0b',
    danger: '#ef4444',
    purple: '#8b5cf6',
    teal: '#14b8a6',
    text: '#0f172a',
    textMuted: '#64748b',
    gridLines: '#e2e8f0'
};

// Global Chart Settings (applied safely if Chart is loaded)
if (typeof Chart !== 'undefined') {
    Chart.defaults.color = COLORS.textMuted;
    Chart.defaults.font.family = "'Inter', sans-serif";
    Chart.defaults.scale.grid.color = COLORS.gridLines;
    Chart.defaults.plugins.tooltip.backgroundColor = 'rgba(255, 255, 255, 0.95)';
    Chart.defaults.plugins.tooltip.titleColor = COLORS.text;
    Chart.defaults.plugins.tooltip.bodyColor = COLORS.text;
    Chart.defaults.plugins.tooltip.padding = 10;
    Chart.defaults.plugins.tooltip.cornerRadius = 8;
    Chart.defaults.plugins.tooltip.borderColor = '#e2e8f0';
    Chart.defaults.plugins.tooltip.borderWidth = 1;
}

// ─── State ───────────────────────────────────────────────────────────────────
let rawData = [];
let filteredData = [];
let charts = {};

// Formatter utilities
const formatCurrency = (val) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(val);
const formatNumber = (val) => new Intl.NumberFormat('en-IN').format(val);
const formatPercent = (val) => `${(val).toFixed(1)}%`;

// Candidate paths for dataset to support running server from root or from /dashboard
const CANDIDATE_URLS = [
    'data/logistics_orders.csv',
    '../data/logistics_orders.csv',
    '/data/logistics_orders.csv',
    './data/logistics_orders.csv'
];

// ─── Initialization ──────────────────────────────────────────────────────────
async function init() {
    const badge = document.querySelector('.header__badge');
    if (badge) {
        badge.textContent = 'Loading Data...';
        badge.style.background = '#f59e0b';
        badge.style.color = '#ffffff';
    }

    if (typeof Papa === 'undefined' || typeof Chart === 'undefined') {
        const errorHtml = `
            <div style="text-align:center; padding: 60px 20px; max-width: 600px; margin: 40px auto; background: white; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08);">
                <h2 style="color: #ef4444; margin-bottom: 12px;">CDN Resources Blocked or Offline</h2>
                <p style="color: #64748b; line-height: 1.6;">
                    Chart.js or PapaParse could not be loaded from CDN. Please check your internet connection and reload the page.
                </p>
            </div>
        `;
        document.querySelector('.main').innerHTML = errorHtml;
        return;
    }

    let csvText = null;
    let successfulUrl = null;

    for (const url of CANDIDATE_URLS) {
        try {
            const response = await fetch(url);
            if (response.ok) {
                const text = await response.text();
                // Validate that response is CSV, not HTML 404 page
                if (text && !text.trim().toLowerCase().startsWith('<!doctype') && !text.trim().toLowerCase().startsWith('<html')) {
                    csvText = text;
                    successfulUrl = url;
                    break;
                }
            }
        } catch (e) {
            // Continue probing next URL
        }
    }

    if (!csvText) {
        console.error("Could not locate logistics_orders.csv across candidate paths:", CANDIDATE_URLS);
        const mainEl = document.querySelector('.main');
        if (mainEl) {
            mainEl.innerHTML = `
                <div style="text-align:center; padding: 50px 20px; max-width: 650px; margin: 40px auto; background: #ffffff; border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.08); border: 1px solid #e2e8f0;">
                    <div style="font-size: 40px; margin-bottom: 16px;">⚠️</div>
                    <h2 style="color: #ef4444; margin-bottom: 12px; font-weight: 700;">Could Not Load Logistics Dataset</h2>
                    <p style="color: #475569; font-size: 0.95rem; line-height: 1.6; margin-bottom: 20px;">
                        The browser cannot access <code>logistics_orders.csv</code>. This happens when opened directly using <code>file://</code> (due to browser CORS security) or when the server root does not contain the data file.
                    </p>
                    <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; text-align: left; font-family: monospace; font-size: 0.85rem; color: #0f172a; margin-bottom: 20px;">
                        # 1. Open your terminal in the project root folder:<br>
                        cd c:\\Users\\harsh\\OneDrive\\Desktop\\PRESS\\Logistics<br><br>
                        # 2. Run the HTTP server:<br>
                        python -m http.server 8000<br><br>
                        # 3. Open this URL in your browser:<br>
                        <a href="http://localhost:8000/dashboard/" target="_blank" style="color: #0041F5; text-decoration: underline;">http://localhost:8000/dashboard/</a>
                    </div>
                </div>
            `;
        }
        if (badge) {
            badge.textContent = 'Data Offline';
            badge.style.background = '#ef4444';
        }
        return;
    }

    try {
        Papa.parse(csvText, {
            header: true,
            dynamicTyping: true,
            skipEmptyLines: true,
            complete: (results) => {
                rawData = results.data;
                // Basic cleanup
                rawData.forEach(d => {
                    d.order_date = new Date(d.order_date);
                    d.total_revenue = parseFloat(d.total_revenue) || 0;
                    d.order_value = parseFloat(d.order_value) || 0;
                    d.actual_delivery_min = parseFloat(d.actual_delivery_min) || null;
                    d.estimated_delivery_min = parseFloat(d.estimated_delivery_min) || null;
                });
                
                populateFilters();
                applyFilters();

                if (badge) {
                    badge.textContent = `Online • ${formatNumber(rawData.length)} Orders`;
                    badge.style.background = '';
                    badge.style.color = '';
                }
            }
        });
    } catch (error) {
        console.error("Error parsing CSV:", error);
    }
}

// ─── Filtering ───────────────────────────────────────────────────────────────
function populateFilters() {
    const cities = [...new Set(rawData.map(d => d.city))].filter(Boolean).sort();
    const citySelect = document.getElementById('cityFilter');
    cities.forEach(city => {
        const option = document.createElement('option');
        option.value = city;
        option.textContent = city;
        citySelect.appendChild(option);
    });

    // Event listeners
    document.getElementById('dateStart').addEventListener('change', applyFilters);
    document.getElementById('dateEnd').addEventListener('change', applyFilters);
    document.getElementById('cityFilter').addEventListener('change', applyFilters);
    document.getElementById('vehicleFilter').addEventListener('change', applyFilters);
    document.getElementById('resetFilters').addEventListener('click', () => {
        document.getElementById('dateStart').value = '2023-01-01';
        document.getElementById('dateEnd').value = '2024-12-31';
        document.getElementById('cityFilter').value = 'all';
        document.getElementById('vehicleFilter').value = 'all';
        applyFilters();
    });
}

function applyFilters() {
    const startDate = new Date(document.getElementById('dateStart').value);
    const endDate = new Date(document.getElementById('dateEnd').value);
    const city = document.getElementById('cityFilter').value;
    const vehicle = document.getElementById('vehicleFilter').value;

    filteredData = rawData.filter(d => {
        return d.order_date >= startDate && 
               d.order_date <= endDate &&
               (city === 'all' || d.city === city) &&
               (vehicle === 'all' || d.vehicle_type === vehicle);
    });

    updateDashboard();
}

function updateDashboard() {
    updateKPIs();
    renderRevenueChart();
    renderCityChart();
    renderDeliveryTimeChart();
    renderCancelChart();
    renderPeakHourChart();
    renderDriverTable();
}

// ─── KPI Calculations ────────────────────────────────────────────────────────
function animateValue(obj, start, end, duration, isCurrency = false, isPercent = false) {
    let startTimestamp = null;
    const step = (timestamp) => {
        if (!startTimestamp) startTimestamp = timestamp;
        const progress = Math.min((timestamp - startTimestamp) / duration, 1);
        const current = progress * (end - start) + start;
        
        if (isCurrency) {
            // For large values format in Lakhs/Crores if needed, but let's stick to standard IN format
            obj.innerHTML = formatCurrency(current);
        } else if (isPercent) {
            obj.innerHTML = formatPercent(current);
        } else {
            obj.innerHTML = formatNumber(Math.floor(current));
        }
        if (progress < 1) {
            window.requestAnimationFrame(step);
        } else {
            // Final exact value
            if (isCurrency) obj.innerHTML = formatCurrency(end);
            else if (isPercent) obj.innerHTML = formatPercent(end);
            else obj.innerHTML = formatNumber(end) + (obj.id.includes('Time') ? ' min' : '');
        }
    };
    window.requestAnimationFrame(step);
}

function updateKPIs() {
    const totalRevenue = filteredData.reduce((sum, d) => sum + d.total_revenue, 0);
    const totalOrders = filteredData.length;
    
    const delivered = filteredData.filter(d => d.order_status === 'Delivered');
    const avgDeliveryTime = delivered.length > 0 ? delivered.reduce((sum, d) => sum + (d.actual_delivery_min || 0), 0) / delivered.length : 0;
    
    const cancelled = filteredData.filter(d => d.order_status === 'Cancelled').length;
    const cancelRate = totalOrders > 0 ? (cancelled / totalOrders) * 100 : 0;
    
    const onTime = delivered.filter(d => (d.actual_delivery_min || 0) <= (d.estimated_delivery_min || 0)).length;
    const onTimePct = delivered.length > 0 ? (onTime / delivered.length) * 100 : 0;
    
    const avgOrderValue = totalOrders > 0 ? filteredData.reduce((sum, d) => sum + d.order_value, 0) / totalOrders : 0;

    // Animate values
    animateValue(document.getElementById('kpiRevenue'), 0, totalRevenue, 1000, true);
    animateValue(document.getElementById('kpiOrders'), 0, totalOrders, 1000);
    animateValue(document.getElementById('kpiDeliveryTime'), 0, avgDeliveryTime, 1000, false);
    animateValue(document.getElementById('kpiCancelRate'), 0, cancelRate, 1000, false, true);
    animateValue(document.getElementById('kpiOnTime'), 0, onTimePct, 1000, false, true);
    animateValue(document.getElementById('kpiAOV'), 0, avgOrderValue, 1000, true);
    
    // Mock trends (in a real app, compare with previous period)
    const setTrend = (id, val, goodIsUp) => {
        const el = document.getElementById(id);
        const isGood = goodIsUp ? val >= 0 : val <= 0;
        el.className = `kpi-card__trend ${isGood ? 'kpi-card__trend--up' : 'kpi-card__trend--down'}`;
        el.querySelector('span').textContent = `${val > 0 ? '+' : ''}${val.toFixed(1)}%`;
        // SVG icon change
        const svg = el.querySelector('svg');
        if (val >= 0) {
            svg.innerHTML = '<polyline points="22 7 13.5 15.5 8.5 10.5 2 17"></polyline><polyline points="16 7 22 7 22 13"></polyline>';
        } else {
            svg.innerHTML = '<polyline points="22 17 13.5 8.5 8.5 13.5 2 7"></polyline><polyline points="16 17 22 17 22 11"></polyline>';
        }
    };
    
    setTrend('kpiRevenueTrend', 12.4, true);
    setTrend('kpiOrdersTrend', 8.2, true);
    setTrend('kpiTimeTrend', -2.1, false);
    setTrend('kpiCancelTrend', -1.5, false);
    setTrend('kpiOnTimeTrend', 4.3, true);
    setTrend('kpiAOVTrend', 3.8, true);
}

// ─── Charts ──────────────────────────────────────────────────────────────────
function destroyChart(id) {
    if (charts[id]) {
        charts[id].destroy();
    }
}

function renderRevenueChart() {
    destroyChart('revenueChart');
    
    // Group by month
    const monthlyData = {};
    filteredData.forEach(d => {
        if(d.order_status === 'Cancelled') return;
        const month = d.order_date.toISOString().substring(0, 7);
        monthlyData[month] = (monthlyData[month] || 0) + d.total_revenue;
    });
    
    const labels = Object.keys(monthlyData).sort();
    const data = labels.map(l => monthlyData[l]);

    const ctx = document.getElementById('revenueChart').getContext('2d');
    
    const gradient = ctx.createLinearGradient(0, 0, 0, 300);
    gradient.addColorStop(0, COLORS.primaryLight);
    gradient.addColorStop(1, 'rgba(37, 99, 235, 0)');

    charts['revenueChart'] = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Revenue (INR)',
                data: data,
                borderColor: COLORS.primary,
                backgroundColor: gradient,
                borderWidth: 3,
                pointBackgroundColor: COLORS.primary,
                pointBorderColor: '#fff',
                pointHoverBackgroundColor: '#fff',
                pointHoverBorderColor: COLORS.primary,
                pointRadius: 4,
                pointHoverRadius: 6,
                fill: true,
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return formatCurrency(context.raw);
                        }
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return '₹' + (value / 100000).toFixed(1) + 'L';
                        }
                    }
                }
            }
        }
    });
}

function renderCityChart() {
    destroyChart('cityChart');
    
    const cityCount = {};
    filteredData.forEach(d => {
        cityCount[d.city] = (cityCount[d.city] || 0) + 1;
    });
    
    const sortedCities = Object.entries(cityCount)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 8); // Top 8
        
    const ctx = document.getElementById('cityChart').getContext('2d');
    
    charts['cityChart'] = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: sortedCities.map(c => c[0]),
            datasets: [{
                label: 'Orders',
                data: sortedCities.map(c => c[1]),
                backgroundColor: COLORS.teal,
                borderRadius: 4,
                barThickness: 20
            }]
        },
        options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            scales: {
                x: { beginAtZero: true }
            }
        }
    });
}

function renderDeliveryTimeChart() {
    destroyChart('deliveryTimeChart');
    
    const monthlyData = {};
    filteredData.forEach(d => {
        if(d.order_status !== 'Delivered' || !d.actual_delivery_min) return;
        const month = d.order_date.toISOString().substring(0, 7);
        if(!monthlyData[month]) monthlyData[month] = { sum: 0, count: 0 };
        monthlyData[month].sum += d.actual_delivery_min;
        monthlyData[month].count += 1;
    });
    
    const labels = Object.keys(monthlyData).sort();
    const data = labels.map(l => monthlyData[l].sum / monthlyData[l].count);
    
    const ctx = document.getElementById('deliveryTimeChart').getContext('2d');

    charts['deliveryTimeChart'] = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Avg Actual Time',
                data: data,
                borderColor: COLORS.success,
                backgroundColor: COLORS.successLight,
                borderWidth: 2,
                pointRadius: 3,
                fill: true,
                tension: 0.3
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            scales: {
                y: {
                    beginAtZero: false,
                    title: { display: true, text: 'Minutes' }
                }
            }
        }
    });
}

function renderCancelChart() {
    destroyChart('cancelChart');
    
    const reasons = {};
    filteredData.forEach(d => {
        if(d.order_status === 'Cancelled' && d.cancellation_reason) {
            reasons[d.cancellation_reason] = (reasons[d.cancellation_reason] || 0) + 1;
        }
    });
    
    const sorted = Object.entries(reasons)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5);
        
    const colors = [COLORS.danger, COLORS.warning, COLORS.primary, COLORS.purple, COLORS.teal];

    const ctx = document.getElementById('cancelChart').getContext('2d');
    
    charts['cancelChart'] = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: sorted.map(s => s[0].length > 25 ? s[0].substring(0,25)+'...' : s[0]),
            datasets: [{
                data: sorted.map(s => s[1]),
                backgroundColor: colors,
                borderWidth: 0,
                hoverOffset: 4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '75%',
            plugins: {
                legend: {
                    position: 'right',
                    labels: {
                        color: COLORS.textMuted,
                        boxWidth: 12,
                        padding: 15,
                        font: { size: 11 }
                    }
                }
            }
        }
    });
}

function renderPeakHourChart() {
    destroyChart('peakHourChart');
    
    const hours = Array(24).fill(0);
    filteredData.forEach(d => {
        // order_time format could be "14:23:45" or a Date object depending on papaparse
        let h = 0;
        if(typeof d.order_time === 'string') {
            h = parseInt(d.order_time.split(':')[0]);
        }
        if(!isNaN(h)) {
            hours[h] += 1;
        }
    });
    
    const labels = Array.from({length: 24}, (_, i) => `${i}:00`);
    
    // Highlight peak hours (11-13, 18-20)
    const bgColors = hours.map((_, i) => {
        if((i >= 11 && i <= 13) || (i >= 18 && i <= 20)) return COLORS.primary;
        return '#e2e8f0';
    });

    const ctx = document.getElementById('peakHourChart').getContext('2d');
    
    charts['peakHourChart'] = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Orders',
                data: hours,
                backgroundColor: bgColors,
                borderRadius: 4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            scales: {
                x: {
                    ticks: { maxTicksLimit: 12 }
                }
            }
        }
    });
}

function renderDriverTable() {
    const driverStats = {};
    
    filteredData.forEach(d => {
        if(!driverStats[d.driver_id]) {
            driverStats[d.driver_id] = {
                name: d.driver_name,
                trips: 0,
                delivered: 0,
                onTime: 0,
                ratingSum: 0,
                ratingCount: 0,
                revenue: 0
            };
        }
        
        const st = driverStats[d.driver_id];
        st.trips++;
        st.revenue += d.total_revenue;
        
        if(d.order_status === 'Delivered') {
            st.delivered++;
            if((d.actual_delivery_min || 0) <= (d.estimated_delivery_min || 0)) {
                st.onTime++;
            }
        }
        
        if(d.rating) {
            st.ratingSum += d.rating;
            st.ratingCount++;
        }
    });
    
    // Calculate final metrics & composite score
    const drivers = Object.values(driverStats).map(d => {
        const onTimePct = d.delivered > 0 ? (d.onTime / d.delivered) * 100 : 0;
        const avgRating = d.ratingCount > 0 ? d.ratingSum / d.ratingCount : 0;
        
        // Simple composite score for ranking
        const score = (avgRating * 20) + (onTimePct * 0.5) + Math.min((d.trips / 100) * 10, 10);
        
        return { ...d, onTimePct, avgRating, score };
    });
    
    drivers.sort((a, b) => b.score - a.score);
    
    const tbody = document.getElementById('driverTableBody');
    tbody.innerHTML = '';
    
    // Render top 10
    const topDrivers = drivers.slice(0, 10);
    const maxRev = Math.max(...topDrivers.map(d => d.revenue));
    
    topDrivers.forEach((d, idx) => {
        const rank = idx + 1;
        let badgeClass = 'rank-badge--default';
        if(rank === 1) badgeClass = 'rank-badge--gold';
        if(rank === 2) badgeClass = 'rank-badge--silver';
        if(rank === 3) badgeClass = 'rank-badge--bronze';
        
        const stars = '★'.repeat(Math.round(d.avgRating)) + '☆'.repeat(5 - Math.round(d.avgRating));
        const revPct = (d.revenue / maxRev) * 100;
        
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><div class="rank-badge ${badgeClass}">${rank}</div></td>
            <td style="font-weight: 600; color: var(--text-primary)">${d.name}</td>
            <td>${formatNumber(d.trips)}</td>
            <td>
                <span class="${d.onTimePct > 85 ? 'text-green' : ''}">${d.onTimePct.toFixed(1)}%</span>
            </td>
            <td>
                <span class="rating-stars">${stars}</span> <span style="font-size:0.7rem; color:var(--text-muted)">${d.avgRating.toFixed(1)}</span>
            </td>
            <td>
                <div class="progress-bar">
                    <div class="progress-bar__fill progress-bar__fill--blue" style="width: ${revPct}%"></div>
                </div>
                ${formatCurrency(d.revenue)}
            </td>
        `;
        tbody.appendChild(tr);
    });
}

// Boot up
document.addEventListener('DOMContentLoaded', init);
