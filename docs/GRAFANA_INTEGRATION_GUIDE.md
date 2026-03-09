# Grafana Integration Guide for Exasol Workshop

## Overview
This guide explains how to add Grafana to the existing Exasol Workshop GitHub Codespace environment to provide real-time analytics dashboards for the NHS Prescriptions dataset.

## Workshop Context
- **Event**: DataTalks.Club Meetup @ Exasol Xperience 2026
- **Date**: Tuesday, March 10, 2026, 18:00
- **Location**: Hotel Telegraphenamt, Berlin
- **Dataset**: 1+ billion rows of NHS prescription data (2010-2018)

## Files Included

1. **grafana_dashboard_exasol_nhs.json** - Pre-configured Grafana dashboard with 4 panels
2. **docker-compose-with-grafana.yml** - Enhanced Docker Compose with Grafana service
3. **grafana_datasource_exasol.yml** - Exasol data source configuration
4. **grafana_dashboard_provider.yml** - Dashboard provisioning configuration

---

## Integration Steps

### Step 1: Directory Structure Setup

Create the following directory structure in the `code/kestra` folder:

```bash
cd code/kestra
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/provisioning/dashboards
mkdir -p grafana/dashboards
```

### Step 2: Place Configuration Files

```bash
# Copy datasource configuration
cp grafana_datasource_exasol.yml grafana/provisioning/datasources/exasol.yml

# Copy dashboard provider configuration
cp grafana_dashboard_provider.yml grafana/provisioning/dashboards/default.yml

# Copy dashboard JSON
cp grafana_dashboard_exasol_nhs.json grafana/dashboards/
```

### Step 3: Configure Exasol Connection

Edit `grafana/provisioning/datasources/exasol.yml` and replace placeholders:

```bash
# Get Exasol connection details
cd ../../deployment
../code/exasol info

# Note the following values:
# - Host (IP address)
# - Port (typically 8563)
# - Password from secrets-*.json file
```

Update `grafana/provisioning/datasources/exasol.yml`:
```yaml
url: <EXASOL_HOST>:8563  # Replace with actual host
database: EXA_DB
user: sys
secureJsonData:
  password: '<EXASOL_PASSWORD>'  # Replace with actual password
```

**Important**: Grafana uses the PostgreSQL data source driver to connect to Exasol via JDBC, as both databases support PostgreSQL wire protocol compatibility.

### Step 4: Replace Docker Compose File

```bash
cd code/kestra

# Backup original
mv docker-compose.yml docker-compose.yml.backup

# Use new version with Grafana
cp docker-compose-with-grafana.yml docker-compose.yml
```

### Step 5: Start Services

```bash
# Stop existing containers if running
docker compose down

# Start all services (Kestra, PostgreSQL, Grafana)
docker compose up -d

# Check status
docker compose ps

# View Grafana logs
docker compose logs -f grafana
```

### Step 6: Access Grafana

1. Open browser: **http://localhost:3000**
2. Login credentials:
   - Username: `admin`
   - Password: `admin`
3. Change password when prompted (or skip)

### Step 7: Verify Dashboard

1. Navigate to **Dashboards** → **Browse**
2. Open folder: **Exasol Workshop**
3. Select: **Exasol NHS Prescriptions - East Central London Analytics**

---

## Dashboard Panels

The dashboard answers two SQL analytics challenges:

### Panel 1 & 2: Top 3 Prescribed Chemicals in East Central London
- **Visualization**: Bar chart + Table
- **SQL Query**:
```sql
SELECT 
    c.CHEMICALNAME,
    SUM(p.ITEMS) AS total_items
FROM 
    PRESCRIPTIONS_UK.PRESCRIPTION p
    JOIN PRESCRIPTIONS_UK.PRACTICE pr ON p.PRACTICECODE = pr.PRACTICECODE
    JOIN PRESCRIPTIONS_UK.CHEMICAL c ON p.CHEMICALCODE = c.CHEMICALCODE
WHERE 
    pr.POSTCODE LIKE 'EC%'
GROUP BY 
    c.CHEMICALNAME
ORDER BY 
    total_items DESC
LIMIT 3;
```

### Panel 3 & 4: Prescription Frequency by Year for Top Chemical
- **Visualization**: Time series line chart + Table
- **SQL Query**: Uses CTE to find the most prescribed chemical, then aggregates by year
```sql
WITH top_chemical AS (
    SELECT 
        c.CHEMICALNAME,
        c.CHEMICALCODE,
        SUM(p.ITEMS) AS total_items
    FROM 
        PRESCRIPTIONS_UK.PRESCRIPTION p
        JOIN PRESCRIPTIONS_UK.PRACTICE pr ON p.PRACTICECODE = pr.PRACTICECODE
        JOIN PRESCRIPTIONS_UK.CHEMICAL c ON p.CHEMICALCODE = c.CHEMICALCODE
    WHERE 
        pr.POSTCODE LIKE 'EC%'
    GROUP BY 
        c.CHEMICALNAME, c.CHEMICALCODE
    ORDER BY 
        total_items DESC
    LIMIT 1
)
SELECT 
    SUBSTR(p.PERIOD, 1, 4) AS year,
    SUM(p.ITEMS) AS items_prescribed
FROM 
    PRESCRIPTIONS_UK.PRESCRIPTION p
    JOIN PRESCRIPTIONS_UK.PRACTICE pr ON p.PRACTICECODE = pr.PRACTICECODE
    JOIN top_chemical tc ON p.CHEMICALCODE = tc.CHEMICALCODE
WHERE 
    pr.POSTCODE LIKE 'EC%'
GROUP BY 
    SUBSTR(p.PERIOD, 1, 4)
ORDER BY 
    items_prescribed DESC;
```

---

## Workshop Sequence Integration

Add the following section to the workshop after **"Load all months"** section in `workshop.md`:

### High-Frequency Analytics with Grafana

Now that we have loaded the complete NHS Prescriptions dataset (1+ billion rows), let's create real-time analytics dashboards with Grafana.

#### Start Grafana

```bash
cd code/kestra
docker compose up -d grafana
```

#### Access the Dashboard

1. Open http://localhost:3000
2. Login with `admin` / `admin`
3. Navigate to **Dashboards** → **Exasol Workshop** folder
4. Open **Exasol NHS Prescriptions - East Central London Analytics**

#### Explore the Analytics

The dashboard answers two key questions about prescriptions in the East Central London (EC) postal code area:

1. **What are the three most commonly prescribed chemicals?**
   - View the bar chart showing the top 3 chemicals by total items prescribed
   - The table view provides exact counts

2. **In which year was the top chemical prescribed most frequently?**
   - The time series chart shows year-over-year trends
   - Identify peak prescription years and patterns

#### Try Your Own Queries

Click on any panel title → **Edit** to:
- Modify SQL queries
- Change visualization types
- Add new filters or aggregations
- Create derived metrics

---

## Troubleshooting

### Grafana Container Won't Start
```bash
# Check logs
docker compose logs grafana

# Verify directory permissions
ls -la grafana/

# Reset Grafana data
docker compose down
docker volume rm kestra_grafana-data
docker compose up -d grafana
```

### Cannot Connect to Exasol
```bash
# Verify Exasol is running
cd ../../deployment
../code/exasol status

# Test connection from Grafana container
docker compose exec grafana nc -zv <EXASOL_HOST> 8563

# Check datasource configuration
docker compose exec grafana cat /etc/grafana/provisioning/datasources/exasol.yml
```

### Dashboard Doesn't Appear
```bash
# Check dashboard provisioning
docker compose exec grafana ls -la /var/lib/grafana/dashboards/

# Verify provisioning config
docker compose exec grafana cat /etc/grafana/provisioning/dashboards/default.yml

# Restart Grafana
docker compose restart grafana
```

### Query Errors
- **"relation does not exist"**: Ensure data is loaded into `PRESCRIPTIONS_UK` schema
- **"authentication failed"**: Check password in datasource configuration
- **"connection refused"**: Verify Exasol host and port, check security groups

---

## Advanced Configurations

### Add More Dashboards

Create new dashboard JSON files in `grafana/dashboards/` directory. They will be auto-provisioned.

### Enable Anonymous Access

Edit `docker-compose.yml`, add to Grafana environment:
```yaml
- GF_AUTH_ANONYMOUS_ENABLED=true
- GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer
```

### Configure SMTP for Alerts

Add to Grafana environment:
```yaml
- GF_SMTP_ENABLED=true
- GF_SMTP_HOST=smtp.gmail.com:587
- GF_SMTP_USER=your-email@gmail.com
- GF_SMTP_PASSWORD=your-app-password
- GF_SMTP_FROM_ADDRESS=your-email@gmail.com
```

### Persist Grafana Configuration

By default, Grafana data is stored in Docker volume `grafana-data`. To use bind mount:

```yaml
volumes:
  - ./grafana/data:/var/lib/grafana
```

---

## Performance Considerations

### Query Optimization

The provided queries are optimized for Exasol's columnar architecture:
- Filters applied early (`WHERE pr.POSTCODE LIKE 'EC%'`)
- Joins on indexed columns (PRACTICECODE, CHEMICALCODE)
- Aggregations pushed to database

### Caching

Grafana caches query results. Configure cache duration:
1. Dashboard Settings → JSON Model
2. Add to panel definition:
```json
"cacheTimeout": "300"
```

### Connection Pooling

Exasol JDBC driver handles connection pooling automatically. For high-frequency dashboards, consider:
- Setting `maxIdleConns` in data source
- Using Grafana Enterprise for query caching

---

## Expected Results

After following this guide:

1. ✅ Grafana accessible at http://localhost:3000
2. ✅ Exasol data source configured and tested
3. ✅ NHS Prescriptions dashboard loaded with 4 panels
4. ✅ Real-time analytics on 1+ billion rows
5. ✅ Sub-second query response times (thanks to Exasol's in-memory columnar engine)

---

## Resources

- **Grafana Documentation**: https://grafana.com/docs/grafana/latest/
- **Exasol JDBC Driver**: https://docs.exasol.com/db/latest/connect_exasol/drivers/jdbc.htm
- **Workshop Repository**: https://github.com/alexeygrigorev/exasol-workshop-starter
- **DataTalks.Club**: https://datatalks.club/

---

## Questions for Workshop

During the workshop on **March 10, 2026**, participants will:
1. Set up the complete data pipeline (Exasol + Kestra + Grafana)
2. Load 1+ billion rows of NHS prescription data
3. Create and customize Grafana dashboards
4. Perform high-frequency analytics queries
5. Optimize query performance

**Support**: If you encounter issues during the workshop, the Exasol team and DataTalks.Club organizers will be available to assist.
