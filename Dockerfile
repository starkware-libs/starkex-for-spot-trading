FROM ciimage/python:3.7

RUN apt update
RUN apt install -y cmake libgmp3-dev g++ python3-pip python3.7-dev npm

COPY . /app/

# Build.
WORKDIR /app/
RUN rm -rf build
RUN ./build.sh

# Run tests.
WORKDIR /app/build/Release
RUN ctest -V

WORKDIR /app/
