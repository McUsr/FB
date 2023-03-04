all: $(TARGET)

$(TARGET):
	.git/test-runner.sh $@
# It's a run we are going to use from commit, and we'll have code formatting here too!
tests:
