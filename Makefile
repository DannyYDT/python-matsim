PYTHON=python3.6
PYTHON_DIR=$(PWD)

.PHONY: all maven python python_pbf

all: python_dist

maven:
	cd java/ && mvn install -DskipTests=true

python_pbf: maven | java/venv
	cd java/ && ./generate_python_stubs.sh
	cp -v java/target/generated-sources/python/*_pb2.py* pythonmatsim/
	cat pythonmatsim/EventBuffer_pb2.py | sed 's,events_pb2,pythonmatsim.events_pb2,' > abc
	mv abc pythonmatsim/EventBuffer_pb2.py

%/venv:
	cd $(@D) && virtualenv --clear -p $(PYTHON) venv/ && venv/bin/pip install --no-binary JPype1 -r requirements.txt

python: python_dist | $(PYTHON_DIR)/venv
	venv/bin/pip install --no-binary JPype1 dist/*

python_dist: python_pbf | $(PYTHON_DIR)/venv
	venv/bin/python setup.py codegen build sdist

examples: python | examples/venv
	cd examples && \
		venv/bin/pip install --no-binary :all: -e ../ && \
		venv/bin/pip freeze | grep '^-e' > requirements.txt

test: python_dist 
	virtualenv --clear -p $(PYTHON) testvenv/
	testvenv/bin/pip install numpy
	testvenv/bin/pip install --no-binary JPype1 JPype1
	testvenv/bin/pip install dist/*
	testvenv/bin/python -m unittest test/*.py  

clean:
	rm -rf build dist javawrappers mavendir
