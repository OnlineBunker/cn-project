#!/usr/bin/env bash
# Extension D: nginx health/failover. Stops Backend A on Phalak's Mac, then restarts it.
. "$(dirname "$0")/lib.sh"
h "1. Normal: both backends in rotation"; bash "$ROOT/scripts/lb-test.sh" 4
h "2. STOP Backend A (Mac 3)"; sshk $PHALAK "cd ~/cn-project && bash scripts/backend.sh stop A"
h "3. Requests continue, served by Backend B only (no failures)"; bash "$ROOT/scripts/lb-test.sh" 6
h "4. RESTART Backend A"; sshk $PHALAK "cd ~/cn-project && bash scripts/backend.sh start A" ; sleep 6
h "5. Load balancing resumes across both"; bash "$ROOT/scripts/lb-test.sh" 6
echo; echo "Single point of failure: the edge nginx on Mac 2 (and the single DNS name pointing to it) -> see Extension E."
