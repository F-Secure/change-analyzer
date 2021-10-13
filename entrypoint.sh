#!/bin/bash -x

chromedriver &
java -jar selenium-server-standalone-3.141.59.jar &
# Give time for background softwares to start.
sleep 3
cd ./change-analyzer

GENERATE=0
REPLAY=0
COMPARE=0
CSV=0

for i in "$@"; do
  case $i in
    -i=*|--ini=*)
      INI="${i#*=}"
      shift
      echo -e "$INI" > /home/localtester/change-analyzer/input.ini
      ;;
    --csv=*)
      CSV=1
      CSV_PATH="${i#*=}"
      shift
      ;;
    -g*|--generate*)
      GENERATE=1
      shift
      ;;
    -r*|--replay*)
      REPLAY=1
      shift
      ;;
    -c*|--compare*)
      COMPARE=1
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

cat input.ini
. .venv/bin/activate

# Generate
if [ "$GENERATE" = "1" ]; then
    echo "GENERATE"
    ca-run --config input.ini
    FIRST_RECORD=$(ls -l recordings|tail -n1|cut --delimiter=' ' -f9)
fi

# Replay
if [ "$REPLAY" = "1" ] && [ "$CSV" = "1" ]; then
    echo "REPLAY IMPORTED CSV"
    FIRST_RECORD=$(ls -l "$CSV_PATH"/recordings|tail -n1|cut --delimiter=' ' -f9)
    FIRST_RECORD="$CSV_PATH/recordings/$FIRST_RECORD"
    ca-run --config input.ini --csv_folder="$FIRST_RECORD"
    SECOND_RECORD=$(ls -l recordings|tail -n1|cut --delimiter=' ' -f9)
elif [ "$REPLAY" = "1" ]; then
    echo "REPLAY"
    FIRST_RECORD=$(ls -l recordings|tail -n1|cut --delimiter=' ' -f9)
    ca-run --config input.ini --csv_folder=recordings/"$FIRST_RECORD"
    SECOND_RECORD=$(ls -l recordings|tail -n1|cut --delimiter=' ' -f9)
fi

# Compare
if [ "$COMPARE" = "1" ]; then
    echo "COMPARE"
    ca-compare --sequence1_folder "$FIRST_RECORD" --sequence2_folder "$SECOND_RECORD"
fi
