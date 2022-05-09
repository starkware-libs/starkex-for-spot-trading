FROM ciimage/python:3.7 as base_image

RUN apt update && apt install -y make libgmp3-dev g++ python3-pip npm
RUN apt -y -o Dpkg::Options::="--force-overwrite" install python3.7-dev python3.7-distutils
# Installing cmake via apt doesn't bring the most up-to-date version.
RUN pip install cmake==3.22

COPY . /app/

# Build.
WORKDIR /app/
RUN rm -rf build
RUN ./build.sh

FROM base_image

# Run tests.
WORKDIR /app/build/Release
RUN ctest -V

WORKDIR /app/
