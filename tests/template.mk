.ONESHELL:
SHELL = /bin/bash

all:  ./workdir/step3 clean beer

./workdir/step1:
  @script1 ./workdir/step1
  touch ./workdir/step1

./workdir/step2: ./workdir/step1
  @script1 ./workdir/step2
  touch ./workdir/step2
  exit 1

./workdir/step3: ./workdir/step2
  @script1 ./workdir/step3
  touch ./workdir/step3


clean:
      rm ./workdir/step1 ./workdir/step2 ./workdir/step3
