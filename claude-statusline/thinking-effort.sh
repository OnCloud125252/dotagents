#!/bin/bash
effort=$(jq -r '.effort.level // empty' 2>/dev/null)
if [ -n "$effort" ] && [ "$effort" != "null" ]; then
  echo -n "$effort"
fi
exit 0
