# ============================================
# Production Dockerfile: Flutter Web + nginx
# ============================================
# Build: docker build -t dating-app .
# Run:   docker run -p 8080:80 dating-app
# Optional env at build: --build-arg SUPABASE_URL=... --build-arg SUPABASE_ANON_KEY=...
# ============================================

# Stage 1: Build Flutter web
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Cache pub dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Build args for production config (optional; override defaults)
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY
RUN flutter pub get && \
  flutter build web \
    --release \
    --web-renderer canvaskit \
    ${SUPABASE_URL:+--dart-define=SUPABASE_URL=$SUPABASE_URL} \
    ${SUPABASE_ANON_KEY:+--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY}

# Stage 2: Serve with nginx
FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
