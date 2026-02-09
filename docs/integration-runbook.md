# Integration Runbook: 5G Health Platform

This guide walks through verifying the end-to-end flow of the platform locally.

## 1. Start Structure

```bash
# In 5g-health-platform-infra
make demo
```
Wait for "Dashboard available at http://localhost:5173".

## 2. Verify Gateway
1. Open browser: [http://localhost:8081/health](http://localhost:8081/health)
2. Expect JSON: `{"status":"ok", ...}`

## 3. Verify Dashboard
1. Open browser: [http://localhost:5173](http://localhost:5173)
2. The dashboard should load without errors.
3. Check the "Connection Status" in the UI (if implemented). It should show "Connected" (Green).

## 4. Verify NATS Streams
Check that the `events` stream exists:
```bash
# Using docker exec
docker exec 5g-platform-nats nats stream info events
```
Expect output showing subjects: `vitals.recorded`, `patient.alert.raised` etc.

## 5. End-to-End Simulation
The `ingestion` service should automatically start publishing mock data if configured (check `ingestion` logs).
1. Tail logs:
   ```bash
   make logs-ingestion
   ```
2. Look for "Published vitals" messages.
3. Go to Dashboard. You should see live graphs or data updating.

## Troubleshooting
- **Gateway not connecting**: Check `make logs-gateway`. Ensure NATS is reachable (`nats://nats:4222`).
- **Dashboard White Screen**: Check browser console (F12). Ensure `WsClient` is connecting to `ws://localhost:8081/ws`.
- **No Data**: Ensure `ingestion` is running. If not, you might need to manually trigger it or check if it needs specific ENV vars.

## Clean Up
```bash
make down
```
