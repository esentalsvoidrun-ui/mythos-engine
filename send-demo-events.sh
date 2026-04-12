#!/bin/bash

# 10 demo-events med lite variation
for i in {1..10}
do
  # Slumpa decision
  if (( RANDOM % 2 )); then
    decision="approved"
  else
    decision="denied"
  fi

  # Skicka event
  curl -s -X POST http://localhost:3000/logs \
    -H "Content-Type: application/json" \
    -d "{\"event\":\"demo_event_$i\",\"decision\":\"$decision\"}"

  # Kort paus så det blir fly-in effekt
  sleep 0.3
done

echo "10 demo-events skickade!"
