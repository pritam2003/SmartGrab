FROM ghcr.io/cirruslabs/flutter:3.38.9

WORKDIR /app
COPY smartgrab/ /app/

RUN flutter pub get

CMD ["flutter", "analyze"]
