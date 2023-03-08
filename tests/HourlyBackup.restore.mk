.ONESHELL:
SHELL = /bin/bash

all:  ${FBDIR}/workdir/step1 clean beer

./workdir/step1:
  ${FBDIR}/.local/bin/HourlySnapshot/HourlySnapshot.restore.sh --verbose /mnt/chromeos/GoogleDrive/MyDrive/FB/Periodic/HourlySnapshot/home-mcusr-wrk-server-homepage/homepage-2023-02-22/homepage-2023-02-22T15:01-backup.tar.gz /tmp/testHourlyRestore
  touch ./workdir/step1

# ./workdir/step2: ./workdir/step1
#       @script1 ./workdir/step2
#       touch ./workdir/step2
#       exit 1

# ./workdir/step3: ./workdir/step2
#       @script1 ./workdir/step3
#       touch ./workdir/step3


clean:
  rm ./workdir/step1
# ./workdir/step2 ./workdir/step3
