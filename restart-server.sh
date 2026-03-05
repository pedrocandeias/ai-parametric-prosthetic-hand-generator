#!/bin/bash
cd "$(dirname "$0")"

PORT=${PORT:-3000}
PID=$(lsof -ti:${PORT} 2>/dev/null)
if [ -n "$PID" ]; then
    kill $PID && echo "Stopped existing server (pid $PID)"
    sleep 1
fi

exec ./start-server.sh
