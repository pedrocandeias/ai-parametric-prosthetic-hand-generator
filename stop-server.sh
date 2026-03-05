#!/bin/bash
PORT=${PORT:-3000}
PID=$(lsof -ti:${PORT} 2>/dev/null)
if [ -n "$PID" ]; then
    kill $PID && echo "Server on port ${PORT} stopped (pid $PID)"
else
    echo "No server running on port ${PORT}"
fi
